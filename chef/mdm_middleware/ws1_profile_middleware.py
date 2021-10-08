# Copyright (c) ZenPayroll, Inc., dba Gusto
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import boto3  # Comment out if not deploying on AWS
import json
import logging
import os
import plistlib
import sys

# Lambda's Python runtime messes with log formatting to make Cloudwatch work
# Add something like this when testing locally:
# logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s", level=logging.INFO)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Lambda Layers (like Requests) are unzipped to /opt/
sys.path.append("/opt/")
import requests
from requests.auth import HTTPBasicAuth


# Secrets management
# Change this section to match your values/preferred secrets management system.
secrets = boto3.client("secretsmanager")
aw_secrets = secrets.get_secret_value(SecretId="ws1_profile_middleware")["SecretString"]
secrets_dict = json.loads(aw_secrets)

AIRWATCH_PASSWORD = secrets_dict["AIRWATCH_PASSWORD"]
AIRWATCH_KEY = secrets_dict["AIRWATCH_KEY"]

# Environment variables
AIRWATCH_USER = os.environ["AIRWATCH_USER"]
MANAGEDLOCATIONGROUPID = os.environ["MANAGEDLOCATIONGROUPID"]
SMARTGROUPID = os.environ["SMARTGROUPID"]
AIRWATCH_DOMAIN = os.environ["AIRWATCH_DOMAIN"]

# Handle all exceptions and always return a response with an appropriate statusCode
SUPPRESS_RAW_ERRORS = True

DEFAULT_RESPONSE = {
    "profile_id": None,
    "body": "",
    "statusCode": requests.codes["internal_server_error"],
    "hint": None,
}


def remove_profile(serial, profile_id):
    """hubcli doesn't remove profiles so we have to do this server-side."""
    r = requests.post(
        url=f"https://{ AIRWATCH_DOMAIN }/API/mdm/profiles/{ profile_id }/remove",
        json={"SerialNumber": serial},
        headers={
            "aw-tenant-code": AIRWATCH_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        auth=HTTPBasicAuth(AIRWATCH_USER, AIRWATCH_PASSWORD),
    )
    r.raise_for_status()

    return r


def install_profile(serial, profile_id):
    """hubcli doesn't work at all currently, so we have to do this server-side."""
    r = requests.post(
        url=f"https://{ AIRWATCH_DOMAIN }/API/mdm/profiles/{ profile_id }/install",
        json={"SerialNumber": serial},
        headers={
            "aw-tenant-code": AIRWATCH_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        auth=HTTPBasicAuth(AIRWATCH_USER, AIRWATCH_PASSWORD),
    )
    r.raise_for_status()

    return r


def payload_to_xml(payload):
    """Quick and dirty conversion of dictionaries to XML with plistlib. Returns a converted dictionary with the header and footer removed."""
    try:
        unprocessed = plistlib.dumps(payload).decode("utf-8")
        header_removed = unprocessed.split("\n", 3)[3]
        return header_removed.rsplit("\n", 2)[0]
    except TypeError as e:
        logger.error(e)
        logger.error(payload)
        logger.error("Failed to convert profile to XML.")
        raise


def create_profile(event):
    """Maps profile payloads to list of raw plist dicts and pass each as seperate item to the Airwatch API."""
    # This will require setting profile contexts in cookbooks. Currently it assumes device/system profiles.
    # profile_context_map = {"System": "Device", "User": "User"}

    r = requests.post(
        url=f"https://{ AIRWATCH_DOMAIN }/API/mdm/profiles/platforms/appleosx/create",
        headers={
            "aw-tenant-code": AIRWATCH_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json;version=2",
        },
        auth=HTTPBasicAuth(AIRWATCH_USER, AIRWATCH_PASSWORD),
        json={
            "General": {
                "Name": event["name"],
                "Description": event["profile"]["PayloadDisplayName"],
                "ProfileContext": "Device",
                # "ProfileContext": profile_context_map[event["profile_context"]],
                "AssignmentType": "Optional",
                "ManagedLocationGroupID": MANAGEDLOCATIONGROUPID,
                "AssignedSmartGroups": [
                    {
                        "SmartGroupId": SMARTGROUPID,
                        "Name": "Devices managed by cpe_profiles_workspaceone",
                    }
                ],
            },
            "CustomSettingsList": list(
                [
                    {"CustomSettings": p}
                    for p in map(payload_to_xml, event["profile"]["PayloadContent"])
                ]
            ),
        },
    )
    r.raise_for_status()

    return r.text


def search_profiles(profile_name, serial):
    """Looks up profiles by name. A status code of 200 means a profile exists. 204 means no matching profile."""
    logger.info(f"Checking if { profile_name } already exists. Request from { serial }")
    r = requests.get(
        url=f"https://{ AIRWATCH_DOMAIN }/API/mdm/profiles/search?searchtext={ profile_name }",
        headers={
            "aw-tenant-code": AIRWATCH_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json;version=2",
        },
        auth=HTTPBasicAuth(AIRWATCH_USER, AIRWATCH_PASSWORD),
    )
    r.raise_for_status()
    if r.status_code == 200:
        return True, r.json()["ProfileList"][0]["ProfileId"]
    elif r.status_code == 204:
        return False, None
    else:
        logger.error(r.text)
        raise requests.exceptions.HTTPError(response=r)


def unsafe_handler(event, context):
    # FIXME we should return a proper HTTP status code. This appears to require
    # defining a schema for our API gateway response
    response = DEFAULT_RESPONSE.copy()

    action = event["action"]
    name = event["name"]
    serial = event["serial"]
    profile_exists = None
    profile_id = None
    remote_install_requested = bool(event.get("remote_install_requested", False))
    skip_creation = bool(event.get("skip_creation", False))
    suppress_skip_creation_assignment_errors = bool(
        event.get("suppress_skip_creation_assignment_errors", True)
    )

    profile_exists, profile_id = search_profiles(name, serial)
    response["profile_id"] = profile_id

    if action not in ["install", "remove"]:
        msg = f"Invalid value for action: {action}."
        logger.info(msg)
        response["body"] = msg
        response["statusCode"] = requests.codes["bad_request"]

    elif profile_exists and action == "install":
        msg = f"Returning existing profile for { name } ({ profile_id })."
        response["statusCode"] = requests.codes["accepted"]

        if remote_install_requested:
            install_profile(serial, profile_id)
            logger.info("Sent install command in lieu of hubcli")

        response["body"] = msg
        logger.info(msg)

    elif profile_exists and action == "remove":
        logger.info(f"Found profile { name } ({ profile_id }) for removal.")
        remove_profile(serial, profile_id)
        response["statusCode"] = requests.codes["ok"]
        response["body"] = f"Removed profile { name } from { serial }."

    elif not profile_exists and action == "remove":
        msg = f"Removal requested for profile { name } on { serial }, but no matching profile found."
        logger.error(msg)
        response["body"] = msg
        response["statusCode"] = requests.codes["no_content"]

    elif not profile_exists and action == "install":
        response["statusCode"] = requests.codes["not_found"]
        response["hint"] = f"Skip creation is set to { skip_creation }."
        msg = f"Failed to find profile { name }"

        if skip_creation and suppress_skip_creation_assignment_errors:
            response["statusCode"] = requests.codes["not_modified"]

        if not skip_creation:
            profile_id = create_profile(event)
            msg = f"Created new profile { name } ({ profile_id })."
            response["profile_id"] = profile_id
            response["statusCode"] = requests.codes["created"]
            if remote_install_requested:
                install_profile(serial, profile_id)
                logger.info("Sent install command in lieu of hubcli")

        response["body"] = msg
        logger.info(msg)

    else:
        logger.error("This else statement never should have executed.")
        raise "Logical failure: all conditions should have been covered by the above if/elif."

    return response


def lambda_handler(event, context):
    action = event["action"]
    name = event["name"]

    try:
        response = unsafe_handler(event, context)

    except requests.exceptions.HTTPError as e:
        logger.error(f"Failed to complete { action } for { name }")
        logger.error(e)

        response = DEFAULT_RESPONSE.copy()
        response["body"] = repr(e)
        response[
            "hint"
        ] = "401 Unauthorized means tell CPE to rotate AW account credentials."

        if (
            skip_creation
            and suppress_skip_creation_assignment_errors
            and action == "install"
        ):
            logger.info(
                f"When attempting to install a profile we did not create, supressed http error: { repr(e) }"
            )
            response["statusCode"] = requests.codes["not_modified"]
            response[
                "hint"
            ] = "Profile is likely not assigned. Middleware only manages assignments for profiles it creates."
        elif e.response is None:
            response["statusCode"] = requests.codes["internal_server_error"]
        else:
            response["statusCode"] = e.response.status_code

    except Exception as e:
        logger.error(f"Failed to complete { action } for { name }")
        logger.error(e)
        if not SUPPRESS_RAW_ERRORS:
            raise e

        response = DEFAULT_RESPONSE.copy()
        response["statusCode"] = requests.codes["internal_server_error"]
        response["hint"] = {
            "RequestId": context.aws_request_id,
            "LogStream": context.log_stream_name,
        }
        response[
            "body"
        ] = f"A {e.__class__.__name__} error occured while attempting to create the profile. Check lambda logs."

    return response
