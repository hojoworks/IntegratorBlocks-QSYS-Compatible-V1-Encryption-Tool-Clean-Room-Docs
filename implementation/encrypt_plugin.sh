#!/bin/bash

# Q-SYS Plugin Encryption Tool - Bash Implementation
# Supports encryption and encrypted file validation only
#
# Usage:
#   ./encrypt_plugin.sh encrypt <input.qplug> <output.qplugx>
#   ./encrypt_plugin.sh validate <input.qplugx>
#   ./encrypt_plugin.sh version
#   ./encrypt_plugin.sh help
#
# File Extensions:
#   .qplug  - Source plugin files (Lua source)
#   .qplugx - Encrypted plugin files (JSON format)
#
# Requirements: openssl, base64 (standard utilities)

# RSA Public Key extracted from the original tool
RSA_PUBLIC_KEY='-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyfxU4QZbgbAHZv9atTIq
TPGsvaFezv3w2GxgtyronJQ0hhk+wKyIHKX1412+pxLGRkSinFmyxqEL7ob3iyqx
AvO4Spn74B6jcYxiqERX1igwOFduZNu1BcA9LLKU1P+QiZW2oovn1vyrdxrgJsTO
A5aukWZYIHOyO8H7Nuqp2t/UUQwn4FL9L+MLgn0zhAty7obJRN8YCkVA+AENM9+n
jGySiR+6PgPUmzMzbQyF58+yhsXytIidl8+Rkgmw7e2T6ZO0z0xrdoJltmS1T+bK
BMvsvrSxod6SY4QYeU0Cy+7CA5R8foggJVBcGPwHqelMYhjc32bZOsp1ZnrDlbmm
eQIDAQAB
-----END PUBLIC KEY-----'

# Color codes for output
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'
COLOR_GRAY='\033[0;90m'

# Function to check if required tools are installed
check_requirements() {
    local missing_tools=()
    
    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
    fi
    
    if ! command -v base64 &> /dev/null; then
        missing_tools+=("base64")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${COLOR_RED}Error: Missing required tools:${COLOR_RESET}"
        for tool in "${missing_tools[@]}"; do
            echo -e "  - $tool"
        done
        echo ""
        echo "Please install the missing tools and try again."
        exit 1
    fi
}

# Function to escape JSON strings (handles quotes, backslashes, newlines, etc.)
escape_json_string() {
    local input="$1"
    # Replace backslashes, quotes, and control characters
    printf '%s' "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g'
}

# Function to create JSON from key-value pairs
create_json() {
    local key_name="$1"
    local key_value="$2"
    local iv_name="$3"
    local iv_value="$4"
    local data_name="$5"
    local data_value="$6"
    
    # Create JSON manually (base64 strings don't need escaping)
    printf '{"key":"%s","iv":"%s","data":"%s"}' "$key_value" "$iv_value" "$data_value"
}

# Function to extract JSON value (simple parser for our specific JSON structure)
extract_json_value() {
    local json_file="$1"
    local key="$2"
    
    # Use grep and sed to extract the value for the given key
    # This handles our specific JSON format: {"key":"value","iv":"value","data":"value"}
    grep -o "\"$key\":\"[^\"]*\"" "$json_file" 2>/dev/null | sed "s/\"$key\":\"\([^\"]*\)\"/\1/"
}

# Function to validate JSON structure (simple validation for our specific format)
validate_json_structure() {
    local json_file="$1"
    
    # Check if file exists and is readable
    if [ ! -f "$json_file" ] || [ ! -r "$json_file" ]; then
        return 1
    fi
    
    # Check for basic JSON structure: starts with { ends with }
    local first_char=$(head -c 1 "$json_file" 2>/dev/null)
    local last_char=$(tail -c 1 "$json_file" 2>/dev/null)
    
    if [ "$first_char" != "{" ] || [ "$last_char" != "}" ]; then
        return 1
    fi
    
    # Check for required fields
    if ! grep -q '"key":' "$json_file" 2>/dev/null; then
        return 1
    fi
    
    if ! grep -q '"iv":' "$json_file" 2>/dev/null; then
        return 1
    fi
    
    if ! grep -q '"data":' "$json_file" 2>/dev/null; then
        return 1
    fi
    
    return 0
}

# Function to check and remove UTF-8 BOM if present
check_utf8_bom() {
    local input_file="$1"
    local temp_file="$2"
    
    # Check if file starts with UTF-8 BOM (EF BB BF)
    local first_bytes=$(od -An -t x1 -N 3 "$input_file" | tr -d ' \n')
    
    if [ "$first_bytes" = "efbbbf" ]; then
        echo -e "${COLOR_YELLOW}[encrypt] UTF-8 BOM detected and will be removed${COLOR_RESET}"
        # Remove BOM by skipping first 3 bytes
        if ! tail -c +4 "$input_file" > "$temp_file"; then
            echo -e "${COLOR_RED}Error: Failed to remove BOM from input file${COLOR_RESET}"
            return 1
        fi
    else
        # No BOM, copy file as-is
        if ! cp "$input_file" "$temp_file"; then
            echo -e "${COLOR_RED}Error: Failed to copy input file${COLOR_RESET}"
            return 1
        fi
    fi
    
    return 0
}

# Function to encrypt a plugin file
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local temp_dir=""
    
    # Cleanup function for this scope
    cleanup_encrypt() {
        if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
            # Securely wipe temporary files before removing
            find "$temp_dir" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || \
            find "$temp_dir" -type f -exec rm -f {} \;
            rm -rf "$temp_dir"
        fi
    }
    
    # Set trap for cleanup on exit/error
    trap cleanup_encrypt EXIT ERR
    
    # Verify input file exists
    if [ ! -f "$input_file" ]; then
        echo -e "${COLOR_RED}Error: Input file '$input_file' not found${COLOR_RESET}"
        exit 1
    fi
    
    # Check file size before processing (prevent loading huge files)
    local file_size=$(stat -c%s "$input_file" 2>/dev/null || stat -f%z "$input_file" 2>/dev/null)
    if [ "$file_size" -gt 104857600 ]; then  # 100MB limit
        echo -e "${COLOR_RED}Error: Input file too large ($file_size bytes). Maximum supported size is 100MB.${COLOR_RESET}"
        exit 1
    fi
    
    echo -e "${COLOR_CYAN}[encrypt] Reading input file: ${COLOR_YELLOW}$input_file${COLOR_RESET}"
    
    # Create temporary directory with secure permissions
    temp_dir=$(mktemp -d)
    chmod 700 "$temp_dir"
    
    local temp_data="$temp_dir/data.bin"
    local temp_key="$temp_dir/aes.key"
    local temp_iv="$temp_dir/aes.iv"
    local temp_encrypted_data="$temp_dir/encrypted.bin"
    local temp_encrypted_key="$temp_dir/encrypted.key"
    local temp_pubkey="$temp_dir/pubkey.pem"
    
    # Verify temp directory creation
    if [ ! -d "$temp_dir" ]; then
        echo -e "${COLOR_RED}Error: Failed to create temporary directory${COLOR_RESET}"
        exit 1
    fi
    
    # Check for BOM and prepare data
    echo -e "${COLOR_CYAN}[encrypt] Preparing data file...${COLOR_RESET}"
    if ! check_utf8_bom "$input_file" "$temp_data"; then
        echo -e "${COLOR_RED}Error: Failed to prepare data file${COLOR_RESET}"
        exit 1
    fi
    
    # Verify temp data file was created
    if [ ! -f "$temp_data" ]; then
        echo -e "${COLOR_RED}Error: Failed to create temporary data file${COLOR_RESET}"
        exit 1
    fi
    
    local data_size=$(wc -c < "$temp_data")
    echo -e "${COLOR_CYAN}[encrypt] Read ${COLOR_GREEN}$data_size bytes${COLOR_CYAN} from input file${COLOR_RESET}"
    
    # Generate random AES-256 key (32 bytes) and IV (16 bytes)
    openssl rand 32 > "$temp_key"
    openssl rand 16 > "$temp_iv"
    
    echo -e "${COLOR_CYAN}[encrypt] Encrypting data...${COLOR_RESET}"
    
    # Encrypt data with AES-256-CBC
    openssl enc -aes-256-cbc -in "$temp_data" -out "$temp_encrypted_data" \
        -K $(xxd -p -c 256 "$temp_key") \
        -iv $(xxd -p -c 256 "$temp_iv") \
        2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error: AES encryption failed${COLOR_RESET}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Save public key to temp file
    echo "$RSA_PUBLIC_KEY" > "$temp_pubkey"
    
    # Encrypt AES key with RSA public key using PKCS1 padding
    openssl rsautl -encrypt -inkey "$temp_pubkey" -pubin -pkcs -in "$temp_key" -out "$temp_encrypted_key" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error: RSA encryption failed${COLOR_RESET}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    echo -e "${COLOR_CYAN}[encrypt] Creating JSON output...${COLOR_RESET}"
    
    # Encode to base64
    local key_base64=$(base64 -w 0 < "$temp_encrypted_key")
    local iv_base64=$(base64 -w 0 < "$temp_iv")
    local data_base64=$(base64 -w 0 < "$temp_encrypted_data")
    
    # Create JSON output using pure bash
    local json_output=$(create_json "key" "$key_base64" "iv" "$iv_base64" "data" "$data_base64")
    
    echo -e "${COLOR_CYAN}[encrypt] Writing encrypted data to: ${COLOR_YELLOW}$output_file${COLOR_RESET}"
    
    # Write to temporary file first, then move atomically
    local temp_output="$output_file.tmp.$$"
    printf '%s' "$json_output" > "$temp_output"
    mv "$temp_output" "$output_file"
    
    local output_size=$(wc -c < "$output_file")
    echo -e "${COLOR_GREEN}[encrypt] Encryption completed successfully!${COLOR_RESET}"
    echo -e "${COLOR_CYAN}[encrypt] Output size: ${COLOR_GREEN}$output_size characters${COLOR_RESET}"
    echo -e "${COLOR_CYAN}[encrypt] Encrypted plugin available for deployment: $output_file${COLOR_RESET}"
    
    # Cleanup will happen automatically via trap
}

# Function to validate an encrypted file
validate_file() {
    local input_file="$1"
    local temp_dir=""
    
    # Cleanup function for this scope
    cleanup_validate() {
        if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
            rm -rf "$temp_dir"
        fi
    }
    
    # Set trap for cleanup
    trap cleanup_validate EXIT ERR
    
    # Verify input file exists
    if [ ! -f "$input_file" ]; then
        echo -e "${COLOR_RED}Error: Input file '$input_file' not found${COLOR_RESET}"
        exit 1
    fi
    
    # Check JSON structure and required fields
    if ! validate_json_structure "$input_file"; then
        echo -e "${COLOR_CYAN}[validate] ${COLOR_RED}Invalid encrypted file: Invalid JSON structure or missing required fields (key, iv, data)${COLOR_RESET}"
        exit 1
    fi
    
    # Extract and decode base64 components to check validity
    local key_base64=$(extract_json_value "$input_file" "key")
    local iv_base64=$(extract_json_value "$input_file" "iv")
    local data_base64=$(extract_json_value "$input_file" "data")
    
    # Verify we extracted all values
    if [ -z "$key_base64" ] || [ -z "$iv_base64" ] || [ -z "$data_base64" ]; then
        echo -e "${COLOR_CYAN}[validate] ${COLOR_RED}Invalid encrypted file: Could not extract required fields${COLOR_RESET}"
        exit 1
    fi
    
    # Validate base64 encoding by attempting to decode
    temp_dir=$(mktemp -d)
    chmod 700 "$temp_dir"
    
    if [ ! -d "$temp_dir" ]; then
        echo -e "${COLOR_RED}Error: Failed to create temporary directory${COLOR_RESET}"
        exit 1
    fi
    
    if ! echo "$key_base64" | base64 -d > "$temp_dir/key" 2>/dev/null; then
        echo -e "${COLOR_CYAN}[validate] ${COLOR_RED}Invalid encrypted file: Key is not valid base64${COLOR_RESET}"
        exit 1
    fi
    
    if ! echo "$iv_base64" | base64 -d > "$temp_dir/iv" 2>/dev/null; then
        echo -e "${COLOR_CYAN}[validate] ${COLOR_RED}Invalid encrypted file: IV is not valid base64${COLOR_RESET}"
        exit 1
    fi
    
    if ! echo "$data_base64" | base64 -d > "$temp_dir/data" 2>/dev/null; then
        echo -e "${COLOR_CYAN}[validate] ${COLOR_RED}Invalid encrypted file: Data is not valid base64${COLOR_RESET}"
        exit 1
    fi
    
    # Get sizes
    local key_size=$(wc -c < "$temp_dir/key")
    local iv_size=$(wc -c < "$temp_dir/iv")
    local data_size=$(wc -c < "$temp_dir/data")
    
    echo -e "${COLOR_CYAN}[validate] ${COLOR_GREEN}Encrypted file structure is valid${COLOR_RESET}"
    echo -e "${COLOR_CYAN}[validate] Key size: ${COLOR_YELLOW}$key_size bytes${COLOR_RESET}"
    echo -e "${COLOR_CYAN}[validate] IV size: ${COLOR_YELLOW}$iv_size bytes${COLOR_RESET}"
    echo -e "${COLOR_CYAN}[validate] Data size: ${COLOR_YELLOW}$data_size bytes${COLOR_RESET}"
    
    exit 0
}



# Function to show version
show_version() {
    echo -e "${COLOR_CYAN}encrypt_plugin.sh ${COLOR_GREEN}version 1.0${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Bash Q-SYS Plugin Encryption Tool${COLOR_RESET}"
    echo -e "${COLOR_GRAY}Reverse-engineered from plugin_tool.exe${COLOR_RESET}"
}

# Function to show usage
show_usage() {
    echo -e "${COLOR_GREEN}Usage:${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}./encrypt_plugin.sh ${COLOR_YELLOW}version${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}./encrypt_plugin.sh ${COLOR_YELLOW}encrypt ${COLOR_GRAY}[input.qplug] [output.qplugx]${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}./encrypt_plugin.sh ${COLOR_YELLOW}validate ${COLOR_GRAY}[encrypted.qplugx]${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}./encrypt_plugin.sh ${COLOR_YELLOW}help${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}File extensions:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}.qplug  ${COLOR_GRAY}- Source plugin files (Lua source)${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}.qplugx ${COLOR_GRAY}- Encrypted plugin files (JSON format)${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Requirements:${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}- openssl (for encryption operations)${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}- base64 (standard utility)${COLOR_RESET}"
}

# Input validation function
validate_input() {
    local file_path="$1"
    
    # Check for dangerous characters and paths
    if [[ "$file_path" =~ [^a-zA-Z0-9._/\\-] ]]; then
        echo -e "${COLOR_RED}Error: Invalid characters in file path: $file_path${COLOR_RESET}"
        exit 1
    fi
    
    # Prevent directory traversal
    if [[ "$file_path" == *".."* ]]; then
        echo -e "${COLOR_RED}Error: Directory traversal not allowed: $file_path${COLOR_RESET}"
        exit 1
    fi
}

# Main execution
main() {
    local command="$1"
    local input_file="$2"
    local output_file="$3"
    
    # Validate inputs if provided
    if [ -n "$input_file" ]; then
        validate_input "$input_file"
    fi
    
    if [ -n "$output_file" ]; then
        validate_input "$output_file"
    fi
    
    case "${command,,}" in
        version)
            show_version
            exit 0
            ;;
        encrypt)
            if [ -z "$input_file" ] || [ -z "$output_file" ]; then
                echo -e "${COLOR_RED}Error: encrypt command requires input and output file paths${COLOR_RESET}"
                echo ""
                show_usage
                exit 1
            fi
            check_requirements
            encrypt_file "$input_file" "$output_file"
            exit 0
            ;;
        validate)
            if [ -z "$input_file" ]; then
                echo -e "${COLOR_RED}Error: validate command requires an encrypted file path${COLOR_RESET}"
                echo ""
                show_usage
                exit 1
            fi
            check_requirements
            validate_file "$input_file"
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        "")
            show_usage
            exit 0
            ;;
        *)
            echo -e "${COLOR_RED}Error: Unknown command: $command${COLOR_RESET}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
