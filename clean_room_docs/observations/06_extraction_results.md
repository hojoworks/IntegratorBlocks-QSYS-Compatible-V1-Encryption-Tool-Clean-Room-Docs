# Public Key Extraction - Results

**Date:** October 28, 2025

**Observer:** AF

**Method Used:** String Scanning

## Extraction Summary

Successfully extracted RSA-2048 public key from `plugin_tool_release.exe` using simple string scanning method. The key was embedded in PEM format within the executable and was easily discoverable.

## Method Used

**String Scanning with PowerShell Regular Expression:**
```powershell
$content = Get-Content "plugin_tool_release.exe" -Raw
$match = [regex]::Match($content, 
    '-----BEGIN PUBLIC KEY-----(.*?)-----END PUBLIC KEY-----',
    [System.Text.RegularExpressions.RegexOptions]::Singleline)
```

- Key was stored in plain text PEM format
- No obfuscation or encoding applied
- Standard OpenSSL PEM markers present
- First method attempted was successful

## Extracted Key

**Location:** `clean_room_docs/extracted_keys/public_key.pem`

**Content:**
```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyfxU4QZbgbAHZv9atTIq
TPGsvaFezv3w2GxgtyronJQ0hhk+wKyIHKX1412+pxLGRkSinFmyxqEL7ob3iyqx
AvO4Spn74B6jcYxiqERX1igwOFduZNu1BcA9LLKU1P+QiZW2oovn1vyrdxrgJsTO
A5aukWZYIHOyO8H7Nuqp2t/UUQwn4FL9L+MLgn0zhAty7obJRN8YCkVA+AENM9+n
jGySiR+6PgPUmzMzbQyF58+yhsXytIidl8+Rkgmw7e2T6ZO0z0xrdoJltmS1T+bK
BMvsvrSxod6SY4QYeU0Cy+7CA5R8foggJVBcGPwHqelMYhjc32bZOsp1ZnrDlbmm
eQIDAQAB
-----END PUBLIC KEY-----
```

## Validation Results

### Binary Analysis

- **Format:** PEM (ASCII-armored DER)
- **Binary Size:** 294 bytes (exact match for RSA-2048)
- **ASN.1 Structure:** Valid
- **First 10 bytes (hex):** `30 82 01 22 30 0D 06 09 2A 86`

### Structure Verification

**ASN.1 Breakdown:**
- `30 82 01 22` - SEQUENCE tag, length 290 bytes
- `30 0D` - SEQUENCE (Algorithm Identifier)
- `06 09` - OBJECT IDENTIFIER, length 9
- `2A 86 48 86 F7 0D 01 01 01` - RSA encryption OID (1.2.840.113549.1.1.1)

**Confirmation:** Valid RSA public key in standard PKCS#1 format

### Key Properties

- **Algorithm:** RSA
- **Key Size:** 2048 bits (256 bytes modulus)
- **Public Exponent:** 65537 (0x010001) - standard value
- **Format:** X.509 SubjectPublicKeyInfo
- **Encoding:** Base64 (PEM)

## Security Analysis

### Key Characteristics

1. **Standard RSA-2048:** Industry-standard key size, considered secure
2. **Standard Exponent:** Uses common public exponent (65537)
3. **No Weaknesses Detected:** Key appears properly generated
4. **Proper Format:** Follows PKCS#1/X.509 standards

### Usage Implications

**What We Can Do:**
- Encrypt data that only QSC can decrypt
- Create compatible .qplugx files
- Use standard OpenSSL functions for encryption
- No special handling required

**What We Cannot Do:**
- Decrypt existing .qplugx files (need private key)
- Generate new key pairs (we use the existing public key)
- Modify the encryption scheme (must match original)

## Clean Room Compliance

**Method Classification:** String Scanning
- **Invasiveness:** None (read-only file access)
- **Analysis Type:** Behavioral observation

**Justification:**
- Public keys are designed to be shared
- No proprietary algorithms examined
- No code disassembly performed
- Standard data extraction only