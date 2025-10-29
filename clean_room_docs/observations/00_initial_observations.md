# Initial Observations - Plugin Encryption Tool

**Date:** October 27, 2025  
**Observer:** Single Developer  
**Tool Version:** Unknown (to be determined)

## Source Information

**Repository:** https://github.com/qsys-plugins/PluginEncryptionTool  
**Binary Location:** release/plugin_tool_release.exe  
**License:** MIT License

## Published Documentation

From the GitHub README, the following commands are documented:

### Command: `usage`
- **Purpose:** Returns currently supported commands and syntax
- **Note:** Invalid commands or blank command also return usage information

### Command: `version`
- **Purpose:** Returns current version for the tool

### Command: `encrypt`
- **Purpose:** Encrypts input file and outputs to specified output file
- **Syntax:** `./plugin_tool_release.exe encrypt <input.qplug> <output.qplugx>`
- **Input Format:** `.qplug` files (Q-SYS plugin files)
- **Output Format:** `.qplugx` files (encrypted Q-SYS plugin files)
- **Path Handling:** Supports both relative and absolute paths

### Examples from Documentation:
```powershell
# Same directory encryption
./plugin_tool_release.exe encrypt MyPlugin.qplug MyEncryptedPlugin.qplugx

# Full path encryption
./plugin_tool_release.exe encrypt C:\path_to_your_plugin\ATestPlugin.qplug C:\path_to_your_plugin\ATestPlugin.qplugx
```

## Platform Information

- **Primary Platform:** Windows
- **Shell:** PowerShell
- **Execution:** Standalone executable

## Initial Questions to Investigate

1. What is the exact version of the tool?
2. What file format is `.qplug`? (It's just LUA)
3. What encryption algorithm is used?
4. Is there any file signature or header in `.qplugx` files?
5. Are there any error messages for invalid inputs?
6. What happens with non-.qplug input files?
7. Is the encryption deterministic or does it use random IVs?
8. Are there any size limitations?
9. Is there any compression applied?
10. Are there any digital signatures or authentication?

