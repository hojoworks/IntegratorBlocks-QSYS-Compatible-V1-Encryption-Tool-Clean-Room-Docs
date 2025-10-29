# File Format Analysis (.qplugx)

**Date:** October 28, 2025
**Observer:** AF  
**Analysis Type:** Black-box behavioral observation
**Input File:** ExamplePlugin.qplug (28,368 bytes)
**Output File:** ExamplePlugin.qplugx (37,368 bytes)

## Overview

The .qplugx format is a JSON-based encrypted container that wraps encrypted Q-SYS plugin files. The format is NOT a binary blob but rather a structured text document containing base64-encoded cryptographic components.

## JSON Schema

```json
{
  "key": "<base64_encoded_encrypted_key>",
  "iv": "<base64_encoded_initialization_vector>",
  "data": "<base64_encoded_ciphertext>"
}
```

## Component Specifications

### 1. Key Field

- **Purpose:** Encrypted symmetric key (likely RSA-encrypted AES key)
- **Base64 Length:** 344 characters
- **Binary Size:** 256 bytes (2048 bits)
- **Encoding:** Base64
- **Analysis:** 256-byte binary size strongly suggests RSA-2048 encrypted data
  - RSA-2048 outputs exactly 256 bytes
  - This field likely contains an AES-256 key (32 bytes) encrypted with RSA-2048
  - Remaining space used for OAEP padding (standard RSA padding scheme)

### 2. IV Field

- **Purpose:** Initialization Vector for AES encryption
- **Base64 Length:** 24 characters
- **Binary Size:** 16 bytes (128 bits)
- **Encoding:** Base64
- **Analysis:** 16-byte IV is standard for AES block cipher
  - Matches AES block size perfectly
  - IV appears to be randomly generated per encryption
  - Confirms non-deterministic encryption behavior

### 3. Data Field

- **Purpose:** Encrypted plugin content
- **Base64 Length:** 36,972 characters (varies with input)
- **Binary Size:** 27,728 bytes (varies with input)
- **Encoding:** Base64
- **Analysis:** Original file was 28,368 bytes
  - Encrypted size: 27,728 bytes
  - Size reduction: 640 bytes smaller
  - This suggests compression before encryption
  - OR the original file had padding that was removed

## Overhead Analysis

**Total File Sizes:**
- Input: 28,368 bytes
- Output: 37,368 bytes
- Overhead: 9,000 bytes

**JSON Structure Overhead Breakdown:**

| Component | Base64 Chars | Binary Bytes | Purpose |
|-----------|--------------|--------------|---------|
| Key | 344 | 256 | RSA-encrypted AES key |
| IV | 24 | 16 | AES initialization vector |
| Data | 36,972 | 27,728 | Encrypted content |
| JSON syntax | ~50 | ~50 | Brackets, quotes, colons |
| **TOTAL** | **37,390** | **28,050** | Approximate |

**Detailed Overhead:**
- RSA key component: 256 bytes
- IV component: 16 bytes
- JSON formatting: ~50 bytes
- Base64 encoding overhead: ~33% increase
- **Total overhead: ~9,000 bytes**

## Encryption Scheme Analysis

### Likely Algorithm: Hybrid RSA/AES Encryption

Based on observed characteristics:

1. **Key Encryption Layer (RSA-2048)**
   - Public/private key cryptography
   - 256-byte output indicates RSA-2048
   - Encrypts the AES symmetric key
   - Public key embedded in executable
   - Private key held by QSC (not needed for our encryption tool)

2. **Data Encryption Layer (AES-256)**
   - Symmetric encryption for bulk data
   - 16-byte IV indicates AES block cipher
   - Likely AES-256-CBC or AES-256-GCM mode
   - Much faster than RSA for large files

### Encryption Process (Our Implementation Target)

```text
1. Load embedded RSA-2048 public key from extracted .pem file
2. Generate random AES-256 key (32 bytes) using OpenSSL RAND_bytes()
3. Generate random IV (16 bytes) using OpenSSL RAND_bytes()
4. [Optional] Compress input data with zlib/gzip
5. Encrypt data with AES-256 (CBC or GCM) using key + IV
6. Encrypt AES key with RSA-2048 public key (OAEP padding)
7. Base64 encode all three components
8. Construct JSON: {"key":"...","iv":"...","data":"..."}
9. Save as .qplugx file
```

**Implementation Notes:**
- We only need the public key (no private key handling)
- All cryptographic operations via OpenSSL library
- Random number generation must be cryptographically secure
- Output must match original tool's format exactly

**Why We Don't Implement Decryption:**
- Requires private key (not available to us)
- Private key is proprietary to QSC
- Our goal is encryption compatibility only
- Q-SYS Designer handles decryption

## Security Observations

1. **Non-Deterministic:** Random IV ensures different ciphertext each time
2. **Hybrid Approach:** Combines RSA (secure key exchange) with AES (fast encryption)
3. **Standard Algorithms:** Uses well-established OpenSSL implementations
4. **Proper Key Size:** RSA-2048 and AES-256 are currently considered secure

### Characteristics

1. **No Authentication:** File does not appear to include HMAC or signature
   - Cannot verify file integrity
   - Cannot detect tampering
   - GCM mode would add authentication (not confirmed)

2. **IV Storage:** IV stored in plaintext (standard practice, not a weakness)

3. **Key Management:** RSA key pair location/storage unknown
   - Could be embedded in executable
   - Could be file-based
   - Could use Windows certificate store

## Compression Analysis

**Observation:** Encrypted data (27,728 bytes) is smaller than input (28,368 bytes)

**Possible Explanations:**
1. **Pre-encryption compression** (most likely)
   - Input compressed with zlib/gzip before encryption
   - Standard practice for plugin files
   - Would explain 640-byte reduction

2. **Padding removal**
   - Original .qplug may have trailing padding
   - Padding stripped during processing

3. **Format conversion**
   - Q-SYS plugin format may have inefficiencies
   - Encryption process optimizes structure

**Cannot Confirm Without:** 
- Examining multiple test cases
- Decompressing decrypted output
- Analyzing .qplug internal format

## File Format Validation

### Determinism Test Results

**Test:** Encrypted same file twice
**Result:** Different output each time
**First SHA256:** 6276E2AC3F91C2578D11C6A4E1224840B35DD65B412859F5440D167102B99FAB
**Second SHA256:** 4E0A9E98DB89B97DFEF1A1DE9D1AEC457E2587648FFB554C9EC7ACB1027ED05B
**First Difference:** Byte offset 8

**Analysis:**
- Byte offset 8 is within the IV field in JSON
- Confirms IV is randomly generated per encryption
- This is correct cryptographic practice
- Prevents identical plaintext from producing identical ciphertext

## Public Key Extraction Strategy

### Hypothesis: RSA Public Key is Embedded in Executable

**Rationale:**
1. Tool performs encryption without user input
2. No external key files in binary package
3. Public keys are non-sensitive (safe to embed)
4. Standard practice for encryption-only tools

**Extraction Methods (Clean Room Compliant):**

1. **String Scanning:**
   - Use `strings` utility on executable
   - Search for PEM format markers:
     - `-----BEGIN PUBLIC KEY-----`
     - `-----BEGIN RSA PUBLIC KEY-----`
   - Search for base64-encoded key material
   - Look for OpenSSL ASN.1 structures

2. **Memory Dump Analysis:**
   - Run tool with test file
   - Capture memory dump during execution
   - Search for RSA public key structures
   - Identify key loading patterns

3. **Resource Inspection:**
   - Check PE file resources
   - Look for embedded data sections
   - Search for custom resource types

**Expected Key Format:**
- RSA-2048 public key
- Likely PEM or DER encoded
- Approximately 294 bytes (DER) or 451 bytes (PEM)
- May be embedded as text, binary, or base64

**Our Scope:**
- **ENCRYPTION ONLY:** We only need the public key
- **NO DECRYPTION:** We will not handle private keys
- **NO KEY GENERATION:** We use the existing embedded key
- **READ-ONLY ACCESS:** Public key extraction is non-invasive

### Implementation Plan

Once public key is extracted:
1. Save to separate .pem file for our implementation
2. Use OpenSSL library to load and use the key
3. Replicate encryption behavior exactly
4. No need to reverse engineer key generation

## Questions for Future Investigation

1. **Compression:** Is compression always applied?
   - Test with pre-compressed input
   - Test with incompressible data (random bytes)
   - Identify compression library (zlib/gzip most likely)

2. **AES Mode:** CBC or GCM?
   - GCM provides authentication
   - CBC requires separate HMAC
   - Affects security properties
   - Test with various data patterns

3. **Key Derivation:** Is AES key truly random?
   - Use /dev/urandom equivalent?
   - CryptGenRandom (Windows)?
   - OpenSSL RAND_bytes()?

4. **Padding Scheme:** PKCS#7? Custom?
   - Affects block alignment
   - Standard for AES-CBC
   - May reveal information about implementation

5. **Compression Algorithm:** If compression is used
   - zlib (most common)
   - gzip
   - Custom implementation
   - Compression level settings

## Clean Room Compliance

All observations derived from:
- Black-box behavioral testing
- Hex dump analysis
- File size measurements
- JSON parsing of output
- Cryptographic size analysis