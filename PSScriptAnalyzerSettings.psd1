# PSScriptAnalyzer settings, enforced by CI (ci.yml) for the app, src/lib, tools and build.ps1.
@{
    Severity     = @('Error', 'Warning', 'Information')
    ExcludeRules = @(
        # The Set-/Start-/Update-* functions are internal UI helpers that only change the app's own
        # window state; -WhatIf/-Confirm would be meaningless there.
        'PSUseShouldProcessForStateChangingFunctions',
        # Write-Host is deliberate: console fallbacks before/without a window, and the DNS benchmark
        # and PSWindowsUpdate scripts run in a child powershell.exe whose host output is streamed.
        'PSAvoidUsingWriteHost'
    )
}
