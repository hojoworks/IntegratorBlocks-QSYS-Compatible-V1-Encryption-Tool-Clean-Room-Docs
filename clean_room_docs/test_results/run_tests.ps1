# Plugin Encryption Tool - Test Runner Script
# Clean Room Documentation Project
# Date: October 28, 2025

# Configuration
$ScriptRoot = $PSScriptRoot
$TestFolder = "C:\tmp\plugin_encryption_test"
$SourceBinary = Join-Path $ScriptRoot "original_binary\release"
$TestFiles = Join-Path $ScriptRoot "test_files"
$ResultsFolder = Join-Path $ScriptRoot "clean_room_docs\test_results"

# Colors for output
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

Write-Host "`n========================================" -ForegroundColor $ColorInfo
Write-Host "Plugin Encryption Tool - Test Suite" -ForegroundColor $ColorInfo
Write-Host "Clean Room Documentation Project" -ForegroundColor $ColorInfo
Write-Host "========================================`n" -ForegroundColor $ColorInfo

# Step 1: Create test folder
Write-Host "[1/6] Creating test folder..." -ForegroundColor $ColorInfo
if (Test-Path $TestFolder) {
    Write-Host "  Cleaning existing test folder..." -ForegroundColor $ColorWarning
    Remove-Item -Path $TestFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $TestFolder -Force | Out-Null
Write-Host "  Test folder created: $TestFolder" -ForegroundColor $ColorSuccess

# Step 2: Copy binary files
Write-Host "`n[2/6] Copying binary files..." -ForegroundColor $ColorInfo
$BinaryFiles = Get-ChildItem -Path $SourceBinary -File
foreach ($file in $BinaryFiles) {
    Copy-Item -Path $file.FullName -Destination $TestFolder -Force
    Write-Host "  Copied: $($file.Name)" -ForegroundColor $ColorSuccess
}
Write-Host "  Total files copied: $($BinaryFiles.Count)" -ForegroundColor $ColorSuccess

# Step 3: Copy test files
Write-Host "`n[3/6] Copying test .qplug files..." -ForegroundColor $ColorInfo
$TestPlugFiles = Get-ChildItem -Path $TestFiles -Filter "*.qplug"
foreach ($file in $TestPlugFiles) {
    Copy-Item -Path $file.FullName -Destination $TestFolder -Force
    Write-Host "  Copied: $($file.Name)" -ForegroundColor $ColorSuccess
}
Write-Host "  Total test files copied: $($TestPlugFiles.Count)" -ForegroundColor $ColorSuccess

# Step 4: Run version command
Write-Host "`n[4/6] Running version command..." -ForegroundColor $ColorInfo
Push-Location $TestFolder
try {
    $versionOutput = & .\plugin_tool_release.exe version 2>&1
    Write-Host "  Output: $versionOutput" -ForegroundColor $ColorSuccess
    
    # Save to results
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $versionOutput | Out-File -FilePath "$ResultsFolder\version_output_$timestamp.txt" -Encoding UTF8
} catch {
    Write-Host "  Error: $_" -ForegroundColor $ColorError
}

# Step 5: Run usage command
Write-Host "`n[5/6] Running usage command..." -ForegroundColor $ColorInfo
try {
    $usageOutput = & .\plugin_tool_release.exe usage 2>&1
    Write-Host "  Output:" -ForegroundColor $ColorSuccess
    Write-Host $usageOutput -ForegroundColor $ColorSuccess
    
    # Save to results
    $usageOutput | Out-File -FilePath "$ResultsFolder\usage_output_$timestamp.txt" -Encoding UTF8
} catch {
    Write-Host "  Error: $_" -ForegroundColor $ColorError
}

# Step 6: Run encryption tests
Write-Host "`n[6/6] Running encryption tests..." -ForegroundColor $ColorInfo

foreach ($plugFile in $TestPlugFiles) {
    $inputFile = $plugFile.Name
    $outputFile = $inputFile -replace '\.qplug$', '.qplugx'
    
    Write-Host "`n  Test: Encrypting $inputFile" -ForegroundColor $ColorInfo
    
    try {
        # Get input file size
        $inputSize = (Get-Item $inputFile).Length
        Write-Host "    Input size: $inputSize bytes" -ForegroundColor $ColorInfo
        
        # Run encryption
        $encryptOutput = & .\plugin_tool_release.exe encrypt $inputFile $outputFile 2>&1
        
        if (Test-Path $outputFile) {
            $outputSize = (Get-Item $outputFile).Length
            $overhead = $outputSize - $inputSize
            
            Write-Host "    Output size: $outputSize bytes" -ForegroundColor $ColorSuccess
            Write-Host "    Overhead: $overhead bytes" -ForegroundColor $ColorSuccess
            Write-Host "    Encryption successful!" -ForegroundColor $ColorSuccess
            
            # Calculate SHA256 of input and output
            $inputHash = (Get-FileHash -Path $inputFile -Algorithm SHA256).Hash
            $outputHash = (Get-FileHash -Path $outputFile -Algorithm SHA256).Hash
            
            Write-Host "    Input SHA256: $inputHash" -ForegroundColor $ColorInfo
            Write-Host "    Output SHA256: $outputHash" -ForegroundColor $ColorInfo
            
            # Save results
            $testResult = @"
Test: $inputFile -> $outputFile
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Input Size: $inputSize bytes
Output Size: $outputSize bytes
Overhead: $overhead bytes
Input SHA256: $inputHash
Output SHA256: $outputHash
Encryption Output: $encryptOutput
"@
            $testResult | Out-File -FilePath "$ResultsFolder\encrypt_test_$($inputFile)_$timestamp.txt" -Encoding UTF8
            
            # Copy encrypted file to results
            Copy-Item -Path $outputFile -Destination "$ResultsFolder\$outputFile" -Force
            
            # Test determinism: encrypt the same file again
            Write-Host "`n    Testing determinism (encrypting same file again)..." -ForegroundColor $ColorInfo
            $outputFile2 = $inputFile -replace '\.qplug$', '_second.qplugx'
            $encryptOutput2 = & .\plugin_tool_release.exe encrypt $inputFile $outputFile2 2>&1
            
            if (Test-Path $outputFile2) {
                $outputHash2 = (Get-FileHash -Path $outputFile2 -Algorithm SHA256).Hash
                
                if ($outputHash -eq $outputHash2) {
                    Write-Host "    Determinism: YES (same output)" -ForegroundColor $ColorSuccess
                } else {
                    Write-Host "    Determinism: NO (different output - uses random IV/nonce)" -ForegroundColor $ColorWarning
                }
                
                # Compare files byte by byte
                $bytes1 = [System.IO.File]::ReadAllBytes((Join-Path $TestFolder $outputFile))
                $bytes2 = [System.IO.File]::ReadAllBytes((Join-Path $TestFolder $outputFile2))
                $identical = $true
                
                if ($bytes1.Length -eq $bytes2.Length) {
                    for ($i = 0; $i -lt $bytes1.Length; $i++) {
                        if ($bytes1[$i] -ne $bytes2[$i]) {
                            $identical = $false
                            Write-Host "    First difference at byte offset: $i" -ForegroundColor $ColorInfo
                            break
                        }
                    }
                } else {
                    $identical = $false
                }
                
                if ($identical) {
                    Write-Host "    Files are IDENTICAL (byte-for-byte)" -ForegroundColor $ColorSuccess
                } else {
                    Write-Host "    Files are DIFFERENT (non-deterministic encryption)" -ForegroundColor $ColorWarning
                }
                
                # Save determinism test results
                $determinismResult = @"
Determinism Test: $inputFile
First encryption SHA256: $outputHash
Second encryption SHA256: $outputHash2
Identical: $identical
"@
                $determinismResult | Out-File -FilePath "$ResultsFolder\determinism_test_$($inputFile)_$timestamp.txt" -Encoding UTF8
            }
            
            # Create hex dump of first 512 bytes
            Write-Host "`n    Creating hex dump of encrypted file..." -ForegroundColor $ColorInfo
            $hexBytes = [System.IO.File]::ReadAllBytes((Join-Path $TestFolder $outputFile))
            $hexDumpSize = [Math]::Min(512, $hexBytes.Length)
            $hexDump = ""
            
            for ($i = 0; $i -lt $hexDumpSize; $i += 16) {
                $hexLine = "{0:X8}  " -f $i
                $asciiLine = ""
                
                for ($j = 0; $j -lt 16; $j++) {
                    if ($i + $j -lt $hexDumpSize) {
                        $byte = $hexBytes[$i + $j]
                        $hexLine += "{0:X2} " -f $byte
                        if ($byte -ge 32 -and $byte -le 126) {
                            $asciiLine += [char]$byte
                        } else {
                            $asciiLine += "."
                        }
                    } else {
                        $hexLine += "   "
                    }
                }
                
                $hexDump += "$hexLine  $asciiLine`n"
            }
            
            $hexDump | Out-File -FilePath "$ResultsFolder\hexdump_$($outputFile)_$timestamp.txt" -Encoding UTF8
            Write-Host "    Hex dump saved (first $hexDumpSize bytes)" -ForegroundColor $ColorSuccess
            
        } else {
            Write-Host "    Error: Output file not created" -ForegroundColor $ColorError
            Write-Host "    Encryption output: $encryptOutput" -ForegroundColor $ColorError
        }
        
    } catch {
        Write-Host "    Error: $_" -ForegroundColor $ColorError
    }
}

Pop-Location

# Summary
Write-Host "`n========================================" -ForegroundColor $ColorInfo
Write-Host "Test Execution Complete!" -ForegroundColor $ColorSuccess
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host "Test folder: $TestFolder" -ForegroundColor $ColorInfo
Write-Host "Results saved to: $ResultsFolder" -ForegroundColor $ColorInfo

