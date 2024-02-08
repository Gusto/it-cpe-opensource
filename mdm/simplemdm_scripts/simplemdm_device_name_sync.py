# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

import boto3
import json
import logging
import os
import time

# AWS Lambda's Python runtime messes with log formatting to make Cloudwatch work
logger = logging.getLogger()
# Add something like this when testing locally:
# logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s", level=logging.INFO)
logger.setLevel(logging.INFO)

import requests
from requests.auth import HTTPBasicAuth

# Secrets management
secrets = boto3.client("secretsmanager")
simplemdm_secrets = secrets.get_secret_value(SecretId=os.environ["SECRET_NAME"])[
    "SecretString"
]
secrets_dict = json.loads(simplemdm_secrets)
SIMPLEMDM_API_KEY = secrets_dict["SIMPLEMDM_API_KEY"]

# Environment variables
SIMPLEMDM_BASE_URL = os.environ["SIMPLEMDM_BASE_URL"]

# Constants
SIMPLEMDM_AUTH = HTTPBasicAuth(SIMPLEMDM_API_KEY, "")


def get_devices():
    """Get all known SimpleMDM devices. Paginates 100 records at a time. 200 success."""
    logger.info("Requesting list of all SimpleMDM devices.")

    has_more = True
    start_id = 0
    device_data = []
    while has_more:
        time.sleep(1)
        response = get_device_page(100, f"{ start_id }")
        data = response["data"]
        device_data.extend(data)
        has_more = response.get("has_more", None)
        if has_more:
            start_id = data[-1].get("id")
    return device_data


def get_device_page(limit, starting_afer=0):
    """Return a single page of devices from SimpleMDM."""
    r = requests.get(
        url=f"{ SIMPLEMDM_BASE_URL }/devices?limit={ limit }&starting_after={ starting_afer }",
        auth=SIMPLEMDM_AUTH,
    )
    if r.status_code == 200:
        return r.json()
    else:
        logger.error(r.text)
        raise SystemExit


def update_smdm_name(device_id, smdm_name):
    """Update the SimpleMDM name for a single device."""
    r = requests.patch(
        url=f"{ SIMPLEMDM_BASE_URL }/devices/{ device_id }",
        auth=SIMPLEMDM_AUTH,
        data={"name": f"{smdm_name}"},
    )
    if r.status_code != 200:
        logger.error(r.text)
        logger.error(
            f"Failed to update name. Device ID: {device_id}. SimpleMDM name: {smdm_name}."
        )


def lambda_handler(event, context):
    device_list = get_devices()
    total_names_updated = 0
    for device in device_list:
        device_id = device["id"]
        device_attributes = device["attributes"]
        model = device_attributes.get("model", None)
        device_name = device_attributes.get("device_name", None)
        smdm_name = device_attributes.get("name", None)

        if model is None or "Mac" not in model:
            continue

        if smdm_name != device_name and device_name is not None:
            update_smdm_name(device_id, device_name)
            logger.info(
                f"Updated { device_id } name from { smdm_name } to { device_name }"
            )
            total_names_updated += 1

    logger.info(f"Updated { total_names_updated } device name(s).")
