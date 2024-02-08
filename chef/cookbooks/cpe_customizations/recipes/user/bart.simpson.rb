# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_customizations
# Recipe:: users/bart.simpson

node.default["cpe_firefox"]["profile"]["3rdparty"]["Extensions"]["uBlock0@raymondhill.net"]["toAdd"]["trustedSiteDirectives"] = []
node.default["cpe_ublock"]["toOverwrite"]["filterLists"] += [
  "fanboy-cookiemonster",
]

node.default["cpe_firefox"]["profile"]["3rdparty"]["Extensions"]["uBlock0@raymondhill.net"]["toOverwrite"]["filterLists"] += [
  "fanboy-cookiemonster",
  "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/ClearURLs%20for%20uBo/clear_urls_uboified.txt",
]

node.default["cpe_firefox"]["profile"]["Cookies"]["AcceptThirdParty"] = "never"
node.default["cpe_firefox"]["profile"]["Cookies"]["RejectTracker"] = true
node.default["cpe_firefox"]["profile"]["DisableFirefoxAccounts"] = true
node.default["cpe_firefox"]["profile"]["DisableFormHistory"] = true # doesn't disable address or credit card autofill
node.default["cpe_firefox"]["profile"]["DisplayBookmarksToolbar"] = true
node.default["cpe_firefox"]["profile"]["EncryptedMediaExtensions"]["Enabled"] = false # Don't enable DRM
node.default["cpe_firefox"]["profile"]["EncryptedMediaExtensions"]["Locked"] = true # Don't download DRM plugin
node.default["cpe_firefox"]["profile"]["FirefoxHome"]["Highlights"] = false
node.default["cpe_firefox"]["profile"]["FirefoxHome"]["Snippets"] = false
node.default["cpe_firefox"]["profile"]["FirefoxHome"]["TopSites"] = false
node.default["cpe_firefox"]["profile"]["SanitizeOnShutdown"]["History"] = true
node.default["cpe_firefox"]["profile"]["SearchBar"] = "separate"
node.default["cpe_firefox"]["profile"]["SearchSuggestEnabled"] = false
node.default["cpe_firefox"]["profile"]["ShowHomeButton"] = false

node.default["cpe_firefox"]["profile"]["ExtensionSettings"].merge!({
  "amazondotcom@search.mozilla.org" => {
    "installation_mode" => "blocked",
  },
  "bing@search.mozilla.org" => {
    "installation_mode" => "blocked",
  },
  "ebay@search.mozilla.org" => {
    "installation_mode" => "blocked",
  },
  "google@search.mozilla.org" => {
    "installation_mode" => "blocked",
  },
  "wikipedia@search.mozilla.org" => {
    "installation_mode" => "blocked",
  },
  "plugin@okta.com" => {
    "installation_mode" => "allowed",
    "install_url" => "https://addons.mozilla.org/firefox/downloads/latest/okta-browser-plugin/latest.xpi",
  },
  "jid1-BoFifL9Vbdl2zQ@jetpack" => {
    "installation_mode" => "normal_installed",
    "install_url" => "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi",
  },
  "sponsorBlocker@ajay.app" => {
    "installation_mode" => "normal_installed",
    "install_url" => "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi",
  },
  "uBlock0@raymondhill.net" => {
    "installation_mode" => "normal_installed",
    "install_url" => "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
  },
  "CookieAutoDelete@kennydo.com" => {
    "installation_mode" => "normal_installed",
    "install_url" => "https://addons.mozilla.org/firefox/downloads/latest/cookie-autodelete/latest.xpi",
  },
  })

node.default["cpe_zoom"]["ConfirmWhenLeave"] = false
node.default["cpe_zoom"]["EnableFaceBeauty"] = false # blemishes are ok
node.default["cpe_zoom"]["MuteVoipWhenJoin"] = true
node.default["cpe_zoom"]["ZDisableVideo"] = true
node.default["cpe_zoom"]["SetUseSystemDefaultMicForVOIP"] = true
node.default["cpe_zoom"]["SetUseSystemDefaultSpeakerForVOIP"] = true

if macos?
  node.default["cpe_munki"]["local"]["managed_installs"] += [
    "Firefox",
    "iTerm2",
    "VLC",
  ]
elsif windows?
end
