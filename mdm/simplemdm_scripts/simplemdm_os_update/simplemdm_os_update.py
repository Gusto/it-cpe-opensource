# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

import json
import logging
import os

import boto3
import requests
from requests.auth import HTTPBasicAuth

# Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Secrets management
secrets = boto3.client("secretsmanager")
simplemdm_secrets = secrets.get_secret_value(SecretId=os.environ["SECRET_NAME"])[
    "SecretString"
]
secrets_dict = json.loads(simplemdm_secrets)

# Environment variables
SIMPLEMDM_API_KEY = secrets_dict["SIMPLEMDM_API_KEY"]
SIMPLEMDM_BASE_URL = os.environ["SIMPLEMDM_BASE_URL"]
SIMPLEMDM_DEVICE_GROUPS = json.loads(os.environ["SIMPLEMDM_DEVICE_GROUPS"])

# Auth
SIMPLEMDM_AUTH = HTTPBasicAuth(SIMPLEMDM_API_KEY, "")


def get_device_group(device_group: str) -> dict:
    """Get a list of device IDs in a device group."""
    r = requests.get(
        url=f"{SIMPLEMDM_BASE_URL}/device_groups/{device_group}",
        auth=SIMPLEMDM_AUTH,
    )

    if r.status_code == 200:
        json_data = json.loads(r.text)
        return {
            "group_name": json_data["data"]["attributes"]["name"],
            "devices": [
                d["id"] for d in json_data["data"]["relationships"]["devices"]["data"]
            ],
        }
    else:
        raise requests.exceptions.HTTPError(
            f"Failed to get list of devices from device group {device_group}"
        )


def queue_update_command(
    device_id: str,
    os_update_mode: str = "force_update",
    version_type: str = "latest_minor_version",
):
    """Queue an OS update MDM command.
    By default, do not require user interaction (possible data loss) and only update minor versions.
    os_update_mode is ignored for iOS and tvOS.
    """
    r = requests.post(
        url=f"{SIMPLEMDM_BASE_URL}/devices/{device_id}/update_os",
        auth=SIMPLEMDM_AUTH,
        data={
            "os_update_mode": f"{os_update_mode}",
            "version_type": f"{version_type}",
        },
    )

    status_code = r.status_code
    if status_code != 202:
        logger.error(
            f" Error: {r.text}. Status code: {r.status_code}. Device ID: {device_id}."
        )
    else:
        logger.info(f"Queued update command for device {device_id}.")


def lambda_handler(event, context):
    for group in SIMPLEMDM_DEVICE_GROUPS:
        device_info = get_device_group(group["group_id"])
        device_list = device_info["devices"]
        update_mode = group["os_update_mode"]
        update_type = group["version_type"]

        logger.info(
            f"Queueing OS update commands (mode: {update_mode}, type: {update_type}) for device group {device_info['group_name']}"
        )
        logger.info(f"Device IDs: {device_list}")
        for device in device_list:
            queue_update_command(
                device_id=device,
                os_update_mode=update_mode,
                version_type=update_type,
            )
