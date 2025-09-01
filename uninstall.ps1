<#  Uninstall.ps1 (revised)
    Purpose: Remove PassportForWork policy values. If only the default value is present
             besides our two values (and no subkeys), delete the entire key.
    Exit codes: 0 success, 1 failure
#>

# Relaunch in 64-bit PowerShell if invoked in 32-bit context
if ($env:PROCESSOR_ARCHITECTURE -eq 'x86' -and (Test-Path "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}

$ErrorActionPreference = 'Stop'

$RegPathPS = 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork'
$RegPathRaw = 'SOFTWARE\Policies\Microsoft\PassportForWork'
$Targets    = @('UsePassportForWork','Enabled')

try {
    Write-Host "=== Uninstall: Removing PassportForWork policy ==="

    if (-not (Test-Path $RegPathPS)) {
        Write-Host "Registry key not present; nothing to remove."
        exit 0
    }

    # Use .NET registry to reliably detect the default value (empty string name) and subkeys
    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $rk   = $base.OpenSubKey($RegPathRaw, $true)

    if (-not $rk) {
        Write-Host "Registry key not accessible; treating as absent."
        exit 0
    }

    $valueNames = @($rk.GetValueNames())     # default value is returned as "" (empty string)
    $subKeys    = @($rk.GetSubKeyNames())

    $targetPresent = ($valueNames | Where-Object { $_ -in $Targets }).Count -gt 0
    $otherValues   = $valueNames | Where-Object { $_ -ne '' -and $_ -notin $Targets }  # exclude default and our targets
    $hasOtherVals  = ($otherValues.Count -gt 0)
    $hasSubKeys    = ($subKeys.Count -gt 0)

    if ($targetPresent -and -not $hasOtherVals -and -not $hasSubKeys) {
        Write-Host "Only default value plus target values found. Removing entire key: HKLM:\$RegPathRaw"
        # Close handle before using PS provider to delete
        $rk.Close()
        Remove-Item -Path $RegPathPS -Recurse -Force -ErrorAction Stop
        Write-Host "Key removed."
        exit 0
    }

    # Otherwise, remove only the target values
    foreach ($name in $Targets) {
        if ($valueNames -contains $name) {
            Write-Host "Deleting value '$name'"
            try {
                $rk.DeleteValue($name, $true)
            } catch {
                # Fallback to PS provider if needed
                Remove-ItemProperty -Path $RegPathPS -Name $name -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "Value '$name' not present; nothing to remove."
        }
    }

    # Close registry key
    $rk.Close()

    Write-Host "Uninstall complete."
    if (-not $hasOtherVals -and -not $hasSubKeys) {
        Write-Host "Note: Key now contains only the default value. Retained by design."
    } else {
        Write-Host "Note: Key retained because it contains other data (values or subkeys not managed by this script)."
    }

    exit 0
}
catch {
    Write-Host "ERROR during uninstall: $($_.Exception.Message)"
    exit 1
}
