# Windows Hello PIN Fix

Intune deployment scripts for fixing the Windows Hello PIN bug that Microsoft introduced in the 2025-06 Cumulative Update for Windows 11 24H2.

## Background

Microsoft introduced a bug in the 2025-06 Cumulative Update for Windows 11 24H2 that affects Windows Hello PIN functionality. This repository provides PowerShell scripts that can be deployed through Microsoft Intune to fix the issue by setting the appropriate Windows Hello for Business policy values in the Windows registry.

## Repository Contents

This repository contains three PowerShell scripts designed for Intune deployment:

### Scripts Overview

| Script | Purpose | Exit Codes |
|--------|---------|------------|
| `install.ps1` | Configures Windows Hello for Business policy values | 0 = Success, 1 = Failure |
| `uninstall.ps1` | Removes Windows Hello for Business policy values | 0 = Success, 1 = Failure |
| `check.ps1` | Validates compliance of policy values | 0 = Compliant, 1 = Non-compliant |

### install.ps1

**Purpose**: Ensures Windows Hello for Business (PassportForWork) policy values are correctly set.

**What it does**:
- Creates the registry key `HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork` if it doesn't exist
- Sets `UsePassportForWork` DWORD value to `1`
- Sets `Enabled` DWORD value to `1`
- Automatically handles 32-bit/64-bit PowerShell context switching
- Provides detailed logging of all operations
- Only makes changes when necessary (idempotent)

**Registry Path**: `HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork`

### uninstall.ps1

**Purpose**: Intelligently removes the Windows Hello for Business policy values.

**What it does**:
- Removes `UsePassportForWork` and `Enabled` registry values
- Uses smart cleanup logic:
  - If only default value and target values exist (no other data), removes the entire registry key
  - If other values or subkeys exist, only removes the target values to preserve existing configuration
- Automatically handles 32-bit/64-bit PowerShell context switching
- Uses both PowerShell and .NET registry APIs for reliable operation

### check.ps1

**Purpose**: Validates that the Windows Hello for Business policy is correctly configured.

**What it does**:
- Checks for the existence of the registry key `HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork`
- Validates that `UsePassportForWork` is set to `1`
- Validates that `Enabled` is set to `1`
- Reports compliance status with detailed information
- Used by Intune as a detection rule to determine if the fix is already applied

## How the Fix Works

The Windows Hello PIN bug is resolved by setting specific Group Policy values in the Windows registry:

1. **Registry Location**: `HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork`
2. **Required Values**:
   - `UsePassportForWork` (DWORD) = `1` - Enables Windows Hello for Business
   - `Enabled` (DWORD) = `1` - Ensures the feature is active

These registry modifications effectively enable Windows Hello for Business through Group Policy, which resolves the PIN functionality issues introduced in the problematic Windows update.

## Intune Application Setup

Follow these steps to create an Intune application for deploying this fix:

### 1. Create New Application

1. In Microsoft Intune admin center, go to **Apps** > **All apps**
2. Click **Add** > **Windows app (Win32)**
3. Compile your own .intunewin file containing the install.ps1 and uninstall.ps1 or use the one [provided under releases (extract the .ZIP file)](https://github.com/tommyvange/WindowsHelloPINFix/releases/latest).

### 2. Program Configuration

Configure the application with these settings:

**Install command**:
```
powershell.exe -ex Bypass -f ./install.ps1
```

**Uninstall command**:
```
powershell.exe -ex Bypass -f ./uninstall.ps1
```

**Installation time required (mins)**: `60`

**Allow available uninstall**: `Yes`

**Install behavior**: `System`

### 3. Requirements

Set the following requirements:

- **Check operating system architecture**: `No Check operating system architecture`
- **Minimum operating system**: `Windows 11 23H2`
- **Disk space required (MB)**: `No Disk space required (MB)`
- **Physical memory required (MB)**: `No Physical memory required (MB)`
- **Minimum number of logical processors required**: `No Minimum number of logical processors required`
- **Minimum CPU speed required (MHz)**: `No Minimum CPU speed required (MHz)`
- **Additional requirement rules**: `No Additional requirement rules`

### 4. Detection Rules

Configure detection using the custom script:

1. Select **Use custom script**
2. Upload the `check.ps1` script from this repository
3. Set **Run script as 32-bit process on 64-bit clients**: `No`
4. Set **Enforce script signature check**: Based on your organization's policy

The detection script will return:
- **Exit code 0**: Application is installed and compliant
- **Exit code 1**: Application needs to be installed or is non-compliant

### 5. Assignment

Assign the application to the appropriate device groups that need the Windows Hello PIN fix.

## Requirements

- **Operating System**: Windows 11 23H2 or later
- **Permissions**: The scripts must run with administrative privileges (System context in Intune)
- **PowerShell**: Scripts are compatible with both PowerShell 5.1 and PowerShell 7
- **Architecture**: Scripts automatically handle both 32-bit and 64-bit PowerShell contexts

## Usage

### Intune Deployment (Recommended)

Deploy through Microsoft Intune using the configuration detailed above. This is the recommended method for enterprise environments.

### Manual Execution

For testing or manual deployment:

1. **Run as Administrator**: Open PowerShell as Administrator
2. **Install the fix**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\install.ps1
   ```
3. **Check compliance**:
   ```powershell
   .\check.ps1
   ```
4. **Uninstall if needed**:
   ```powershell
   .\uninstall.ps1
   ```

## Script Features

- **Automatic Architecture Detection**: All scripts automatically detect and handle 32-bit/64-bit PowerShell contexts
- **Comprehensive Error Handling**: Robust error handling with meaningful exit codes
- **Detailed Logging**: Verbose output for troubleshooting and auditing
- **Idempotent Operations**: Scripts can be run multiple times safely
- **Smart Cleanup**: Uninstall script preserves existing registry configurations when possible

## Troubleshooting

### Common Issues

1. **Script execution errors**: Ensure PowerShell execution policy allows script execution
2. **Permission denied**: Scripts must run with administrative privileges
3. **Registry access errors**: Verify the account has permission to modify `HKLM:\SOFTWARE\Policies`

### Validation

After deployment, verify the fix by:

1. Running `check.ps1` manually or checking Intune compliance reports
2. Verifying registry values using `regedit.exe`:
   - Navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork`
   - Confirm `UsePassportForWork` and `Enabled` are both set to `1`

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve these scripts.

## Support

For issues related to:
- **Script functionality**: Open an issue in this repository
- **Intune deployment**: Consult Microsoft Intune documentation
- **Windows Hello issues**: Contact Microsoft Support for the underlying Windows update problems

---

**Note**: This fix addresses symptoms of the Windows Hello PIN bug introduced in Microsoft's 2025-06 Cumulative Update. Monitor Microsoft's official channels for permanent fixes to the underlying issue.
