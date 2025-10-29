# Quick Start Guide

## Installation

No installation required - these are standalone scripts.

### Make Bash Script Executable (Linux/macOS)
```bash
chmod +x encrypt_plugin.sh
```

## Basic Usage Examples

### Encrypt a Plugin File

**Bash (Linux/macOS/WSL):**
```bash
./encrypt_plugin.sh encrypt MyPlugin.qplug MyPlugin.qplugx
```

**PowerShell (Windows/Linux):**
```powershell
.\encrypt_plugin.ps1 encrypt MyPlugin.qplug MyPlugin.qplugx
```

### Validate an Encrypted File

**Bash:**
```bash
./encrypt_plugin.sh validate MyPlugin.qplugx
```

**PowerShell:**
```powershell
.\encrypt_plugin.ps1 validate MyPlugin.qplugx
```

### Get Help

**Bash:**
```bash
./encrypt_plugin.sh help
```

**PowerShell:**
```powershell
.\encrypt_plugin.ps1 help
```

## Expected Output

### Successful Encryption
```
[encrypt] Reading input file: MyPlugin.qplug
[encrypt] Preparing data file...
[encrypt] Read 15234 bytes from input file
[encrypt] Encrypting data...
[encrypt] Creating JSON output...
[encrypt] Writing encrypted data to: MyPlugin.qplugx
[encrypt] Encryption completed successfully!
[encrypt] Output size: 20567 characters
[encrypt] Encrypted plugin available for deployment: MyPlugin.qplugx
```

### Successful Validation
```
[validate] Encrypted file structure is valid
[validate] Key size: 256 bytes
[validate] IV size: 16 bytes
[validate] Data size: 15248 bytes
```

## Troubleshooting

### "Command not found" (Bash)
Make sure the script is executable:
```bash
chmod +x encrypt_plugin.sh
```

### "Missing required tools" (Bash)
Install OpenSSL:
```bash
# Ubuntu/Debian
sudo apt install openssl

# macOS with Homebrew
brew install openssl

# Red Hat/CentOS
sudo yum install openssl
```

### PowerShell Execution Policy (Windows)
If you get execution policy errors:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### File Path Issues
Always use forward slashes `/` in bash and backslashes `\` in PowerShell for paths.

## File Size Limits

- Maximum input file size: 100MB
- Typical plugin files: 10KB - 1MB