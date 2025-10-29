# Public Key Extraction Strategy

**Date:** October 28, 2025

**Observer:** AF

**Method:** Non-invasive string scanning and resource extraction

## Objective

Extract the RSA-2048 public key embedded in `plugin_tool_release.exe` to enable compatible encryption in our clean room implementation.

## Rationale

1. **Encryption-Only Scope:** We only need the public key for encryption
2. **No Private Key Access:** Private key remains with QSC for decryption
3. **Non-Sensitive Data:** Public keys are meant to be shared
4. **Clean Room Compliant:** String scanning is non-invasive observation

## Public Key Characteristics

### Expected Format

**RSA-2048 Public Key:**
- Modulus: 2048 bits (256 bytes)
- Public Exponent: Usually 65537 (0x010001)
- Total Size: ~294 bytes (DER) or ~451 bytes (PEM)

**Common Encoding Formats:**

1. **PEM Format (ASCII):**
```text
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
(base64 encoded data, typically 6-8 lines)
...
-----END PUBLIC KEY-----
```

2. **PEM RSA Format (ASCII):**
```text
-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEA...
-----END RSA PUBLIC KEY-----
```

3. **DER Format (Binary):**
- ASN.1 structure
- Starts with: `30 82 01 22` (SEQUENCE, length 290)
- Followed by algorithm identifier
- Then RSA public key structure

## Extraction Methods

### Method 1: String Scanning (Recommended)

**Tool:** `strings.exe` (Sysinternals) or PowerShell

**Commands:**
```powershell
# Search for PEM markers
strings plugin_tool_release.exe | Select-String "BEGIN PUBLIC KEY"
strings plugin_tool_release.exe | Select-String "BEGIN RSA PUBLIC KEY"

# Extract context around markers
$content = [System.IO.File]::ReadAllText("plugin_tool_release.exe")
$content -match '-----BEGIN.*PUBLIC KEY-----'

```

## Validation Steps

Once key is extracted:

1. **Format Verification:**
```bash
# If PEM format
openssl rsa -pubin -in extracted_key.pem -text -noout

# If DER format
openssl rsa -pubin -inform DER -in extracted_key.der -text -noout
```

2. **Size Verification:**
- Should show 2048-bit modulus
- Public exponent should be 65537 (or small value)

3. **Functional Test:**
```bash
# Test encryption with extracted key
echo "test data" > test.txt
openssl rsautl -encrypt -pubin -inkey extracted_key.pem -in test.txt -out test.enc

# Verify output is 256 bytes (RSA-2048 output size)
ls -l test.enc
```

4. **Cross-Validation:**
- Encrypt test file with original tool
- Extract the encrypted key field from .qplugx
- Verify it's 256 bytes
- Confirms RSA-2048 usage

## Expected Outcome

**Successful Extraction Will Provide:**
1. RSA-2048 public key in PEM or DER format
2. Verified 2048-bit modulus
3. Compatible with OpenSSL library
4. Ready for use in our implementation

**File to Create:**
```
clean_room_docs/extracted_keys/public_key.pem
```

## Implementation Plan

### Phase 1: String Scan (Easiest)
1. Run strings utility
2. Search for PEM markers
3. Extract complete key block
4. Validate with OpenSSL

## Clean Room Compliance

All methods are clean room compliant:
- String scanning: Reading embedded strings (non-invasive)
- Binary search: Pattern matching (no disassembly)

**No Code Reverse Engineering Required:**
- Not examining program logic
- Not analyzing algorithms
- Only extracting data
- Behavioral observation only

## Security Considerations

**Public Key is Non-Sensitive:**
- Designed to be shared
- Cannot be used for decryption
- Only enables encryption
- No security risk in extraction

**Private Key Remains Secure:**
- Never exposed by tool
- Held by QSC only
- Not needed for our implementation
- Cannot be derived from public key

**Our Use Case:**
- Create compatible .qplugx files
- Q-SYS Designer decrypts using QSC's private key
- No attempt to decrypt or access private key
- Encryption compatibility only

## Next Steps

1. Start with Method 1 (string scanning) - simplest approach
2. Document findings in this file
3. Save extracted key to `extracted_keys/` folder
4. Validate key with OpenSSL
5. Update STATUS.md with results
6. Proceed to implementation phase
