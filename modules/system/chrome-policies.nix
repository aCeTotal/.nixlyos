{ ... }:

{
  # Enterprise policies for Chrome/Chromium to suppress restore and first-run prompts
  environment.etc = {
    # Google Chrome policies
    "opt/chrome/policies/managed/fast-fresh.json".text = ''
      {
        "RestoreOnStartup": 0,
        "HideFirstRunExperience": true,
        "DefaultBrowserSettingEnabled": false,
        "SuppressFirstRunDefaultBrowserPrompt": true,
        "BackgroundModeEnabled": false,
        "BrowserCrashDumpEnabled": false,
        "MetricsReportingEnabled": false,
        "AutoOpenFileTypes": ["application"],
        "AutoOpenAllowedForURLs": ["*"]
      }
    '';

    # Chromium policies (in case Chromium is used instead)
    "chromium/policies/managed/fast-fresh.json".text = ''
      {
        "RestoreOnStartup": 0,
        "HideFirstRunExperience": true,
        "DefaultBrowserSettingEnabled": false,
        "SuppressFirstRunDefaultBrowserPrompt": true,
        "BackgroundModeEnabled": false,
        "BrowserCrashDumpEnabled": false,
        "MetricsReportingEnabled": false,
        "AutoOpenFileTypes": ["application"],
        "AutoOpenAllowedForURLs": ["*"]
      }
    '';

    # Brave Browser policies
    "brave/policies/managed/fast-fresh.json".text = ''
      {
        "RestoreOnStartup": 0,
        "HideFirstRunExperience": true,
        "DefaultBrowserSettingEnabled": false,
        "SuppressFirstRunDefaultBrowserPrompt": true,
        "BackgroundModeEnabled": false,
        "BrowserCrashDumpEnabled": false,
        "MetricsReportingEnabled": false,
        "AutoOpenFileTypes": ["application"],
        "AutoOpenAllowedForURLs": ["*"]
      }
    '';
  };
}

