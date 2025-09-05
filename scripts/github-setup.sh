#!/usr/bin/env bash
set -euo pipefail

# Colors for better user experience
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

prompt_user() {
    local prompt="$1"
    local var_name="$2"
    echo -n -e "${YELLOW}$prompt${NC} "
    read -r "$var_name"
}

confirm_action() {
    local prompt="$1"
    local response
    echo -n -e "${YELLOW}$prompt (y/N): ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if ! command -v gh >/dev/null 2>&1; then
        missing_tools+=("gh (GitHub CLI)")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please run the provisioning script first:"
        echo "  bash provision/$(uname | tr '[:upper:]' '[:lower:]').sh"
        exit 1
    fi
    
    print_step "All prerequisites found"
}

# Test if GitHub SSH access is already working
test_github_access() {
    print_header "Testing Current GitHub Access"
    
    echo "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_step "GitHub SSH access already working!"
        
        # Get the username from the SSH test
        local github_user
        github_user=$(ssh -T git@github.com 2>&1 | grep "successfully authenticated" | sed 's/.*Hi \([^!]*\)!.*/\1/')
        echo "Authenticated as: $github_user"
        
        if confirm_action "GitHub access is already configured. Skip SSH setup?"; then
            return 0
        else
            echo "Proceeding with SSH setup anyway..."
            return 1
        fi
    else
        echo "GitHub SSH access not working or not configured yet."
        return 1
    fi
}

# Find existing SSH keys
find_existing_ssh_keys() {
    local ssh_dir="$HOME/.ssh"
    local existing_keys=()
    
    # Check for common SSH key types
    local key_types=("id_ed25519" "id_rsa" "id_ecdsa" "id_dsa")
    
    for key_type in "${key_types[@]}"; do
        if [ -f "$ssh_dir/$key_type" ]; then
            existing_keys+=("$key_type")
        fi
    done
    
    echo "${existing_keys[@]}"
}

# Configure Git user information
configure_git_user() {
    print_header "Git User Configuration"
    
    local current_name current_email
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        echo "Current Git configuration:"
        echo "  Name: $current_name"
        echo "  Email: $current_email"
        
        if confirm_action "Keep current Git configuration?"; then
            print_step "Using existing Git configuration"
            return 0
        fi
    fi
    
    local git_name git_email
    prompt_user "Enter your full name:" git_name
    prompt_user "Enter your email address:" git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    print_step "Git user configuration updated"
}

# Setup SSH key for GitHub
setup_ssh_key() {
    print_header "SSH Key Setup"
    
    # Find all existing SSH keys
    local existing_keys
    existing_keys=$(find_existing_ssh_keys)
    
    if [ -n "$existing_keys" ]; then
        echo "Found existing SSH keys: $existing_keys"
        
        # Check if any existing key is already loaded in SSH agent
        local loaded_key=""
        for key in $existing_keys; do
            local key_path="$HOME/.ssh/$key"
            if ssh-add -l 2>/dev/null | grep -q "$key_path"; then
                loaded_key="$key"
                print_step "SSH key '$key' already loaded in agent"
                break
            fi
        done
        
        # If no key is loaded, offer to load one
        if [ -z "$loaded_key" ]; then
            echo "Available SSH keys:"
            local i=1
            for key in $existing_keys; do
                echo "  $i) $key"
                i=$((i+1))
            done
            echo "  $i) Generate new Ed25519 key"
            
            local choice
            prompt_user "Choose an option (1-$i):" choice
            
            if [ "$choice" -le "${#existing_keys[@]}" ] && [ "$choice" -ge 1 ]; then
                local selected_key
                selected_key=$(echo $existing_keys | cut -d' ' -f$choice)
                local key_path="$HOME/.ssh/$selected_key"
                
                echo "Adding $selected_key to SSH agent..."
                ssh-add "$key_path" 2>/dev/null || {
                    print_warning "Failed to add key to agent (may need passphrase)"
                    ssh-add "$key_path"
                }
                print_step "SSH key '$selected_key' added to agent"
                return 0
            fi
        else
            if confirm_action "Use existing loaded SSH key '$loaded_key'?"; then
                return 0
            fi
        fi
    fi
    
    # Generate new Ed25519 key
    local ssh_key_path="$HOME/.ssh/id_ed25519"
    local email
    email=$(git config --global user.email)
    
    if [ -f "$ssh_key_path" ]; then
        print_warning "Ed25519 key already exists but wasn't loaded"
        if ! confirm_action "Overwrite existing Ed25519 key?"; then
            return 1
        fi
    fi
    
    echo "Generating new Ed25519 SSH key..."
    ssh-keygen -t ed25519 -C "$email" -f "$ssh_key_path" -N ""
    
    # Start SSH agent and add key
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add "$ssh_key_path"
    
    print_step "New Ed25519 SSH key generated and added to agent"
}

# Add SSH key to GitHub account
add_ssh_key_to_github() {
    print_header "GitHub SSH Key Setup"
    
    local ssh_key_path="$HOME/.ssh/id_ed25519.pub"
    
    if [ ! -f "$ssh_key_path" ]; then
        print_error "Public SSH key not found at $ssh_key_path"
        return 1
    fi
    
    echo "Your public SSH key:"
    echo "----------------------------------------"
    cat "$ssh_key_path"
    echo "----------------------------------------"
    
    if confirm_action "Add this SSH key to your GitHub account automatically?"; then
        if gh auth status >/dev/null 2>&1; then
            local key_title
            prompt_user "Enter a title for this SSH key (e.g., 'Work Laptop'):" key_title
            gh ssh-key add "$ssh_key_path" --title "$key_title"
            print_step "SSH key added to GitHub account"
        else
            echo "GitHub CLI authentication required..."
            gh auth login
            local key_title
            prompt_user "Enter a title for this SSH key (e.g., 'Work Laptop'):" key_title
            gh ssh-key add "$ssh_key_path" --title "$key_title"
            print_step "SSH key added to GitHub account"
        fi
    else
        echo "Please manually add the SSH key to your GitHub account:"
        echo "1. Go to https://github.com/settings/ssh/new"
        echo "2. Paste the public key shown above"
        echo "3. Give it a descriptive title"
        echo ""
        prompt_user "Press Enter when you've added the key to GitHub..." _
    fi
}


# Setup GPG for verified commits
setup_gpg_signing() {
    print_header "GPG Setup for Verified Commits"
    
    if confirm_action "Set up GPG key signing for verified commits?"; then
        # Check if GPG is available
        if ! command -v gpg >/dev/null 2>&1; then
            print_warning "GPG not found. Installing..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                if command -v brew >/dev/null 2>&1; then
                    brew install gnupg
                else
                    print_error "Please install GPG manually"
                    return 1
                fi
            else
                sudo apt-get update && sudo apt-get install -y gnupg
            fi
        fi
        
        # Check for existing GPG keys
        local existing_keys
        existing_keys=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep sec || echo "")
        
        if [ -n "$existing_keys" ]; then
            echo "Existing GPG keys found:"
            gpg --list-secret-keys --keyid-format LONG
            if confirm_action "Use existing GPG key?"; then
                local key_id
                prompt_user "Enter the GPG key ID to use:" key_id
                git config --global user.signingkey "$key_id"
                git config --global commit.gpgsign true
                print_step "Configured Git to use existing GPG key"
                return 0
            fi
        fi
        
        # Generate new GPG key
        local name email
        name=$(git config --global user.name)
        email=$(git config --global user.email)
        
        echo "Generating GPG key for $name <$email>..."
        gpg --batch --full-generate-key <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $name
Name-Email: $email
Expire-Date: 2y
%no-ask-passphrase
%no-protection
%commit
%echo Done
EOF
        
        # Get the key ID and configure Git
        local key_id
        key_id=$(gpg --list-secret-keys --keyid-format LONG "$email" | grep sec | cut -d'/' -f2 | cut -d' ' -f1)
        
        git config --global user.signingkey "$key_id"
        git config --global commit.gpgsign true
        
        # Export public key for GitHub
        echo "Your GPG public key (add this to GitHub):"
        echo "----------------------------------------"
        gpg --armor --export "$key_id"
        echo "----------------------------------------"
        
        echo "To add this GPG key to GitHub:"
        echo "1. Go to https://github.com/settings/gpg/new"
        echo "2. Paste the GPG key shown above"
        echo ""
        prompt_user "Press Enter when you've added the GPG key to GitHub..." _
        
        print_step "GPG signing configured"
    else
        print_step "Skipping GPG setup"
    fi
}

# Main execution
main() {
    print_header "GitHub Development Setup Wizard"
    echo "This script will help you set up GitHub access for development."
    echo ""
    
    check_prerequisites
    
    # Test if GitHub access is already working
    local skip_ssh_setup=false
    if test_github_access; then
        skip_ssh_setup=true
        print_step "GitHub SSH access already configured and working"
    fi
    
    configure_git_user
    
    # Only do SSH setup if not already working
    if [ "$skip_ssh_setup" = false ]; then
        setup_ssh_key
        add_ssh_key_to_github
        
        # Test the connection after setup
        print_header "Verifying GitHub Connection"
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            print_step "GitHub SSH connection verified!"
        else
            print_warning "GitHub connection test failed. Please verify your setup."
        fi
    fi
    
    setup_gpg_signing
    
    print_header "Setup Complete!"
    echo "You're now ready to:"
    echo "• Clone repositories using SSH"
    echo "• Push commits to GitHub"
    if git config --global commit.gpgsign >/dev/null 2>&1; then
        echo "• Create verified commits with GPG signatures"
    fi
    echo ""
    echo "Next steps:"
    echo "1. Clone your company repository"
    echo "2. Set up your local development environment"
    echo ""
    echo "Run the repo setup script next:"
    echo "  bash scripts/repo-clone.sh"
}

# Run main function
main "$@"