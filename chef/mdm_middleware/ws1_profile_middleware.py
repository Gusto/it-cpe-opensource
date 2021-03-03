import boto3  # Comment out if not deploying on AWS
import json
import logging
import os
import plistlib
import sys

# AWS Lambda's Python runtime messes with log formatting to make Cloudwatch work
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
ws1_secrets = secrets.get_secret_value(SecretId="your_secret_name")["SecretString"]
secrets_dict = json.loads(ws1_secrets)
AIRWATCH_PASSWORD = secrets_dict["AIRWATCH_PASSWORD"]
AIRWATCH_KEY = secrets_dict["AIRWATCH_KEY"]

# Environment variables
AIRWATCH_USER = os.environ["AIRWATCH_USER"]
MANAGEDLOCATIONGROUPID = os.environ["MANAGEDLOCATIONGROUPID"]
SMARTGROUPID = os.environ["SMARTGROUPID"]
AIRWATCH_DOMAIN = os.environ["AIRWATCH_DOMAIN"]


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
    if r.status_code != 200:
        logger.error(r.text)
        raise LookupError("Failed to remove profile.")

    return r


def payload_to_xml(payload):
    """Quick and dirty conversion of dictionaries to XML with plistlib. Returns a converted dictionary with the header and footer removed."""
    unprocessed = plistlib.dumps(payload).decode("utf-8")
    header_removed = unprocessed.split("\n", 3)[3]
    return header_removed.rsplit("\n", 2)[0]


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
    if r.status_code != 200:
        logger.error(r.text)
        raise LookupError("Failed to search for profile.")

    return r.text


def search_profiles(profile_name):
    """Looks up profiles by name. A status code of 200 means a profile exists. 204 means no matching profile."""
    logger.info(f"Checking if { profile_name } already exists.")
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
        raise requests.exceptions.HTTPError(response=r)


def lambda_handler(event, context):
    """Entrypoint for running in AWS Lambda. Remove the context argument on other platforms."""
    try:
        profile_exists, profile_id = search_profiles(event["name"])
    except requests.exceptions.HTTPError as e:
        logger.error(e)
        return {"body": repr(e), "statusCode": 500}

    if event["action"] not in ["install", "remove"]:
        return {"body": "Action must be one of install or remove", "statusCode": 400}

    if profile_exists and event["action"] == "install":
        logger.info(f'Found existing profile for {event["name"]}.')
        return {"profile_id": profile_id, "statusCode": 200}
    elif profile_exists and event["action"] == "remove":
        logger.info(f'Found profile {event["name"]}.')
        remove_profile(event["serial"], profile_id)
        logger.info(f'Removed profile {event["name"]} from {event["serial"]}.')
    elif profile_exists is False and event["action"] == "remove":
        logger.error(
            f'Removal requested for {event["name"]} on {event["serial"]}, but no matching profile found.'
        )
        return {"body": f"Can't remove {event["name"]} because there's no profile with that name.", "statusCode": 400}
    else:
        profile_id = create_profile(event)
        logger.info(f'Created new profile {event["name"]}.')
        return {"profile_id": profile_id, "statusCode": 201}
