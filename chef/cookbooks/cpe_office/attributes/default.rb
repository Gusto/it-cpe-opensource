#
# Cookbook:: cpe_office
# Attributes:: default
#
#
# Copyright:: (c) 2021-present, Gusto, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#

default["cpe_office"]["configure"] = false

default["cpe_office"]["mac"] = {
  "mau" => {
    "ChannelName" => nil,
    "DisableInsiderCheckbox" => nil,
    "ExtendedLogging" => nil,
    "HowToCheck" => "AutomaticDownload",
    "ManifestServer" => nil,
    "SendAllTelemetryEnabled" => nil,
    "StartDaemonOnAppLaunch" => true,
    "UpdateCache" => nil,
    "AcknowledgedDataCollectionPolicy" => nil,
  },
  "o365" => {
    "SendAllTelemetryEnabled" => false,
  },
  "onenote" => {
    "FirstRunExperienceCompletedO15" => true,
    "kSubUIAppCompletedFirstRunSetup1507" => true,
    "SendAllTelemetryEnabled" => false,
    "OUIShouldEstablishWhatsNewBaseline" => true,
    "OUIWhatsNewLastShownLink" => [18051],
  },
  "excel" => {
    "kSubUIAppCompletedFirstRunSetup1507" => true,
    "SendAllTelemetryEnabled" => false,
    "OUIShouldEstablishWhatsNewBaseline" => true,
    "OUIWhatsNewLastShownLink" => [18051, 18052],
  },
  "outlook" => {
    "AutomaitcallyDownloadExternalContent" => nil,
    "kSubUIAppCompletedFirstRunSetup1507" => true,
    "SendAllTelemetryEnabled" => false,
    "OUIWhatsNewLastShownLink" => nil,
    "TrustO365AutodiscoverRedirect" => nil,
  },
  "powerpoint" => {
    "kSubUIAppCompletedFirstRunSetup1507" => true,
    "SendAllTelemetryEnabled" => false,
    "OUIShouldEstablishWhatsNewBaseline" => true,
    "OUIWhatsNewLastShownLink" => [18051],
  },
  "word" => {
    "kSubUIAppCompletedFirstRunSetup1507" => true,
    "SendAllTelemetryEnabled" => false,
    "OUIShouldEstablishWhatsNewBaseline" => true,
    "OUIWhatsNewLastShownLink" => [18051],
  },
  "global" => {
    "VisualBasicMacroExecutionState" => "DisabledWithWarnings",
  },
}

node.default["cpe_office"]["win"]["global"] = {
  "Common" => {
    "SendCustomerData" => {
      "data" => nil, # Disable telemetry
    },
    "LinkedIn" => {
      "data" => nil, # Disable LinkedIn
    },
    "qmenable" => {
      "data" => nil, # Disable telemetry
    },
  },
  'Common\ClientTelemetry' => {
    "SendTelemetry" => {
      "data" => nil, # Disable telemetry
    },
  },
  'Common\General' => {
    "OptinDisable" => {
      "data" => nil, # Suppress recommended settings dialog
    },
    "ShownFirstRunOptin" => {
      "data" => nil, # Suppress first run consent popup
    },
  },
  'Common\Privacy' => {
    "DisconnectedState" => {
      "data" => nil, # Disable connected experiences
    },
    "UserContentDisabled" => {
      "data" => nil, # Disable content analysis
    },
    "DownloadContentDisabled" => {
      "data" => nil, # Disable content download
    },
    "ControllerConnectedServicesEnabled" => {
      "data" => nil, # Disable additional optional connected experiences
    },
  },
  "Feedback" => {
    "enabled" => {
      "data" => nil, # Disable telemetry
    },
  },
  "Registration" => {
    "AcceptAllEULAs" => {
      "data" => nil, # Accept EULA
    },
  },
}

node.default["cpe_office"]["win"]["excel"] = {
  "Options" => {
    "AlertIfNotDefault" => {
      "data" => nil, # Don't nag user
    },
  },
  'Security\Trusted Documents' => {
    "DisableTrustedDocuments" => {
      "data" => nil, # Don't allow documents to bypass macro settings
    },
  },
  "Security" => {
    "VBAwarnings" => {
      "data" => nil, # Disable macros without warning
    },
  },
}

node.default["cpe_office"]["win"]["powerpoint"] = {
  "Options" => {
    "AlertIfNotDefault" => {
      "data" => nil, # Don't nag user
    },
  },
  'Security\Trusted Documents' => {
    "DisableTrustedDocuments" => {
      "data" => nil, # Don't allow documents to bypass macro settings
    },
  },
  "Security" => {
    "VBAwarnings" => {
      "data" => nil, # Disable macros without warning
    },
  },
}

node.default["cpe_office"]["win"]["word"] = {
  "Options" => {
    "AlertIfNotDefault" => {
      "data" => nil, # Don't nag user
    },
  },
  'Security\Trusted Documents' => {
    "DisableTrustedDocuments" => {
      "data" => nil, # Don't allow documents to bypass macro settings
    },
  },
  "Security" => {
    "VBAwarnings" => {
      "data" => nil,  # Disable macros without warning
    },
  },
}
