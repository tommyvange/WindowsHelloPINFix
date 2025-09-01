<#  Install.ps1
    Purpose: Ensure Windows Hello for Business (PassportForWork) policy values are set.
    Exit codes: 0 success, 1 failure
#>

# Relaunch in 64-bit PowerShell if invoked in 32-bit context (to target HKLM\SOFTWARE correctly)
if ($env:PROCESSOR_ARCHITECTURE -eq 'x86' -and (Test-Path "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}

$ErrorActionPreference = 'Stop'

$RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork'
$Values  = @{
    UsePassportForWork = 1
    Enabled            = 1
}

try {
    Write-Host "=== Install: Configuring PassportForWork policy ==="
    $changed = $false

    if (-not (Test-Path $RegPath)) {
        Write-Host "Creating registry key: $RegPath"
        New-Item -Path $RegPath -Force | Out-Null
        $changed = $true
    } else {
        Write-Host "Registry key exists: $RegPath"
    }

    foreach ($name in $Values.Keys) {
        $desired = [int]$Values[$name]
        $exists = $false
        try {
            $current = Get-ItemProperty -Path $RegPath -Name $name -ErrorAction Stop | Select-Object -ExpandProperty $name
            $exists = $true
        } catch {
            $exists = $false
        }

        if (-not $exists) {
            Write-Host "Creating DWORD value '$name' = $desired"
            New-ItemProperty -Path $RegPath -Name $name -Value $desired -PropertyType DWord -Force | Out-Null
            $changed = $true
        } elseif ([int]$current -ne $desired) {
            Write-Host "Updating '$name' from $current to $desired"
            Set-ItemProperty -Path $RegPath -Name $name -Value $desired
            $changed = $true
        } else {
            Write-Host "'$name' already set to $desired"
        }
    }

    if ($changed) {
        Write-Host "Install complete. Policy values set."
    } else {
        Write-Host "No changes needed. Policy values already compliant."
    }

    exit 0
}
catch {
    Write-Host "ERROR during install: $($_.Exception.Message)"
    exit 1
}
