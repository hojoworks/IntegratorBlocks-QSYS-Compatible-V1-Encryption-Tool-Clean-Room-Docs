# Binary Inventory and File Analysis

**Date:** October 28, 2025  

**Observer:** AF

## Binary Package Overview

**Copyright:** 2022 QSC, LLC  
**License:** MIT License  
**Version:** 1.0.0.0 (from executable metadata)  
**Build Date:** September 11, 2025 02:04:16 AM (file timestamps)

## File Inventory

### Main Executable

| File | Size | SHA256 Hash |
|------|------|-------------|
| plugin_tool_release.exe | 51.5 KB (52,736 bytes) | 11F4D11029E0E4C8D47AC7EC2993148B01EB949D742589B6B5C9A3BA6C2BD03B |

**Embedded Version Information:**
- Product Version: 1.0.0.0
- File Version: 1.0.0.0

### OpenSSL Libraries (Current Version)

| File | Size | SHA256 Hash | Purpose |
|------|------|-------------|---------|
| libcrypto-1_1-x64.dll | 3307.5 KB (3,386,880 bytes) | 33A566DAAAFB7DCA849A7E9D2BE1283E2CCDC3A077EE0310E78E0960B5E5F48E | OpenSSL crypto library (v1.1, x64) |
| libssl-1_1-x64.dll | 663.5 KB (679,424 bytes) | 421F3CD75439158BC5901F34E2451138244C115120C288EDCF9AE7254DBA4596 | OpenSSL SSL/TLS library (v1.1, x64) |

### OpenSSL Libraries (Legacy/Debug Version)

| File | Size | SHA256 Hash | Purpose |
|------|------|-------------|---------|
| libcryptoMD.dll | 2337.5 KB (2,393,600 bytes) | A1C6125AF7F4D48C1E635B1B7CF55FAD3D142CCDE7E71C820911FCD1CEEE1B29 | OpenSSL crypto (MD/Debug build) |
| libeay32MD.dll | 2082 KB (2,131,968 bytes) | B9912AC316C268EC9B79DE03BCBC28DEBD0192558071EFA4F56145F0B33BA25D | OpenSSL legacy crypto (MD/Debug build) |
| libsslMD.dll | 479 KB (490,496 bytes) | 3D404648C0D10995F2541A29D465A01944F6C7CBAAE6BC6B9ECAEC531938CAC5 | OpenSSL SSL (MD/Debug build) |

### Microsoft Visual C++ Runtime

| File | Size | SHA256 Hash | Purpose |
|------|------|-------------|---------|
| msvcp140.dll | 569.38 KB (583,048 bytes) | 254F5CDE2DEF2BF3941F746E4902A36F5169BF73AE9E258E49BC1FEF7B26EC99 | MSVC++ 2015 Runtime (C++ Standard Library) |
| vcruntime140.dll | 91.88 KB (94,088 bytes) | F10EF6DE6C651DB42DBD455A1C674047862CEBF6CCCE1F784CDB0571C9EA9757 | MSVC++ 2015 Runtime (Core) |
| vcruntime140_1.dll | 35.88 KB (36,744 bytes) | A571D26E536D4F7DA93ACC24EDB1D823140B660795576DC27F626F1889106D36 | MSVC++ 2015 Runtime (Additional) |

### Supporting Libraries

| File | Size | SHA256 Hash | Purpose |
|------|------|-------------|---------|
| version.dll | 30.76 KB (31,496 bytes) | E549D528FEE40208DF2DD911C2D96B29D02DF7BEF9B30C93285F4A2F3E1AD5B0 | Windows Version API wrapper |

## Key Observations

### 1. Cryptographic Dependencies

**Primary Observation:** The tool uses OpenSSL libraries for cryptographic operations.

**Evidence:**
- Includes OpenSSL 1.1 x64 libraries (libcrypto-1_1-x64.dll, libssl-1_1-x64.dll)
- Also includes debug/MD builds (libcryptoMD.dll, libeay32MD.dll, libsslMD.dll)
- `libeay32` is the legacy OpenSSL crypto library name (pre-1.1.0)

**Implications:**
- Tool likely uses standard OpenSSL encryption algorithms (AES, RSA, etc.)
- Having both release and debug builds suggests development/testing artifacts
- MD suffix typically indicates "Multi-threaded Debug" runtime linkage

### 2. Development Environment

**Build Environment Indicators:**
- MSVC++ 2015 Runtime (version 140) - compiled with Visual Studio 2015 or compatible
- x64 architecture (64-bit Windows application)
- Debug libraries included alongside release libraries (unusual for production)

### 3. File Size Analysis

**Main Executable:** 51.5 KB - Relatively small, suggests:
- Minimal UI (command-line only)
- Core logic is compact
- Heavy lifting delegated to OpenSSL libraries

**Total Package Size:** ~9.5 MB (mostly OpenSSL libraries)

### 4. Binary Characteristics

**Timestamp Consistency:** All files have identical timestamps (Sep 11, 2025 02:04:16 AM)
- Indicates automated build/packaging process
- All files deployed together as a unit

### 5. Platform Requirements

**Windows-Specific:**
- .exe extension (Windows executable)
- Windows DLL dependencies (MSVC runtime, version.dll)
- x64 architecture only (no x86/ARM builds observed)

**Runtime Requirements:**
- Windows 7 or later (based on MSVC 2015 runtime)
- x64 processor architecture
- No .NET Framework required (native C/C++ application)

## Documented Commands (from README.md)

### Command: `version`
- Returns tool version (likely displays "1.0.0.0")

### Command: `usage`
- Returns command help
- Default behavior for invalid/blank commands

### Command: `encrypt`
- Syntax: `plugin_tool_release.exe encrypt <input.qplug> <output.qplugx>`
- Input: .qplug files
- Output: .qplugx files
- Supports relative and absolute paths

## Security Observations

### 1. OpenSSL Version
- OpenSSL 1.1.x series is in LTS (Long Term Support) as of 2025
- Generally considered secure if using recent 1.1.1 patches
- To verify exact version, would need to run `openssl version` via DLL or analyze binary

### 2. Debug Libraries Present
- Presence of debug builds (MD variants) in production package is unusual
- May indicate:
  - Development/testing version
  - Both versions needed for compatibility
  - Packaging oversight

### 3. Hash Verification
All file hashes documented for:
- Integrity verification
- Detecting tampering
- Future version comparison

## Analysis Constraints (Clean Room Compliance)

**What We Observed:**
- File sizes and timestamps
- External dependencies (DLLs)
- Embedded version metadata
- Cryptographic hash values
- File system permissions
- Documentation (README.md, license.txt)

**What We Did NOT Do:**
- Decompile the executable
- Disassemble machine code
- Debug or trace execution
- Extract internal resources
- Analyze binary structure beyond metadata

## File Manifest (SHA256 Checksums)

For integrity verification, all files can be validated against these SHA256 hashes:

```
11F4D11029E0E4C8D47AC7EC2993148B01EB949D742589B6B5C9A3BA6C2BD03B  plugin_tool_release.exe
33A566DAAAFB7DCA849A7E9D2BE1283E2CCDC3A077EE0310E78E0960B5E5F48E  libcrypto-1_1-x64.dll
A1C6125AF7F4D48C1E635B1B7CF55FAD3D142CCDE7E71C820911FCD1CEEE1B29  libcryptoMD.dll
B9912AC316C268EC9B79DE03BCBC28DEBD0192558071EFA4F56145F0B33BA25D  libeay32MD.dll
421F3CD75439158BC5901F34E2451138244C115120C288EDCF9AE7254DBA4596  libssl-1_1-x64.dll
3D404648C0D10995F2541A29D465A01944F6C7CBAAE6BC6B9ECAEC531938CAC5  libsslMD.dll
254F5CDE2DEF2BF3941F746E4902A36F5169BF73AE9E258E49BC1FEF7B26EC99  msvcp140.dll
F10EF6DE6C651DB42DBD455A1C674047862CEBF6CCCE1F784CDB0571C9EA9757  vcruntime140.dll
A571D26E536D4F7DA93ACC24EDB1D823140B660795576DC27F626F1889106D36  vcruntime140_1.dll
E549D528FEE40208DF2DD911C2D96B29D02DF7BEF9B30C93285F4A2F3E1AD5B0  version.dll
```

## References

- OpenSSL Documentation: https://www.openssl.org/docs/man1.1.1/
- Microsoft Visual C++ Redistributable: https://docs.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist
- Original Repository: https://github.com/qsys-plugins/PluginEncryptionTool
