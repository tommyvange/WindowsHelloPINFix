<#  Check.ps1
    Purpose: Report compliance for PassportForWork policy values.
    Exit codes: 0 compliant, 1 non-compliant / error
#>

# Relaunch in 64-bit PowerShell if invoked in 32-bit context
if ($env:PROCESSOR_ARCHITECTURE -eq 'x86' -and (Test-Path "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}

$ErrorActionPreference = 'Stop'

$RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork'
$Expected = @{
    UsePassportForWork = 1
    Enabled            = 1
}

try {
    Write-Host "=== Check: Validating PassportForWork policy ==="

    if (-not (Test-Path $RegPath)) {
        Write-Host "Non-compliant: Key missing -> $RegPath"
        exit 1
    }

    $nonCompliant = @()
    foreach ($name in $Expected.Keys) {
        $desired = [int]$Expected[$name]
        try {
            $current = Get-ItemProperty -Path $RegPath -Name $name -ErrorAction Stop | Select-Object -ExpandProperty $name
            if ([int]$current -ne $desired) {
                $nonCompliant += "'$name' is $current (expected $desired)"
            } else {
                Write-Host "Compliant: '$name' = $desired"
            }
        } catch {
            $nonCompliant += "'$name' is missing (expected $desired)"
        }
    }

    if ($nonCompliant.Count -gt 0) {
        Write-Host "Non-compliant:"
        $nonCompliant | ForEach-Object { Write-Host " - $_" }
        exit 1
    } else {
        Write-Host "All values compliant."
        exit 0
    }
}
catch {
    Write-Host "ERROR during check: $($_.Exception.Message)"
    exit 1
}
