#!/usr/bin/env python3

import os
import sys
import json
import plistlib
import requests
import subprocess
from pathlib import Path
from optparse import OptionParser
from datetime import datetime


DEBUG = False
SLACK_WEBHOOK = os.environ.get("SLACK_WEBHOOK_TOKEN", None)
MUNKI_REPO = os.path.join(os.getenv("GITHUB_WORKSPACE", "/tmp/"), "munki_repo")
OVERRIDES_DIR = os.path.relpath("overrides/")
RECIPE_TO_RUN = os.environ.get("RECIPE", None)

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
        result = subprocess.run(" ".join(cmd), shell=True, cwd=MUNKI_REPO, capture_output=hide_cmd_output)
    except subprocess.CalledProcessError as e:
        print(e.stderr)
        raise e


def current_branch():
    git_run(["rev-parse", "--abbrev-ref", "HEAD"])


def checkout(branch, new=True):
    if current_branch() != "master" and branch != "master":
        checkout("master", new=False)

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
    result = subprocess.check_call(
        "/usr/local/munki/iconimporter munki_repo", shell=True
    )
    git_run(["add", "icons/"])
    git_run(["commit", "-m", "Added new icons"])
    git_run(["push", "--set-upstream", "origin", f"{branch_name}"])


def slack_alert(recipe, opts):
    if opts.debug:
        print("Debug: skipping Slack notification - debug is enabled!")
        return

    if SLACK_WEBHOOK is None:
        print("Skipping slack notification - webhook is missing!")
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
        SLACK_WEBHOOK,
        data=json.dumps(
            {
                "attachments": [
                    {
                        "username": "Autopkg",
                        "as_user": True,
                        "title": task_title,
                        "color": "warning" if not recipe.verified else "good" if not recipe.error else "danger",
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
    parser = OptionParser(description="Wrap AutoPkg with git support.")
    parser.add_option(
        "-l", "--list", help="Path to a plist or JSON list of recipe names."
    )
    parser.add_option(
        "-g",
        "--gitrepo",
        help="Path to git repo. Defaults to MUNKI_REPO from Autopkg preferences.",
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
        help="Run iconimporter against git munki repo.",
    )

    (opts, _) = parser.parse_args()

    global DEBUG
    DEBUG = bool(opts.debug)

    failures = []

    recipes = RECIPE_TO_RUN.split(", ") if RECIPE_TO_RUN else opts.list if opts.list else None
    if recipes is None:
        print("Recipe --list or RECIPE_TO_RUN not provided!")
        sys.exit(1)
    recipes = parse_recipes(recipes)
    for recipe in recipes:
        handle_recipe(recipe, opts)
        slack_alert(recipe, opts)
        if not opts.disable_verification:
            if not recipe.verified:
                failures.append(recipe)
    if not opts.disable_verification:
        if failures:
            title_file=open("pull_request_title","a+")
            title_file.write("fix: Update trust for")
            body_file=open("pull_request_body","a+")
            for recipe in failures:
                title_file.write(" " + recipe.name)
                body_file.write(recipe.results["message"] + "\n")
            title_file.close()
            body_file.close()

    if opts.icons:
        import_icons()


if __name__ == "__main__":
    main()
