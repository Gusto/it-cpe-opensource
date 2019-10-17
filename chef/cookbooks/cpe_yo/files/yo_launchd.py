#!/usr/bin/python
# Copyright 2014-2017 Shea G. Craig
# Portions copyright © 2019 ZenPayroll, Inc., dba Gusto
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
"""Manage Yo notifications

This tool helps schedule yo notifications. It solves several problems
for administrators.

First, it ensures that the proper application context is available prior
to attempting to run the yo binary, which will fail if not run as the
current console user.

The scheduler ensures that any notification is delivered at least once
to each user. If they are not logged in when configured, the
notification will be delivered immediately after their next login.

Admins may specify a date after which notifications are no-longer
considered deliverable, ensuring notifications aren't delivered to
infrequently used accounts long-past their freshness date.

Likewise, a list of accounts for which delivering notifications should
be skipped may be specified on a per-notification and a global basis.

Normally, the tool must be run as root. For testing purposes,  you may
trigger a notification for the current console user by running this tool
with that user's account.

Unless cleared, the `com.sheagcraig.yo` preference domain caches
all notifications so that they may be delivered to any user of the
system without foreknowledge of their username, infinitely into the
future. The yo_scheduler includes a flag to clear cached notifications
while retaining any other preferences.
"""

import os
import sys
import pytz
import argparse
import plistlib as plist
from datetime import time, datetime
from subprocess import call, check_call, CalledProcessError

# pylint: disable=import-error
from SystemConfiguration import SCDynamicStoreCopyConsoleUser

# pylint: enable=import-error


__version__ = "2.0.1"
BUNDLE_ID = "com.sheacraig.yo"
WATCH_PATH = "/var/run/com.sheacraig.chef.scheduler.yo.on_demand.launchd"
SCHEDULE_PATH = "/usr/local/lib/yo/schedule.plist"
RECEIPTS_PATH = "/usr/local/lib/yo/.receipts"
YO_BINARY = "/Applications/Utilities/yo.app/Contents/MacOS/yo"


def main():
    """Application main"""
    sys.stdout.write("Running yo\n")
    global USER_RECEIPTS_PATH
    USER_RECEIPTS_PATH = "/Users/{}/Library/Yo/.receipts".format(get_console_user()[0])
    process_notifications()


def unix_timestamp(datetime_object):
    """:troll: Python 2.7"""
    the_70s = datetime(1970, 1, 1, 0, 0, 0, tzinfo=pytz.utc)
    return int((datetime_object - the_70s).total_seconds())


def run_yo_with_args(arg_str):
    """Run the yo binary with supplied args using subprocess"""
    args = "{} {}".format(YO_BINARY, arg_str)
    call(args, shell=True)


def check_conditional(arg_str, conditions):
    """
    Run a conditional script and check return code, returning false if
    non-zero, or true if successful or no conidtional script exists
    """
    condition = conditions.get(arg_str)
    if not condition:
        return True

    try:
        check_call(path)
        return True
    except CalledProcessError as e:
        return False


def check_time(utc_time):
    n = datetime.utcnow().replace(tzinfo=pytz.utc)
    return n >= utc_time


def process_notifications():
    """Process scheduled notifications for current console user

    Compare list of scheduled notifications against receipts for
    the user, and only deliver if notification has not previously been
    sent.
    """
    receipts = get_receipts()
    schedule = get_schedule()
    for arg_str, time_condition in schedule.get("notifications", {}).iteritems():
        sys.stdout.write("Considering {}\n".format(arg_str))
        utc_time = time_condition.replace(tzinfo=pytz.utc)
        receipt_key = arg_str + str(unix_timestamp(utc_time))
        if (
            receipt_key not in receipts.keys()
            and check_conditional(arg_str, schedule.get("conditions", {}))
            and check_time(utc_time)
        ):
            sys.stdout.write("Running {} (Known as {})\n".format(arg_str, receipt_key))
            run_yo_with_args(arg_str)
            add_receipt(receipt_key)


def get_schedule():
    """Get a dictionary of all scheduled notification arguments"""
    # We _can_ use CopyAppValue here because the preferences have been
    # set for AnyUser.
    tmp = "/tmp/schedule.plist"
    cmd = "/usr/bin/plutil -convert xml1 -o {} {}".format(tmp, SCHEDULE_PATH)
    call(cmd, shell=True)
    r = plist.readPlist(tmp)
    os.remove(tmp)
    return r


def get_receipts():
    """Get a dictionary of all scheduled notification arguments"""
    # We _can_ use CopyAppValue here because the preferences have been
    # set for AnyUser.
    if not os.path.isfile(USER_RECEIPTS_PATH):
        return {}

    tmp = "/tmp/receipts.plist"
    cmd = "/usr/bin/plutil -convert xml1 -o {} {}".format(tmp, USER_RECEIPTS_PATH)
    call(cmd, shell=True)
    r = plist.readPlist(tmp)
    os.remove(tmp)
    return r


def add_receipt(receipt_key, stamp=None):
    """Add a receipt to current users receipt file."""
    receipts = get_receipts()
    if not stamp:
        stamp = datetime.now()
    receipts[receipt_key] = stamp
    plist.writePlist(receipts, USER_RECEIPTS_PATH)


def is_console_user():
    """Test for whether current user is the current console user"""
    console_user = get_console_user()
    return False if not console_user[0] else os.getuid() == console_user[1]


def get_console_user():
    """Get informatino about the console user

    Returns:
        3-Tuple of (str) username, (int) uid, (int) gid
    """
    return SCDynamicStoreCopyConsoleUser(None, None, None)


def exit_if_not_root():
    """Exit if executing user is not root"""
    if os.getuid() != 0:
        sys.exit("Only the root user may run yo_launchd.py")


if __name__ == "__main__":
    main()
