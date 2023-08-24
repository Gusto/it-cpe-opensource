This directory contains an example setup of using Github Actions to orchestrate AutoPkg and Munki.

### How it works

We've supplied an example override for Firefox.

The different workflows run on a staggered schedule to avoid merge conflicts. AutoPkg can also be run on-demand.


* `autopkg.yml` - Checks out the latest version of your autopkg overrides, installs Munki and autopkg, then clones all the upstream recipe repos. We forked Facebook's `autopkg_tools.py` script, which iterates over a list of recipes, and successful builds are pushed into a separate Git LFS repo. The build results are posted to a Slack channel so we can fix any recipe trust issues with a pull request. This also runs hjuutilainen's VirusTotalAnalyzer post-processor.

* `repoclean.yml` - Pares your Munki repo down to the two newest versions of each package.

* `autopromote.yml` - Moves your Munki packages through catalogs on a set schedule.


## GitHub Actions specifics

GitHub releases can be changed after publishing, which can make your build environment change without any indication. If an action’s repo get compromised a tag could point to malicious code. We pin the SHA1 commit hash for actions instead, since git and GitHub have robust protections against SHA1 collisions.

### Setting up your local machine

Because of how AutoPkg handles relative paths, the directory paths on your machine must match the ones on the AutoPkg runner for recipes to run properly. You can see an example of the paths and preferences we use in `autopkg.yml`

### Using this repo

1. Create an empty GitHub repo with Actions enabled.
1. Copy `workflows/` to `.github/` in this repo.
1. Create an override: `autopkg make-override recipename.munki` or if there are multiple recipes with the same filename, `autopkg make-override com.github.recipe.identifier` (be sure to place it in `overrides/`)
1. Add the recipe filename to `recipe_list.json`
1. Add the repo to `repo_list.txt`
1. Create another empty Github repo with Actions enabled. This will be your munki repo.
1. In your munki repo, create a [GitHub deploy key](https://docs.github.com/en/developers/overview/managing-deploy-keys#setup-2) with read/write access to repo.
1. Copy the name of your Munki git repo to the `Checkout your munki LFS repo` step in `autopkg.yml`
1. Add the private key for your Munki repo deploy key as a Github Actions secret named `CPE_MUNKI_LFS_DEPLOY_KEY` in your AutoPkg repo. Optionally, if using Slack, add Github Actions secrets for `SLACK_WEBHOOK_URL` (a URL to post AutoPkg results in Slack) and `AUTOPROMOTE_SLACK_TOKEN`.

### YAML support

With YAML becoming more popular for AutoPkg recipes and overrides, this runner now includes YAML support. Simply ensure the recipe list uses the full file name including a `.yaml` extension.

```json
[
  "Firefox.munki.recipe.yaml",
  "GoogleChrome.munki.recipe.yaml"
]
```


## Credits

[autopkg_tools.py](https://github.com/facebook/IT-CPE/tree/master/legacy/autopkg_tools) from Facebook under a BSD 3-clause license with modifications from [tig](https://6fx.eu).
