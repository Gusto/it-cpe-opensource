# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

import boto3
import json
import logging
import os
import requests
import secrets
import sys
from requests.auth import HTTPBasicAuth

# Lambda's Python runtime messes with log formatting to make Cloudwatch work
logger = logging.getLogger()
logger.setLevel(logging.INFO)
# Add something like this when testing locally:
# logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s", level=logging.INFO)

secrets = boto3.client("secretsmanager")
snipe_secrets = secrets.get_secret_value(SecretId=os.environ["SECRET_NAME"])[
    "SecretString"
]
secrets_dict = json.loads(snipe_secrets)

SIMPLEMDM_API_KEY = secrets_dict["SIMPLEMDM_API_KEY"]
SNIPE_API_KEY = secrets_dict["SNIPE_API_KEY"]

# Environment variables
SNIPE_BASE_URL = os.environ.get("SNIPE_BASE_URL")

# Constants
SIMPLEMDM_AUTH = HTTPBasicAuth(SIMPLEMDM_API_KEY, "")

SNIPE_HEADERS = {
    "Authorization": f"Bearer {SNIPE_API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json",
}


def serial_to_asset(serial_number, simplemdm_device_id):
    try:
        r = requests.get(
            f"{ SNIPE_BASE_URL }/hardware/byserial/{ serial_number }",
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if "total" not in r.json().keys():
            logger.info(f"No Snipe device found for {serial_number}")
            return create_snipe_asset(simplemdm_device_id)

        return r.json()["rows"][0]["id"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def retrieve_device_custom_attributes(simplemdm_device_id):
    try:
        r = requests.get(
            f"{ SNIPE_BASE_URL }/devices/{simplemdm_device_id}/custom_attribute_values",
            auth=SIMPLEMDM_AUTH,
        )
        r.raise_for_status()
        device_custom_attributes = {}
        for i in r.json()["data"]:
            device_custom_attributes[i["id"]] = i["attributes"]["value"]
        return device_custom_attributes
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def email_to_snipe_userid(device_custom_attributes):
    try:
        r = requests.get(
            f"{ SNIPE_BASE_URL }/users?email={ device_custom_attributes['email'] }",
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if r.json()["total"] == 0:
            logger.info(f"No Snipe user found for {device_custom_attributes['email']}")
            return create_snipe_user(device_custom_attributes)
        else:
            logger.info(
                f"Snipe returned user id {r.json()['rows'][0]['id']} for {device_custom_attributes['email']}"
            )
            return r.json()["rows"][0]["id"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def create_snipe_user(device_custom_attributes):
    try:
        password = f"{secrets.token_hex(16)}Snoopyisfunny1991."  # meet password complexity requirements
        user_payload = {
            "groups": None,
            "activated": False,
            "first_name": device_custom_attributes["first_name"],
            "last_name": device_custom_attributes["last_name"],
            "username": device_custom_attributes["username"],
            "password": password,
            "password_confirmation": password,
            "email": device_custom_attributes["email"],
        }

        r = requests.post(
            f"{ SNIPE_BASE_URL }/users",
            json=user_payload,
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        logger.info(f'Created Snipe user for {device_custom_attributes["email"]}')
        return r.json()["payload"]["id"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def get_simplemdm_device_info(device_id):
    try:
        r = requests.get(
            f"{ SNIPE_BASE_URL }/devices/{device_id}",
            auth=SIMPLEMDM_AUTH,
        )
        r.raise_for_status()
        return r.json()["data"]["attributes"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def search_snipe_models(model_name):
    try:
        r = requests.get(
            f"{ SNIPE_BASE_URL }/models?search={ model_name }", headers=SNIPE_HEADERS
        )
        r.raise_for_status()
        if r.json()["total"] > 0:
            logger.info(f"Found Snipe model for { model_name }")
            return r.json()["rows"][0]["id"]
        else:
            logger.info(f"Couldn't find a model named { model_name }")
            return create_snipe_model(model_name)

    except requests.exceptions.HTTPError as err:
        logger.error(err)


def create_snipe_model(model_name):
    try:
        # Check if iOS device or MacBook
        if model_name.lower().startswith("i"):
            category_id = 9  # Tablet
        else:
            category_id = 3  # Laptop
        r = requests.post(
            f"{ SNIPE_BASE_URL }/models",
            headers=SNIPE_HEADERS,
            json={
                "name": model_name,
                "category_id": category_id,
                "manufacturer_id": 1,  # Hardcoded to 1 for Apple
                "fieldset_id": 2,  # Hardcoded fieldset
            },
        )
        r.raise_for_status()
        logger.info(f"Created new model for { model_name }")
        return r.json()["payload"]["id"]

    except requests.exceptions.HTTPError as err:
        logger.error(f"Couldn't create model { model_name }")
        logger.error(err)


def create_snipe_asset(simplemdm_device_id):
    try:
        simplemdm_device_info = get_simplemdm_device_info(simplemdm_device_id)
        asset_payload = {
            "status_id": 2,  # Deployable
            "serial": simplemdm_device_info["serial_number"],
            "model_id": search_snipe_models(simplemdm_device_info["model_name"]),
        }
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware",
            json=asset_payload,
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if r.json()["status"] == "error":
            logger.info(r.json())
            logger.error(f"Error creating Snipe asset for {simplemdm_device_id}")
        else:
            logger.info(f"Created Snipe asset for {simplemdm_device_id}")

        return r.json()["payload"]["id"]  # Snipe device ID
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def create_snipe_asset_from_abm(event):
    """Create assets from DEP records, which may not have a corresponding SimplemMDM device ID."""
    # TODO: combine this function with create_snipe_asset function, or write library
    try:
        serial_number = event["data"]["device"]["serial_number"]
        asset_payload = {
            "status_id": 2,  # Deployable
            "serial": serial_number,
            "model_id": search_snipe_models(event["data"]["device"]["model"]),
        }
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware",
            json=asset_payload,
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if r.json()["status"] == "error":
            logger.info(r.json())
            logger.error(f"Error creating Snipe asset for {serial_number}.")
        else:
            logger.info(
                f"Created Snipe asset {r.json()['payload']['id']} for {serial_number}."
            )

    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def checkin_asset(serial_number, simplemdm_device_id):
    try:
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware/{ serial_to_asset(serial_number, simplemdm_device_id) }/checkin",
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        logger.info(f"Checked in Snipe device {serial_number}")
        return r
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def checkout_asset(device_custom_attributes, serial_number, simplemdm_device_id):
    try:
        if len(device_custom_attributes["email"]) < 3:
            device_custom_attributes["email"] = (
                device_custom_attributes["username"]
                + "@"
                + device_custom_attributes["company"].replace(" ", "").lower()
                + ".com"
            )

        email = device_custom_attributes["email"]
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware/{ serial_to_asset(serial_number, simplemdm_device_id) }/checkout",
            headers=SNIPE_HEADERS,
            json={
                "assigned_user": email_to_snipe_userid(device_custom_attributes),
                "checkout_to_type": "user",
                "name": serial_number,
            },
        )
        r.raise_for_status()
        logger.info(f"Assigned {serial_number} to {email}")
        return r
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def lambda_handler(event, context):
    logger.info(f"Processing {event['type']} event")

    if "device" in event["data"].keys():
        serial_number = event["data"]["device"]["serial_number"]
        simplemdm_device_id = event["data"]["device"].get("id")

    if event["type"] == "device.enrolled":
        device_custom_attributes = retrieve_device_custom_attributes(
            simplemdm_device_id
        )
        if device_custom_attributes["username"] != "":
            # We need to check-in the laptop first to make it deployable
            checkin_asset(serial_number, simplemdm_device_id)
            checkout_asset(device_custom_attributes, serial_number, simplemdm_device_id)
        else:
            logger.info(
                f"Username attribute is empty. Skipping Snipe asset assignment."
            )
    elif event["type"] == "abm.device.added":
        create_snipe_asset_from_abm(event)
    elif event["type"] == "device.unenrolled":
        checkin_asset(serial_number, simplemdm_device_id)
