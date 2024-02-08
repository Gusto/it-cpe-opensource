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
ws1_webhooks_secrets = secrets.get_secret_value(SecretId=os.environ["SECRET_NAME"])[
    "SecretString"
]
secrets_dict = json.loads(ws1_webhooks_secrets)

# Environment variables
SNIPE_API_KEY = secrets_dict["SNIPE_API_KEY"]

# Environment variables
SNIPE_BASE_URL = os.environ.get("SNIPE_BASE_URL")
SNIPE_LAPTOP_CATEGORY_ID = os.environ.get("SNIPE_LAPTOP_CATEGORY_ID")
SNIPE_MANUFACTURER_ID_LENOVO = os.environ.get("SNIPE_MANUFACTURER_ID_LENOVO")
SNIPE_FIELDESET_ID = os.environ.get("SNIPE_FIELDESET_ID")

# Constants
SNIPE_HEADERS = {
    "Authorization": f"Bearer {SNIPE_API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json",
}


def serial_to_asset(event):
    try:
        serial_number = event["SerialNumber"]
        r = requests.get(
            f"{ SNIPE_BASE_URL }/hardware/byserial/{ serial_number }",
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if "total" not in r.json().keys():
            logger.info(f"No Snipe device found for {serial_number}")
            return create_snipe_asset(event)

        return r.json()["rows"][0]["id"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def search_snipe_models(event):
    # This is a bit of a hack to avoid having to request the device info from WS1.
    # We use the device's friendly name, which is something like "MacBookPro15,1-1337NOBEEF"
    try:
        if event["Platform"] == "WinRT":
            logger.info(f"Device is WinRT. Assuming generic Thinkpad model.")
            model_name = "Thinkpad"
        else:
            model_name = event["DeviceFriendlyName"]
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
        r = requests.post(
            f"{ SNIPE_BASE_URL }/models",
            headers=SNIPE_HEADERS,
            json={
                "name": model_name,
                "category_id": SNIPE_LAPTOP_CATEGORY_ID,
                "manufacturer_id": SNIPE_MANUFACTURER_ID_LENOVO,
                "fieldset_id": SNIPE_FIELDESET_ID,
            },
        )
        r.raise_for_status()
        logger.info(f"Created new model for { model_name }")
        return r.json()["payload"]["id"]

    except requests.exceptions.HTTPError as err:
        logger.error(f"Couldn't create model { model_name }")
        logger.error(err)


def create_snipe_asset(event):
    try:
        asset_payload = {
            "status_id": 2,  # Deployable
            "serial": event["SerialNumber"],
            "model_id": search_snipe_models(event),
        }
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware",
            json=asset_payload,
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if r.json()["status"] == "error":
            logger.info(r.json())
            logger.error(
                f"Error creating Snipe asset for {event['DeviceFriendlyName']}"
            )
        else:
            logger.info(f"Created Snipe asset for {event['DeviceFriendlyName']}.")

        return r.json()["payload"]["id"]  # Snipe device ID
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def create_snipe_user(event):
    try:
        password = f"{secrets.token_hex(16)}Snoopy1991."  # meet password complexity requirements
        user_payload = {
            "groups": None,
            "activated": False,
            "first_name": event["EnrollmentUserName"].split(".")[0],
            "last_name": event["EnrollmentUserName"].split(".")[1],
            "username": event["EnrollmentUserName"],
            "password": password,
            "password_confirmation": password,
            "email": event["EnrollmentEmailAddress"],
        }

        r = requests.post(
            f"{ SNIPE_BASE_URL }/users",
            json=user_payload,
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        logger.info(f'Created Snipe user for {event["EnrollmentEmailAddress"]}')
        return r.json()["payload"]["id"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def email_to_snipe_userid(event):
    try:
        r = requests.get(
            f"{ SNIPE_BASE_URL }/users?email={ event['EnrollmentEmailAddress'] }",
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        if r.json()["total"] == 0:
            logger.info(f"No Snipe user found for {event['EnrollmentEmailAddress']}")
            return create_snipe_user(event)
        else:
            logger.info(
                f"Snipe returned user id {r.json()['rows'][0]['id']} for {event['EnrollmentEmailAddress']}"
            )
            return r.json()["rows"][0]["id"]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def update_asset_name(event):
    try:
        r = requests.patch(
            f"{ SNIPE_BASE_URL }/hardware/{ serial_to_asset(event) }",
            headers=SNIPE_HEADERS,
            json={"name": event["DeviceFriendlyName"]},
        )
        r.raise_for_status()
        logger.info(
            f'Renamed {event["SerialNumber"]} to {event["DeviceFriendlyName"]}.'
        )
        return r
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def checkin_asset(event):
    try:
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware/{ serial_to_asset(event) }/checkin",
            headers=SNIPE_HEADERS,
        )
        r.raise_for_status()
        logger.info(f'Checked in device {event["SerialNumber"]}.')
        return r
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def checkout_asset(event):
    try:
        r = requests.post(
            f"{ SNIPE_BASE_URL }/hardware/{ serial_to_asset(event) }/checkout",
            headers=SNIPE_HEADERS,
            json={
                "assigned_user": email_to_snipe_userid(event),
                "checkout_to_type": "user",
                "name": event["DeviceFriendlyName"],
            },
        )
        r.raise_for_status()
        logger.info(
            f'Assigned {event["DeviceFriendlyName"]} to {event["EnrollmentEmailAddress"]}.'
        )
        return r
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


def lambda_handler(event, context):
    if event["EventId"] == 642:  # device name changed
        logger.info(f"Processing device name change event.")
        update_asset_name(event)
    elif event["EventId"] == 25:  # Device wipe
        logger.info(f"Processing device wipe event.")
        checkin_asset(event)
    elif event["EventId"] == 148 or event["EventId"] == 170:  # Device enrollment
        logger.info(f"Processing device enrollment event.")
        checkout_asset(event)
