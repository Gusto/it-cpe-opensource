#!/usr/bin/env python3

# BSD-3-Clause
# Copyright (c) Facebook, Inc. and its affiliates.
# Copyright (c) tig <https://6fx.eu/>.
# Copyright (c) Gusto, Inc.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import os
import sys
import json
import plistlib
import requests
import subprocess
from pathlib import Path
from optparse import OptionParser
from datetime import datetime

DEBUG = os.environ.get("DEBUG", False)
METADATA_CACHE_PATH = os.environ.get("METADATA_CACHE_PATH", "/tmp/autopkg_metadata.json")
MUNKI_REPO = os.path.join(os.getenv("GITHUB_WORKSPACE", "/tmp/"), "munki_repo")
OVERRIDES_DIR = os.path.relpath("overrides/")
RECIPE_TO_RUN = os.environ.get("RECIPE", None)
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_TOKEN", None)


class Recipe(object):
    def __init__(self, path):
        self.path = os.path.join(OVERRIDES_DIR, path)
        self.error = False
        self.results = {}
        self.updated = False
        self.verified = None

        self._keys = None
        self._has_run = False

    @property
    def plist(self):
        if self._keys is None:
            with open(self.path, "rb") as f:
                self._keys = plistlib.load(f)

        return self._keys

    @property
    def branch(self):
        return (
            "{}_{}".format(self.name, self.updated_version)
            .strip()
            .replace(" ", "")
            .replace(")", "-")
            .replace("(", "-")
        )

    @property
    def updated_version(self):
        if not self.results or not self.results["imported"]:
            return None

        return self.results["imported"][0]["version"].strip().replace(" ", "")

    @property
    def name(self):
        return self.plist["Input"]["NAME"]

    def verify_trust_info(self):
        cmd = ["/usr/local/bin/autopkg", "verify-trust-info", self.path, "-vvv"]
        cmd = " ".join(cmd)

        if DEBUG:
            print("Running " + str(cmd))

        p = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True
        )
        (output, err) = p.communicate()
        p_status = p.wait()
        if p_status == 0:
            self.verified = True
        else:
            err = err.decode()
            self.results["message"] = err
            self.verified = False
        return self.verified

    def update_trust_info(self):
        cmd = ["/usr/local/bin/autopkg", "update-trust-info", self.path]
        cmd = " ".join(cmd)

        if DEBUG:
            print("Running " + str(cmd))

        # Fail loudly if this exits 0
        try:
            subprocess.check_call(cmd, shell=True)
        except subprocess.CalledProcessError as e:
            print(e.stderr)
            raise e

    def _parse_report(self, report):
        with open(report, "rb") as f:
            report_data = plistlib.load(f)

        failed_items = report_data.get("failures", [])
        imported_items = []
        if report_data["summary_results"]:
            # This means something happened
            munki_results = report_data["summary_results"].get(
                "munki_importer_summary_result", {}
            )
            imported_items.extend(munki_results.get("data_rows", []))

        return {"imported": imported_items, "failed": failed_items}

    def run(self):
        if self.verified == False:
            self.error = True
            self.results["failed"] = True
            self.results["imported"] = ""
        else:
            report = "/tmp/autopkg.plist"
            if not os.path.isfile(report):
                # Letting autopkg create them has led to errors on github runners
                Path(report).touch()

            try:
                cmd = [
                    "/usr/local/bin/autopkg",
                    "run",
                    self.path,
                    "-v",
                    "--post",
                    "io.github.hjuutilainen.VirusTotalAnalyzer/VirusTotalAnalyzer",
                    "--report-plist",
                    report,
                ]

                if opts.xattr:
                    cmd = cmd + [
                        "--post",
                        "com.github.williamtheaker.CacheRecipeMetadata/CacheRecipeMetadata",
                    ]

                cmd = " ".join(cmd)
                if DEBUG:
                    print("Running " + str(cmd))

                subprocess.check_call(cmd, shell=True)

            except subprocess.CalledProcessError as e:
                self.error = True

            self._has_run = True
            self.results = self._parse_report(report)
            if not self.results["failed"] and not self.error and self.updated_version:
                self.updated = True

        return self.results


### GIT FUNCTIONS
def git_run(cmd):
    cmd = ["git"] + cmd
    hide_cmd_output = True

    if DEBUG:
        print("Running " + " ".join(cmd))
        hide_cmd_output = False

    try:
        result = subprocess.run(
            " ".join(cmd), shell=True, cwd=MUNKI_REPO, capture_output=hide_cmd_output
        )
    except subprocess.CalledProcessError as e:
        print(e.stderr)
        raise e


def current_branch():
    git_run(["rev-parse", "--abbrev-ref", "HEAD"])


def checkout(branch, new=True):
    if current_branch() != "main" and branch != "main":
        checkout("main", new=False)

    gitcmd = ["checkout"]
    if new:
        gitcmd += ["-b"]

    gitcmd.append(branch)
    # Lazy branch exists check
    try:
        git_run(gitcmd)
    except subprocess.CalledProcessError as e:
        if new:
            checkout(branch, new=False)
        else:
            raise e


### Recipe handling
def handle_recipe(recipe, opts):
    if not opts.disable_verification:
        recipe.verify_trust_info()
        if recipe.verified is False:
            recipe.update_trust_info()
    if recipe.verified in (True, None):
        recipe.run()
        if recipe.results["imported"]:
            checkout(recipe.branch)
            for imported in recipe.results["imported"]:
                git_run(["add", f"'pkgs/{ imported['pkg_repo_path'] }'"])
                git_run(["add", f"'pkgsinfo/{ imported['pkginfo_path'] }'"])
            git_run(
                [
                    "commit",
                    "-m",
                    f"'Updated { recipe.name } to { recipe.updated_version }'",
                ]
            )
            git_run(["push", "--set-upstream", "origin", recipe.branch])
    return recipe


def parse_recipes(recipes):
    recipe_list = []
    ## Added this section so that we can run individual recipes
    if RECIPE_TO_RUN:
        for recipe in recipes:
            ext = os.path.splitext(recipe)[1]
            if ext != ".recipe":
                recipe_list.append(recipe + ".recipe")
            else:
                recipe_list.append(recipe)
    else:
        ext = os.path.splitext(recipes)[1]
        if ext == ".json":
            parser = json.load
        elif ext == ".plist":
            parser = plistlib.load
        else:
            print(f'Invalid run list extension "{ ext }" (expected plist or json)')
            sys.exit(1)

        with open(recipes, "rb") as f:
            recipe_list = parser(f)

    return map(Recipe, recipe_list)


## Icon handling
def import_icons():
    branch_name = "icon_import_{}".format(datetime.now().strftime("%Y-%m-%d"))
    checkout(branch_name)
    subprocess.check_call("/usr/local/munki/iconimporter munki_repo", shell=True)
    git_run(["add", "icons/"])
    git_run(["commit", "-m", "Added new icons"])
    git_run(["push", "--set-upstream", "origin", f"{branch_name}"])


## Metadata cache handling
def load_cached_attributes():
    # Load metadata cache file from disk
    with open(METADATA_CACHE_PATH, "r") as cache_file:
        cached_files = json.load(cache_file)
    return cached_files


def write_dummy_files(attributes_dict):
    # Python has no native support for extended attributes on macOS, so we shellout to write attributes to dummy files
    for i in attributes_dict:
        # Write text to file since AutoPkg ignores 0 byte files
        Path(attributes_dict[i]["pathname"]).write_text(
            "This is a dummy file for managing extended attribute values."
        )

        subprocess.Popen(
            f"xattr -w com.github.autopkg.etag '{ attributes_dict[i]['etag'] }' { attributes_dict[i]['pathname'] }",
            shell=True,
        )  # Write etag header
        subprocess.Popen(
            f"xattr -w com.github.autopkg.last-modified '{ attributes_dict[i]['last_modified'] }' { attributes_dict[i]['pathname'] }",
            shell=True,
        )  # Write last-modified header


def slack_alert(recipe, opts):
    if opts.debug:
        print("Debug: skipping Slack notification - debug is enabled!")
        return

    if SLACK_WEBHOOK_URL is None:
        print("Skipping Slack notification - webhook URL is missing!")
        return

    if not recipe.verified:
        task_title = f"{ recipe.name } failed trust verification"
        task_description = recipe.results["message"]
    elif recipe.error:
        task_title = f"Failed to import { recipe.name }"
        if not recipe.results["failed"]:
            task_description = "Unknown error"
        else:
            task_description = ("Error: {} \n" "Traceback: {} \n").format(
                recipe.results["failed"][0]["message"],
                recipe.results["failed"][0]["traceback"],
            )

            if "No releases found for repo" in task_description:
                # Just no updates
                return
    elif recipe.updated:
        task_title = "Imported %s %s" % (recipe.name, str(recipe.updated_version))
        task_description = (
            "*Catalogs:* %s \n" % recipe.results["imported"][0]["catalogs"]
            + "*Package Path:* `%s` \n" % recipe.results["imported"][0]["pkg_repo_path"]
            + "*Pkginfo Path:* `%s` \n" % recipe.results["imported"][0]["pkginfo_path"]
        )
    else:
        # Also no updates
        return

    response = requests.post(
        SLACK_WEBHOOK_URL,
        data=json.dumps(
            {
                "attachments": [
                    {
                        "username": "Autopkg",
                        "as_user": True,
                        "title": task_title,
                        "color": "warning"
                        if not recipe.verified
                        else "good"
                        if not recipe.error
                        else "danger",
                        "text": task_description,
                        "mrkdwn_in": ["text"],
                    }
                ]
            }
        ),
        headers={"Content-Type": "application/json"},
    )
    if response.status_code != 200:
        raise ValueError(
            "Request to slack returned an error %s, the response is:\n%s"
            % (response.status_code, response.text)
        )


def main():
    parser = OptionParser(description="Wrap AutoPkg with Git support.")
    parser.add_option(
        "-l", "--list", help="Path to a plist or JSON list of recipe names."
    )
    parser.add_option(
        "-g",
        "--gitrepo",
        help="Path to Git repo. Defaults to MUNKI_REPO from Autopkg preferences.",
        default=MUNKI_REPO,
    )
    parser.add_option(
        "-d",
        "--debug",
        action="store_true",
        help="Disables sending Slack alerts and adds more verbosity to output.",
    )
    parser.add_option(
        "-v",
        "--disable_verification",
        action="store_true",
        help="Disables recipe verification.",
    )
    parser.add_option(
        "-i",
        "--icons",
        action="store_true",
        help="Run iconimporter against Git Munki repo.",
    )
    parser.add_option(
        "-x",
        "--xattr",
        action="store_true",
        help="Load and write external extended attribute cache file.",
    )

    (opts, _) = parser.parse_args()

    global DEBUG
    DEBUG = bool(DEBUG or opts.debug)

    failures = []

    recipes = (
        RECIPE_TO_RUN.split(", ") if RECIPE_TO_RUN else opts.list if opts.list else None
    )
    if recipes is None:
        print("Recipe --list or RECIPE_TO_RUN not provided!")
        sys.exit(1)
    if opts.xattr:
        attributes_dict = load_cached_attributes()
        write_dummy_files(attributes_dict)
    recipes = parse_recipes(recipes)
    for recipe in recipes:
        handle_recipe(recipe, opts)
        slack_alert(recipe, opts)
        if not opts.disable_verification:
            if not recipe.verified:
                failures.append(recipe)
    if not opts.disable_verification:
        if failures:
            title = " ".join([f"{recipe.name}" for recipe in failures])
            lines = [f"{recipe.results['message']}\n" for recipe in failures]
            with open("pull_request_title", "a+") as title_file:
                title_file.write(f"Update trust for {title}")
            with open("pull_request_body", "a+") as body_file:
                body_file.writelines(lines)

    if opts.icons:
        import_icons()


if __name__ == "__main__":
    main()
