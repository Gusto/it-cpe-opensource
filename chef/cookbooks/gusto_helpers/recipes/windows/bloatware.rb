# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: gusto_helpers
# Recipes:: windows/bloatware

return if virtual?

hostile_microsoft_keys = [
  {
  "path": 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\ActiveX Compatibility\{D27CDB6E-AE6D-11CF-96B8-444553540000}',
  "name": "Compatibility Flags", # Disable ActiveX Flash plugin for IE
  "type": :dword,
  "data": "00000400",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\ActiveX Compatibility\{D27CDB6E-AE6D-11CF-96B8-444553540000}',
  "name": "Compatibility Flags", # Disable ActiveX Flash plugin for IE
  "type": :dword,
  "data": "00000400",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MicrosoftEdge\ActiveX Compatibility\{D27CDB6E-AE6D-11cf-96B8-444553540000}',
  "name": "Compatibility Flags", # Disable ActiveX Flash plugin for IE
  "type": :dword,
  "data": "00000400",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search',
  "name": "BingSearchEnabled", # Disable Bing searches in start menu
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SystemPaneSuggestionsEnabled", # Disable app suggestions in start menu
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SubscribedContent-338389Enabled", # Disable Windows suggestions in apps
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SubscribedContent-310093Enabled", # Disable Windows features suggestions on login
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced',
  "name": "Start_TrackProgs", # Disable 'Let Windows track app launches to improve Start and search results'
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo',
  "name": "Enabled", # Don't let apps create unique advertising ID
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Input\TIPC',
  "name": "Enabled", # Don't show ads
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced',
  "name": "Start_TrackProgs", # Don't let Windows track app launches
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
  "name": "DoNotShowFeedbackNotifications", # Don't collect feedback
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
  "name": "AllowTelemetry", # Don't share telemetry
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Control Panel\International\User Profile',
  "name": "HttpAcceptLanguageOptOut", # Disable 'Let websites provide locally relevant content by accessing my language list'
  "type": :dword,
  "data": "1",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SubscribedContent-338393Enabled", # Disable 'Show me suggested content in the Settings app' 1
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SubscribedContent-353694Enabled", # Disable 'Show me suggested content in the Settings app' 2
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SubscribedContent-353696Enabled", # Disable 'Show me suggested content in the Settings app' 3
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement',
  "name": "ScoobeSystemSettingEnabled", # Disable "Get even more out of Windows" suggestions
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager',
  "name": "SubscribedContent-353698Enabled", # Disable "Show suggestions in your timeline"
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance',
  "name": "fAllowToGetHelp", # Disable remote assistance connections
  "type": :dword,
  "data": "0",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppPrivacy',
  "name": "LetAppsGetDiagnosticInfo", # Disable 'Let Windows apps access diagnostic information about other apps'
  "type": :dword,
  "data": "2",
  },
  {
  "path": 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main',
  "name": "NotifyDisableIEOptions", # Disable Internet Explorer 11 as a standalone browser
  "type": :dword,
  "data": "1",
  },
  {
  "path": 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Feeds',
  "name": "ShellFeedsTaskbarViewMode", # Disable taskbar "News and interests" spam
  "type": :dword,
  "data": "2",
  },
]
hostile_microsoft_keys.each do |reg_key|
  registry_key reg_key[:path] do
    values [{ name: reg_key[:name], type: reg_key[:type], data: reg_key[:data] }]
    recursive true
    action :create
  end
end
# Bleh, Workspace ONE requires DiagTrack and dmwappushservice <https://techzone.vmware.com/troubleshooting-windows-devices-workspace-one-operational-tutorial#overview>
# ["DiagTrack", "dmwappushservice"].each do |svc_name|
#   # Disable these services to kill telemetry data to Microsoft
#   windows_service svc_name do
#     startup_type :disabled
#     action %i{disable stop}
#   end
# end

windows_bloatware_apps = [
  "Microsoft.549981C3F5F10", # Cortana
  "Microsoft.GetHelp",
  "Microsoft.Getstarted",
  "Microsoft.HelpAndTips",
  "Microsoft.MixedReality.Portal",
  "Microsoft.WindowsFeedbackHub",
  "Microsoft.XboxApp",
  "Microsoft.XboxGameOverlay",
  "Microsoft.XboxGamingOverlay",
  "Microsoft.XboxIdentityProvider",
  "Microsoft.XboxSpeechToTextOverlay",
  "Microsoft.ZuneMusic", # Groove Music
  "Microsoft.ZuneVideo",
]

windows_bloatware_apps.each do |app|
  powershell_script "Remove #{app}" do
    code "Get-AppxPackage #{app} | Remove-AppxPackage"
    not_if "if ( Get-AppxPackage -Name #{app}){return 0}"
  end
end
