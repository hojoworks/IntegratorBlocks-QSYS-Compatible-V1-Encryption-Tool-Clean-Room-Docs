# OpenSSL Library Analysis

**Date:** October 28, 2025  
**Observer:** AF
**Analysis Type:** Dependency Analysis (Clean Room Compliant)

## Overview

The Plugin Encryption Tool relies on OpenSSL libraries for cryptographic operations. This document analyzes the implications of these dependencies.

## OpenSSL Libraries Present

### Release/Production Libraries (OpenSSL 1.1)

**libcrypto-1_1-x64.dll** (3.31 MB)
- OpenSSL cryptographic primitives library
- Version: 1.1.x series (x64 architecture)
- Provides: AES, RSA, SHA, HMAC, random number generation, etc.

**libssl-1_1-x64.dll** (663.5 KB)
- OpenSSL SSL/TLS protocol library
- Version: 1.1.x series (x64 architecture)
- Provides: SSL/TLS implementations (though likely not used for file encryption)

### Debug/Development Libraries

**libcryptoMD.dll** (2.34 MB)
- Multi-threaded Debug build of OpenSSL crypto
- "MD" = Multi-threaded Debug runtime linkage
- Typically used during development/testing

**libeay32MD.dll** (2.08 MB)
- Legacy OpenSSL crypto library name (pre-1.1.0)
- "libeay" = "library, Eric Andrew Young" (OpenSSL co-founder)
- MD build variant

**libsslMD.dll** (479 KB)
- Debug build of SSL/TLS library
- Likely not used for file encryption operations

## Analysis: Why Both Release and Debug?

### Possible Explanations:

1. **Development Artifact**
   - Debug libraries accidentally included in distribution
   - Common oversight in manual packaging

2. **Runtime Switching**
   - Tool might dynamically load different libraries based on mode
   - Unlikely given small executable size

3. **Compatibility**
   - Different libraries for different scenarios
   - But release builds should not depend on debug libraries

4. **Testing/Diagnostic Mode**
   - Hidden debug mode that uses MD libraries
   - Would allow verbose error reporting

### Most Likely Scenario:
Development/packaging oversight. Production release should only include release libraries (libcrypto-1_1-x64.dll and libssl-1_1-x64.dll).

## Cryptographic Capabilities

Based on OpenSSL 1.1.x inclusion, the tool has access to:

### Symmetric Encryption Algorithms
- **AES** (128, 192, 256-bit) - Most likely candidate
  - AES-CBC, AES-GCM, AES-CTR, AES-ECB modes available
- **DES/3DES** - Legacy, unlikely
- **Blowfish** - Legacy, unlikely
- **Camellia** - Less common
- **ChaCha20** - Modern, possible

### Asymmetric Encryption Algorithms
- **RSA** - Possible for key encryption
- **DSA** - Digital signatures
- **ECDSA** - Elliptic curve signatures
- **DH/ECDH** - Key exchange (unlikely for file encryption)

### Hash Functions
- **SHA-1** - Legacy
- **SHA-2** (SHA-256, SHA-384, SHA-512) - Most likely
- **SHA-3** - Modern
- **MD5** - Legacy, insecure
- **BLAKE2** - Modern

### Key Derivation Functions
- **PBKDF2** - Password-based key derivation
- **HKDF** - HMAC-based key derivation
- **scrypt** - Memory-hard KDF

### Random Number Generation
- **OpenSSL RAND** - Cryptographically secure PRNG

## Likely Encryption Scheme

### Hypothesis 1: AES-256-CBC
**Evidence:**
- Industry standard for file encryption
- Widely used in enterprise tools
- Available in OpenSSL 1.1.x

**Typical Implementation:**
```
1. Generate random AES key (or derive from password/master key)
2. Generate random IV (Initialization Vector)
3. Encrypt file content with AES-256-CBC
4. Store IV + encrypted data in output file
5. Optionally: HMAC for integrity verification
```

### Hypothesis 2: AES-256-GCM
**Evidence:**
- Modern authenticated encryption
- Provides both confidentiality and integrity
- Increasingly popular in new applications

**Typical Implementation:**
```
1. Generate random AES key
2. Generate random nonce/IV
3. Encrypt with AES-GCM (authenticated encryption)
4. Store nonce + ciphertext + authentication tag
```

### Hypothesis 3: Hybrid Encryption
**Evidence:**
- Could use RSA for key encryption + AES for data
- Common in sophisticated systems
- Allows key management flexibility

**Typical Implementation:**
```
1. Generate random AES session key
2. Encrypt file with AES
3. Encrypt AES key with RSA public key
4. Store encrypted key + encrypted file
```

## Key Management Questions

### Question 1: Key Source
Where does the encryption key come from?

**Possibilities:**
- A) Embedded in executable (fixed key)
- B) Derived from file content (hash-based)
- C) Derived from machine/user ID (hardware-bound)
- D) Randomly generated per file (symmetric)
- E) Public key encryption (asymmetric)

**Documentation Review:**
- No password prompt mentioned
- No key file mentioned
- Suggests either embedded key or derived key

### Question 2: Key Storage
If symmetric, where is the decryption key?

**Possibilities:**
- Not intended to be decryptable (one-way protection)

### Question 3: Determinism
Does encrypting the same file twice produce identical output?

**If YES:** Deterministic encryption
- No random IV/nonce
- Key derived from file content
- Weaker security (no semantic security)

**If NO:** Non-deterministic encryption
- Random IV/nonce per encryption
- Better security (semantic security)
- Each encryption produces different output

**To Test:** Encrypt same file twice, compare outputs.

## Analysis Limitations (Clean Room Compliance)

**What We Analyzed:**
- DLL file names and versions
- File sizes suggesting algorithm complexity
- OpenSSL documentation for available algorithms
- Common implementation patterns

**What We Did NOT Do:**
- Analyze DLL internals
- Hook or intercept OpenSSL calls
- Debug the application
- Examine import tables of executable  

All conclusions are based on:
- Published OpenSSL documentation
- Industry standard practices
- Logical deduction from public information

## Testing Recommendations

To determine actual encryption method:

1. **Determinism Test**
   - Encrypt same file twice
   - Compare outputs byte-by-byte
   - If identical → deterministic; if different → random IV

2. **File Size Test**
   - Encrypt files of various sizes
   - Calculate overhead (output_size - input_size)
   - Reveals: IV size, padding scheme, header size

3. **Pattern Test**
   - Encrypt files with known patterns (all zeros, repeating bytes)
   - Analyze ciphertext for patterns
   - Determines block cipher mode

4. **Entropy Test**
   - Calculate Shannon entropy of encrypted files
   - Should be close to 8.0 bits/byte for good encryption
   - Lower entropy suggests weakness

5. **Known-Plaintext Test**
   - Create .qplug files with controlled content
   - Encrypt and analyze
   - May reveal file format structure

## Preliminary Conclusions

1. **Encryption Capability:** Tool has full access to modern cryptographic algorithms via OpenSSL
2. **Most Likely Algorithm:** AES-256 in CBC or GCM mode
3. **Key Management:** Likely embedded or derived (no user interaction documented)
4. **Decryption:** Q-SYS Designer must have complementary decryption capability
5. **Security Level:** Depends on key management more than algorithm choice

## References

- OpenSSL 1.1.1 Documentation: https://www.openssl.org/docs/man1.1.1/
- OpenSSL Security Policy: https://www.openssl.org/policies/secpolicy.html
- Common Encryption Patterns: Applied Cryptography by Bruce Schneier
