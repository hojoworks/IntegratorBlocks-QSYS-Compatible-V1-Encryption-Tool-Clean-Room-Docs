# Q-SYS Plugin Encryption Tool - PowerShell Implementation
# Supports encryption and encrypted file validation only
#
# Usage:
#   .\encrypt_plugin.ps1 encrypt <input.qplug> <output.qplugx>
#   .\encrypt_plugin.ps1 validate <input.qplugx>
#   .\encrypt_plugin.ps1 version
#   .\encrypt_plugin.ps1 help
#
# File Extensions:
#   .qplug  - Source plugin files (Lua source)
#   .qplugx - Encrypted plugin files (JSON format)

param(
    [Parameter(Position=0)]
    [ValidateSet("encrypt", "validate", "version", "help", "")]
    [string]$Command = "",
    
    [Parameter(Position=1)]
    [string]$InputFile = "",
    
    [Parameter(Position=2)]
    [string]$OutputFile = ""
)

# Input validation and sanitization (allow valid Windows paths)
if ($InputFile -and $InputFile -match '[<>"|?*]|^\.\.') {
    Write-Error "Invalid characters in input file path"
    exit 1
}

if ($OutputFile -and $OutputFile -match '[<>"|?*]|^\.\.') {
    Write-Error "Invalid characters in output file path"
    exit 1
}

# RSA Public Key extracted from the original tool
$RSAPublicKeyPEM = @"
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyfxU4QZbgbAHZv9atTIq
TPGsvaFezv3w2GxgtyronJQ0hhk+wKyIHKX1412+pxLGRkSinFmyxqEL7ob3iyqx
AvO4Spn74B6jcYxiqERX1igwOFduZNu1BcA9LLKU1P+QiZW2oovn1vyrdxrgJsTO
A5aukWZYIHOyO8H7Nuqp2t/UUQwn4FL9L+MLgn0zhAty7obJRN8YCkVA+AENM9+n
jGySiR+6PgPUmzMzbQyF58+yhsXytIidl8+Rkgmw7e2T6ZO0z0xrdoJltmS1T+bK
BMvsvrSxod6SY4QYeU0Cy+7CA5R8foggJVBcGPwHqelMYhjc32bZOsp1ZnrDlbmm
eQIDAQAB
-----END PUBLIC KEY-----
"@

# UTF-8 BOM bytes
$UTF8_BOM = [byte[]](0xEF, 0xBB, 0xBF)

class PluginEncryptionTool : System.IDisposable {
    [System.Security.Cryptography.RSA]$PublicKey
    
    PluginEncryptionTool() {
        $this.LoadPublicKey()
    }
    
    # Implement IDisposable for proper cleanup
    [void]Dispose() {
        if ($this.PublicKey) {
            $this.PublicKey.Dispose()
            $this.PublicKey = $null
        }
    }
    
    [void]LoadPublicKey() {
        try {
            # Remove PEM headers and decode base64
            $keyData = $script:RSAPublicKeyPEM -replace "-----BEGIN PUBLIC KEY-----", "" -replace "-----END PUBLIC KEY-----", "" -replace "`n", "" -replace "`r", ""
            $keyBytes = [Convert]::FromBase64String($keyData)
            
            # Create RSA provider and import the key using XML format
            $this.PublicKey = [System.Security.Cryptography.RSA]::Create()
            
            # Parse the DER encoded public key manually or use alternative method
            
            # Try using ImportSubjectPublicKeyInfo if available (.NET Core 3.0+)
            if ($this.PublicKey | Get-Member -Name "ImportSubjectPublicKeyInfo" -MemberType Method) {
                $this.PublicKey.ImportSubjectPublicKeyInfo($keyBytes, [ref]$null)
            }
            # Fallback: Try ImportRSAPublicKey (.NET Core 2.1+)
            elseif ($this.PublicKey | Get-Member -Name "ImportRSAPublicKey" -MemberType Method) {
                $this.PublicKey.ImportRSAPublicKey($keyBytes, [ref]$null)
            }
            # Legacy fallback: Convert to XML parameters
            else {
                # Extract modulus and exponent from DER data (simplified approach)
                # This is a basic implementation - in practice you'd need proper DER parsing
                $this.PublicKey = $this.CreateRSAFromModulusAndExponent()
            }
            
            Write-Verbose "RSA public key loaded successfully"
        }
        catch {
            Write-Error "Failed to load RSA public key: $($_.Exception.Message)"
            throw
        }
    }
    
    [System.Security.Cryptography.RSA]CreateRSAFromModulusAndExponent() {
        # Hardcoded RSA parameters extracted from the public key
        # Modulus (n) and Exponent (e) from the 2048-bit RSA key
        $modulusBase64 = "yfxU4QZbgbAHZv9atTIqTPGsvaFezv3w2GxgtyronJQ0hhk+wKyIHKX1412+pxLGRkSinFmyxqEL7ob3iyqxAvO4Spn74B6jcYxiqERX1igwOFduZNu1BcA9LLKU1P+QiZW2oovn1vyrdxrgJsTOA5aukWZYIHOyO8H7Nuqp2t/UUQwn4FL9L+MLgn0zhAty7obJRN8YCkVA+AENM9+njGySiR+6PgPUmzMzbQyF58+yhsXytIidl8+Rkgmw7e2T6ZO0z0xrdoJltmS1T+bKBMvsvrSxod6SY4QYeU0Cy+7CA5R8foggJVBcGPwHqelMYhjc32bZOsp1ZnrDlbmmeQ=="
        $exponentBase64 = "AQAB"
        
        $modulus = [Convert]::FromBase64String($modulusBase64)
        $exponent = [Convert]::FromBase64String($exponentBase64)
        
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $params = New-Object System.Security.Cryptography.RSAParameters
        $params.Modulus = $modulus
        $params.Exponent = $exponent
        
        $rsa.ImportParameters($params)
        return $rsa
    }
    
    [PSObject]CheckUTF8BOM([byte[]]$data) {
        $hasBOM = $false
        $cleanData = $data
        
        if ($data.Length -ge 3 -and 
            $data[0] -eq $script:UTF8_BOM[0] -and 
            $data[1] -eq $script:UTF8_BOM[1] -and 
            $data[2] -eq $script:UTF8_BOM[2]) {
            $hasBOM = $true
            $cleanData = $data[3..($data.Length - 1)]
            Write-Verbose "UTF-8 BOM detected and removed"
        }
        
        return [PSCustomObject]@{
            Data = $cleanData
            HasBOM = $hasBOM
        }
    }
    
    [PSObject]EncryptData([byte[]]$data) {
        $aes = $null
        $encryptor = $null
        $rsaProvider = $null
        $aesKey = $null
        $aesIV = $null
        
        try {
            # Generate random AES key (256-bit) and IV (128-bit)
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.KeySize = 256
            $aes.BlockSize = 128
            $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
            $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
            $aes.GenerateKey()
            $aes.GenerateIV()
            
            # Store copies before encryption (original will be cleared)
            $aesKey = [byte[]]::new($aes.Key.Length)
            $aes.Key.CopyTo($aesKey, 0)
            $aesIV = [byte[]]::new($aes.IV.Length)
            $aes.IV.CopyTo($aesIV, 0)
            
            Write-Verbose "Generated AES key: $($aesKey.Length) bytes"
            Write-Verbose "Generated AES IV: $($aesIV.Length) bytes"
            
            # Encrypt data with AES
            $encryptor = $aes.CreateEncryptor()
            $encryptedData = $encryptor.TransformFinalBlock($data, 0, $data.Length)
            
            Write-Verbose "AES encrypted data size: $($encryptedData.Length) bytes"
            
            # Encrypt AES key with RSA using PKCS1 padding
            $rsaProvider = New-Object System.Security.Cryptography.RSACryptoServiceProvider
            $rsaProvider.ImportParameters($this.PublicKey.ExportParameters($false))
            $encryptedKey = $rsaProvider.Encrypt($aesKey, $false)  # false = PKCS1 padding
            
            Write-Verbose "RSA encrypted key size: $($encryptedKey.Length) bytes"
            
            # Return structured result
            return [PSCustomObject]@{
                EncryptedKey = $encryptedKey
                IV = $aesIV
                EncryptedData = $encryptedData
            }
        }
        catch {
            Write-Error "Encryption failed: $($_.Exception.Message)"
            throw
        }
        finally {
            # Secure cleanup - clear sensitive data from memory
            if ($aesKey) {
                [Array]::Clear($aesKey, 0, $aesKey.Length)
            }
            if ($aesIV) {
                [Array]::Clear($aesIV, 0, $aesIV.Length)
            }
            
            # Dispose cryptographic objects
            if ($encryptor) { $encryptor.Dispose() }
            if ($aes) { $aes.Dispose() }
            if ($rsaProvider) { $rsaProvider.Dispose() }
        }
    }
    
    [string]EncodeBase64([byte[]]$data) {
        return [Convert]::ToBase64String($data)
    }
    

    

    

    
    [PSObject]ValidateEncryptedFile([string]$inputFile) {
        try {
            # Verify input file exists
            if (-not (Test-Path $inputFile)) {
                throw "Input file '$inputFile' not found"
            }
            
            # Read and parse JSON from input file
            $jsonContent = [System.IO.File]::ReadAllText($inputFile)
            $encryptedData = $jsonContent | ConvertFrom-Json
            
            # Validate JSON structure
            if (-not $encryptedData.key -or -not $encryptedData.iv -or -not $encryptedData.data) {
                throw "Invalid encrypted file format - missing required fields (key, iv, data)"
            }
            
            # Decode and validate base64 components
            $encryptedKey = [Convert]::FromBase64String($encryptedData.key)
            $iv = [Convert]::FromBase64String($encryptedData.iv)
            $encryptedDataBytes = [Convert]::FromBase64String($encryptedData.data)
            
            return [PSCustomObject]@{
                IsValid = $true
                KeySize = $encryptedKey.Length
                IVSize = $iv.Length
                DataSize = $encryptedDataBytes.Length
                Message = "Encrypted file structure is valid"
            }
        }
        catch {
            return [PSCustomObject]@{
                IsValid = $false
                KeySize = 0
                IVSize = 0
                DataSize = 0
                Message = "Invalid encrypted file: $($_.Exception.Message)"
            }
        }
    }
    
    [void]EncryptFile([string]$inputFile, [string]$outputFile) {
        $data = $null
        
        try {
            # Verify input file exists
            if (-not (Test-Path $inputFile)) {
                throw "Input file '$inputFile' not found"
            }
            
            # Check file size before reading (prevent loading huge files)
            $fileInfo = Get-Item $inputFile
            if ($fileInfo.Length -gt 100MB) {
                throw "Input file too large ($($fileInfo.Length) bytes). Maximum supported size is 100MB."
            }
            
            # Read input file as bytes
            Write-Host "[encrypt] Reading input file: " -ForegroundColor Cyan -NoNewline
            Write-Host "$inputFile" -ForegroundColor Yellow
            $data = [System.IO.File]::ReadAllBytes($inputFile)
            Write-Host "[encrypt] Read " -ForegroundColor Cyan -NoNewline
            Write-Host "$($data.Length) bytes" -ForegroundColor Green -NoNewline
            Write-Host " from input file" -ForegroundColor Cyan
            
            # Check for UTF-8 BOM
            $bomResult = $this.CheckUTF8BOM($data)
            $originalData = $data
            $data = $bomResult.Data
            
            # Clear original data array if BOM was removed
            if ($bomResult.HasBOM -and $originalData) {
                [Array]::Clear($originalData, 0, $originalData.Length)
                Write-Host "[encrypt] UTF-8 BOM detected and removed" -ForegroundColor Yellow
            }
            
            # Encrypt the data
            Write-Host "[encrypt] Encrypting data..." -ForegroundColor Cyan
            $encryptResult = $this.EncryptData($data)
            
            # Create JSON structure matching official tool format
            Write-Host "[encrypt] Creating JSON output..." -ForegroundColor Cyan
            $jsonOutput = @{
                key = [Convert]::ToBase64String($encryptResult.EncryptedKey)
                iv = [Convert]::ToBase64String($encryptResult.IV)
                data = [Convert]::ToBase64String($encryptResult.EncryptedData)
            } | ConvertTo-Json -Compress
            
            # Write to output file atomically
            Write-Host "[encrypt] Writing encrypted data to: " -ForegroundColor Cyan -NoNewline
            Write-Host "$outputFile" -ForegroundColor Yellow
            
            $tempOutputFile = "$outputFile.tmp"
            [System.IO.File]::WriteAllText($tempOutputFile, $jsonOutput)
            Move-Item $tempOutputFile $outputFile -Force
            
            Write-Host "[encrypt] Encryption completed successfully!" -ForegroundColor Green
            Write-Host "[encrypt] Output size: " -ForegroundColor Cyan -NoNewline
            Write-Host "$($jsonOutput.Length) characters" -ForegroundColor Green
            Write-Host "[encrypt] Encrypted plugin available for deployment: $outputFile" -ForegroundColor Cyan
        }
        catch {
            Write-Error "Encryption failed: $($_.Exception.Message)"
            throw
        }
        finally {
            # Secure cleanup - clear sensitive data from memory
            if ($data) {
                [Array]::Clear($data, 0, $data.Length)
            }
        }
    }
    
    [void]ShowVersion() {
        Write-Host "encrypt_plugin.ps1 " -ForegroundColor Cyan -NoNewline
        Write-Host "version 1.0" -ForegroundColor Green
        Write-Host "Pure PowerShell Q-SYS Plugin Encryption Tool" -ForegroundColor Yellow
        Write-Host "Reverse-engineered from plugin_tool.exe" -ForegroundColor Gray
    }
    
    [void]ShowUsage() {
        Write-Host "Usage:" -ForegroundColor Green
        Write-Host "  encrypt_plugin.ps1 " -ForegroundColor Cyan -NoNewline
        Write-Host "version" -ForegroundColor Yellow
        Write-Host "  encrypt_plugin.ps1 " -ForegroundColor Cyan -NoNewline
        Write-Host "encrypt " -ForegroundColor Yellow -NoNewline
        Write-Host "[input.qplug] [output.qplugx]" -ForegroundColor Gray
        Write-Host "  encrypt_plugin.ps1 " -ForegroundColor Cyan -NoNewline
        Write-Host "validate " -ForegroundColor Yellow -NoNewline
        Write-Host "[encrypted.qplugx]" -ForegroundColor Gray
        Write-Host "  encrypt_plugin.ps1 " -ForegroundColor Cyan -NoNewline
        Write-Host "help" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "File extensions:" -ForegroundColor Green
        Write-Host "  .qplug  " -ForegroundColor Yellow -NoNewline
        Write-Host "- Source plugin files (Lua source)" -ForegroundColor Gray
        Write-Host "  .qplugx " -ForegroundColor Yellow -NoNewline
        Write-Host "- Encrypted plugin files (JSON format)" -ForegroundColor Gray
    }
}

# Main execution logic
function Main {
    param($Command, $InputFile, $OutputFile)
    
    $tool = $null
    try {
        $tool = [PluginEncryptionTool]::new()
        
        switch ($Command.ToLower()) {
            "version" {
                $tool.ShowVersion()
                exit 0
            }
            "encrypt" {
                if ([string]::IsNullOrEmpty($InputFile) -or [string]::IsNullOrEmpty($OutputFile)) {
                    Write-Error "encrypt command requires input and output file paths"
                    $tool.ShowUsage()
                    exit 1
                }
                $tool.EncryptFile($InputFile, $OutputFile)
                exit 0
            }
validate {
                if ([string]::IsNullOrEmpty($InputFile)) {
                    Write-Error "validate command requires an encrypted file path"
                    $tool.ShowUsage()
                    exit 1
                }
                $result = $tool.ValidateEncryptedFile($InputFile)
                if ($result.IsValid) {
                    Write-Host "[validate] " -ForegroundColor Cyan -NoNewline
                    Write-Host $result.Message -ForegroundColor Green
                    Write-Host "[validate] Key size: " -ForegroundColor Cyan -NoNewline
                    Write-Host "$($result.KeySize) bytes" -ForegroundColor Yellow
                    Write-Host "[validate] IV size: " -ForegroundColor Cyan -NoNewline
                    Write-Host "$($result.IVSize) bytes" -ForegroundColor Yellow
                    Write-Host "[validate] Data size: " -ForegroundColor Cyan -NoNewline
                    Write-Host "$($result.DataSize) bytes" -ForegroundColor Yellow
                    exit 0
                } else {
                    Write-Host "[validate] " -ForegroundColor Cyan -NoNewline
                    Write-Host $result.Message -ForegroundColor Red
                    exit 1
                }
            }
            "help" {
                $tool.ShowUsage()
                exit 0
            }
            default {
                if ([string]::IsNullOrEmpty($Command)) {
                    $tool.ShowUsage()
                } else {
                    Write-Error "Unknown command: $Command"
                    $tool.ShowUsage()
                    exit 1
                }
            }
        }
    }
    catch {
        Write-Error "Tool execution failed: $($_.Exception.Message)"
        exit 1
    }
    finally {
        # Ensure proper cleanup
        if ($tool) {
            $tool.Dispose()
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main -Command $Command -InputFile $InputFile -OutputFile $OutputFile
}
