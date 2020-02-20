#
#
# Cookbook Name:: cpe_anyconnect
# Attributes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

# Only declare your basic attributes here.
# By default, these values should usually be `nil` or `false`, such that
# your cookbook should be a complete no-op if ran as-is.

# If you don't intend for someone to be able to overwrite a value,
# do not make it an attribute. All attributes are expected to be modifiable by
# any sort of customization.

default['cpe_anyconnect']['enabled'] = false

default['cpe_anyconnect']['server_preferences'] =
  {
    "ClientInitialization" => [{

      "ShowPreConnectMessage" => [false],
      "CertificateStore" => ["All"],
      "CertificateStoreMac" => ["Login"],
      "CertificateStoreOverride" => [false],
      "SuspendOnConnectedStandby" => [nil],
      "WindowsLogonEnforcement" => ["SingleLocalLogon"],
      "LinuxLogonEnforcement" => [nil],
      "WindowsVPNEstablishment" => ["LocalUsersOnly"],
      "LinuxVPNEstablishment" => [nil],
      "AuthenticationTimeout" => [12],
      "AllowIPsecOverSSL" => [nil],
      "ClearSmartcardPin" => [{"UserControllable" => true, "content" => true}],
      "ServiceDisable" => [nil],
      "IPProtocolSupport" => ["IPv4,IPv6"],
      "CaptivePortalRemediationBrowserFailover" => [nil],
      "AllowManualHostInput" => [false],

      "UseStartBeforeLogon" =>
      [{"UserControllable" => true, "content" => false}],

      "AutomaticCertSelection" =>
      [{"UserControllable" => true, "content" => false}],

      "AllowLocalProxyConnections" => [true],

      "AutoConnectOnStart" =>
      [{"UserControllable" => true, "content" => false}],

      "MinimizeOnConnect" =>
      [{"UserControllable" => true, "content" => true}],

      "LocalLanAccess" =>
      [{"UserControllable" => true, "content" => true}],

      "DisableCaptivePortalDetection" =>
      [{"UserControllable" => false, "content" => nil}],

      "AutoUpdate" =>
      [{"UserControllable" => true, "content" => false}],

      "RSASecurIDIntegration" =>
      [{"UserControllable" => false, "content" => 'Automatic'}],

      "RetainVpnOnLogoff" =>
      [{"UserEnforcement" => nil, "content" => false}],

      "BackupServerList" =>
      [{"HostAddress" => [{}]}],

      "SafeWordSofTokenIntegration" =>
      [{"UserControllable" => false, "content" => nil}],

      "AutoReconnect" => [{
        "UserControllable" => false,
        "content" => true,
        "AutoReconnectBehavior" =>
        [{"UserControllable" => false, "content" => "DisconnectOnSuspend"}]}],

      "ProxySettings" => [{
        "content" => "Native",
        "PublicProxyServerAddress" =>
        [{"UserControllable" => false, "content" => nil}]}],

      "AutomaticVPNPolicy" => [{
        "content" => false,
        "TrustedDNSDomains" => [nil],
        "TrustedDNSServers" => [nil],
        "TrustedNetworkPolicy" => [nil],
        "UntrustedNetworkPolicy" => [nil],

        "TrustedHttpsServerList" => [{
          "TrustedHttpsServer" => [{
            "Address" => [nil],
            "Port" => [nil],
            "CertificateHash" => [nil]}]}],

         "AlwaysOn" => [{
           "ConnectFailurePolicy" => [{
             "AllowCaptivePortalRemediation" =>
             [{"CaptivePortalRemediationTimeout" => [nil]}],
             "ApplyLastVPNLocalResourceRules" => [nil]}],
             "AllowVPNDisconnect" => [nil]}]}],

      "PPPExclusion" => [{
        "UserControllable" => false,
        "content" => "Disable",
        "PPPExclusionServerIP" =>
        [{"UserControllable" => false, "content" => "Disable"}]}],

      "EnableScripting" => [{
        "UserControllable" => false,
        "content" => false,
        "TerminateScriptOnNextEvent" => [nil],
        "EnablePostSBLOnConnectScript" => [nil]}],

      "CertificatePinning" => [{
        "CertificatePinList" => [{
          "Pin" => [{
            "Subject" => nil,
            "Issuer" => nil,
            "content" => nil}]}]}],

      "CertificateMatch" => [{
        "MatchOnlyCertsWithEKU" => [nil],
        "MatchOnlyCertsWithKU" => [nil],
        "KeyUsage" =>
        [{"MatchKey" => [nil]}],

        "ExtendedKeyUsage" => [{
          "ExtendedMatchKey" => [nil],
          "CustomExtendedMatchKey" => [nil]}],

        "DistinguishedName" => [{
          "DistinguishedNameDefinition" => [{
            "Wildcard" => nil,
            "Operator" => nil,
            "MatchCase" => nil,
            "Name" => [nil],
            "Pattern" => [nil]}]}]}],

      "MobilePolicy" => [{
        "DeviceLockRequired" => [{
          "MaximumTimeoutMinutes" => nil,
          "MinimumPasswordLength" => nil,
          "PasswordComplexity" => nil}]}],

      "CertificateEnrollment" => [{
        "CertificateExpirationThreshold" => [nil],
        "AutomaticSCEPHost" => [nil],
        "CertificateImportStore" => [nil],

        "CAURL" => [{
          "PromptForChallengePW" => nil,
          "Thumbprint" => nil,
          "content" => nil}],

        "CertificateSCEP" => [{
          "CADomain" => [nil],
          "Name_CN" => [nil],
          "Department_OU" => [nil],
          "Company_O" => [nil],
          "State_ST" => [nil],
          "State_SP" => [nil],
          "Country_C" => [nil],
          "Email_EA" => [nil],
          "Domain_DC" => [nil],
          "SurName_SN" => [nil],
          "GivenName_GN" => [nil],
          "UnstructName_N" => [nil],
          "Initials_I" => [nil],
          "Qualifier_GEN" => [nil],
          "Qualifier_DN" => [nil],
          "City_L" => [nil],
          "Title_T" => [nil],
          "KeySize" => [nil],
          "DisplayGetCertButton" => [nil],
          "CertificateAccessControl" => [nil]}]}],

      "DeviceLockRequired" => [{
        "DeviceLockMaximumTimeoutMinutes" => [nil],
        "DeviceLockMinimumPasswordLength" => [nil],
        "DeviceLockPasswordComplexity" => [nil]}],

      "EnableAutomaticServerSelection" => [{
        "UserControllable" => false,
        "AutoServerSelectionImprovement" => [20],
        "AutoServerSelectionSuspendTime" => [4],
        "content" => false}],
    }],

    "ServerList" => [{
        "HostEntry" => [{
          "HostName" =>
          [{'content' => 'EXAMPLE SERVER'}],
          "HostAddress" =>
          [{'content' => 'example0.addr.com'}]
        }],

        "HostEntry" => [{
          "HostName" =>
          [{'content' => 'EXAMPLE SERVER 1'}],
          "HostAddress" =>
          [{'content' => 'example1.addr.com'}]}]}]
}

default['cpe_anyconnect']['global_preferences'] = {
  'DefaultUser' => [{"UserControllable" => false, "content" => nil}],
  'DefaultSecondUser' => [{"UserControllable" => false, "content" => nil}],
  'ClientCertificateThumbprint' => [{"UserControllable" => false, "content" => nil}],
  'MultipleClientCertificateThumbprints' => [{"UserControllable" => false, "content" => nil}],
  'ServerCertificateThumbprint' => [{"UserControllable" => false, "content" => nil}],
  'DefaultHostName' => [{"UserControllable" => false, "content" => "EXAMPLE SERVER"}],
  'DefaultHostAddress' => [{"UserControllable" => false, "content" => "example.addr.com"}],
  'DefaultGroup' => [{"UserControllable" => false, "content" => nil}],
  'ProxyHost' => [{"UserControllable" => false, "content" => nil}],
  'ProxyPort' => [{"UserControllable" => false, "content" => nil}],
  'SDITokenType' => [{"UserControllable" => false, "content" => 'none'}],
  'ControllablePreferences' => [{"UserControllable" => false, "content" => nil}]
}

default['cpe_anyconnect']['validation'] = {
  'strict' => true,
  'write_anyways' => true
}

default['cpe_anyconnect']['shim'] = {
  'flags' => {
    'example' => 'EXAMPLE SERVER',
  },
  'enabled' => false,
  'command_name' => 'vpn-shortcut',
  'default' => 'example',
  'passcode' => 'push',
  'script_path' => '/opt/vpn-shortcut.sh'
}
