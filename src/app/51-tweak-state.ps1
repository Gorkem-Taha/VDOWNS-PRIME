# Tweak state library: loaded into the apply/revert runspaces. Before a tweak runs for the
# first time, every value it touches is snapshotted to HKCU:\Software\VDOWNS\TweakState so
# "Revert" can put back exactly what was there (including "value did not exist").
$script:TweakStateLib = @'
#@include lib/TweakState.ps1
'@

