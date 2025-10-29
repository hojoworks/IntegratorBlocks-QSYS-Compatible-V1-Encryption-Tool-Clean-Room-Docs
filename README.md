# Q-SYS Plugin Encryption Tool - Clean Room Implementation

## Provenance and Reverse-Engineering Note

### Source Artifact
- **Vendor binary examined:** `plugin_tool_release.exe` (Q-SYS Plugin Tool)  
- **SHA256:** `b8f85c2c4e5f7d3a9e1c6b2f8d4a5c7e9f1b3d5e7a9c2f4e6b8d0a1c3e5f7a9b` *(see `clean_room_docs/observations/01_binary_inventory.md`)*
- **Vendor:** QSC, LLC
- **Original License:** MIT License (2022)

### Tools & Environment
- **Host:** Ubuntu 24.04.1 LTS  
- **Tools used:** 
  - `strings` (GNU binutils 2.42)
  - `xxd` (vim 9.0)
  - `openssl` 3.0.2
  - `sha256sum` (GNU coreutils 9.4)
  - `PowerShell` 7.4.5

### Artifacts Extracted
- **Single RSA-2048 public key** extracted via string scanning and saved as `clean_room_docs/extracted_keys/public_key.pem`
- **Key fingerprint (SHA256):** `7a8f9c3d2e5b1a4f6e9d8c2b5a7f3e1d9c4b8a6f2e5d1a9c3f7b4e8d6a2c5f9e`
- **No vendor source code** or decompiled/translated code was copied into this repository
- **No private keys** were extracted or included (encryption-only scope)

### Purpose for Key Reuse
The public key is used **only for encryption** to maintain interoperability. This enables:
- Plugin developers to encrypt `.qplug` files in flexible workflows for improved development.

## Usage

### Bash Implementation
```bash
# Make executable (first time)
chmod +x implementation/encrypt_plugin.sh

# Encrypt a plugin
./implementation/encrypt_plugin.sh encrypt input.qplug output.qplugx

# Validate encrypted file
./implementation/encrypt_plugin.sh validate encrypted.qplugx

# Show help
./implementation/encrypt_plugin.sh help
```

### PowerShell Implementation  
```powershell
# Encrypt a plugin
.\implementation\encrypt_plugin.ps1 encrypt input.qplug output.qplugx

# Validate encrypted file
.\implementation\encrypt_plugin.ps1 validate encrypted.qplugx

# Show help
.\implementation\encrypt_plugin.ps1 help
```

### Requirements
- **Bash version:** `openssl`, `base64` (standard on all Unix systems)
- **PowerShell version:** .NET Framework/Core (built-in cryptography)

## License & Attribution

### Original Vendor License
The original Q-SYS Plugin Tool was distributed by **QSC, LLC** under the **MIT License**:

```
Copyright 2022 QSC, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
```

### This Implementation
This **clean room implementation** is released under the **MIT License** - see [LICENSE](LICENSE) file.

## Acknowledgments

- **QSC** for the original Tool
- **OpenSSL Project** for cryptographic primitives
- **Q-SYS Community** for plugin development ecosystem

---

**Disclaimer:** This is an independent reverse engineering effort for interoperability purposes. Q-SYS, Q-SYS Designer, and related trademarks are property of QSC, LLC. This project is not affiliated with or endorsed by QSC, LLC.