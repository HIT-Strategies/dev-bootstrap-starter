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
    
    # Test GitHub access
    if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_warning "GitHub SSH access not verified"
        echo "Please run the GitHub setup script first:"
        echo "  bash scripts/github-setup.sh"
        if ! confirm_action "Continue anyway?"; then
            exit 1
        fi
    fi
    
    print_step "Prerequisites checked"
}

# Get company repository information
get_repo_info() {
    print_header "Repository Information"
    
    echo "Please provide your company repository details:"
    echo ""
    
    local repo_url repo_name clone_dir
    
    # Get repository URL
    prompt_user "Enter the repository URL (SSH format, e.g., git@github.com:company/repo.git):" repo_url
    
    # Extract repository name from URL
    repo_name=$(basename "$repo_url" .git)
    
    # Default clone directory
    clone_dir="$HOME/code/$repo_name"
    
    echo ""
    echo "Repository details:"
    echo "  URL: $repo_url"
    echo "  Name: $repo_name"
    echo "  Clone directory: $clone_dir"
    echo ""
    
    if confirm_action "Use these settings?"; then
        echo "$repo_url" > /tmp/repo_url
        echo "$clone_dir" > /tmp/clone_dir
        echo "$repo_name" > /tmp/repo_name
    else
        prompt_user "Enter custom clone directory:" clone_dir
        # Expand tilde
        clone_dir="${clone_dir/#\~/$HOME}"
        echo "$repo_url" > /tmp/repo_url
        echo "$clone_dir" > /tmp/clone_dir
        echo "$repo_name" > /tmp/repo_name
    fi
}

# Clone the repository
clone_repository() {
    print_header "Cloning Repository"
    
    local repo_url clone_dir repo_name
    repo_url=$(cat /tmp/repo_url)
    clone_dir=$(cat /tmp/clone_dir)
    repo_name=$(cat /tmp/repo_name)
    
    if [ -d "$clone_dir" ]; then
        echo "Directory $clone_dir already exists."
        if confirm_action "Remove existing directory and re-clone?"; then
            rm -rf "$clone_dir"
        else
            print_step "Using existing directory"
            return 0
        fi
    fi
    
    # Create parent directory if needed
    local parent_dir
    parent_dir=$(dirname "$clone_dir")
    mkdir -p "$parent_dir"
    
    echo "Cloning $repo_url to $clone_dir..."
    if git clone "$repo_url" "$clone_dir"; then
        print_step "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        echo "Please check:"
        echo "• Repository URL is correct"
        echo "• You have access to the repository"
        echo "• SSH key is properly configured"
        exit 1
    fi
}

# Setup local development environment
setup_local_environment() {
    print_header "Local Development Environment"
    
    local clone_dir repo_name
    clone_dir=$(cat /tmp/clone_dir)
    repo_name=$(cat /tmp/repo_name)
    
    cd "$clone_dir"
    
    # Check for common configuration files
    local has_config=false
    
    if [ -f "package.json" ]; then
        echo "Found package.json - Node.js project detected"
        if command -v node >/dev/null 2>&1; then
            if confirm_action "Install Node.js dependencies?"; then
                if command -v pnpm >/dev/null 2>&1; then
                    pnpm install
                elif command -v yarn >/dev/null 2>&1; then
                    yarn install
                else
                    npm install
                fi
                print_step "Node.js dependencies installed"
            fi
        else
            print_warning "Node.js not found - please install via asdf or other means"
        fi
        has_config=true
    fi
    
    if [ -f "go.mod" ]; then
        echo "Found go.mod - Go project detected"
        if command -v go >/dev/null 2>&1; then
            if confirm_action "Download Go dependencies?"; then
                go mod download
                print_step "Go dependencies downloaded"
            fi
        else
            print_warning "Go not found - please install via asdf"
        fi
        has_config=true
    fi
    
    if [ -f "Cargo.toml" ]; then
        echo "Found Cargo.toml - Rust project detected"
        if command -v cargo >/dev/null 2>&1; then
            if confirm_action "Build Rust project?"; then
                cargo build
                print_step "Rust project built"
            fi
        else
            print_warning "Rust not found - please install via asdf"
        fi
        has_config=true
    fi
    
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "Python project detected"
        if command -v python >/dev/null 2>&1; then
            if confirm_action "Set up Python virtual environment?"; then
                python -m venv venv
                source venv/bin/activate
                if [ -f "requirements.txt" ]; then
                    pip install -r requirements.txt
                elif [ -f "pyproject.toml" ]; then
                    pip install .
                fi
                print_step "Python environment set up"
            fi
        else
            print_warning "Python not found - please install via asdf"
        fi
        has_config=true
    fi
    
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        echo "Found Docker Compose configuration"
        if command -v docker >/dev/null 2>&1; then
            if confirm_action "Start Docker services?"; then
                docker compose up -d
                print_step "Docker services started"
            fi
        else
            print_warning "Docker not found"
        fi
        has_config=true
    fi
    
    if [ -f ".tool-versions" ]; then
        echo "Found .tool-versions - asdf configuration detected"
        if command -v asdf >/dev/null 2>&1; then
            if confirm_action "Install asdf tools from .tool-versions?"; then
                # Add plugins if they don't exist
                awk '{print $1}' .tool-versions | while read -r plugin; do
                    asdf plugin add "$plugin" 2>/dev/null || true
                done
                asdf install
                print_step "asdf tools installed"
            fi
        else
            print_warning "asdf not found"
        fi
        has_config=true
    fi
    
    # Check for README or documentation
    if [ -f "README.md" ]; then
        echo ""
        echo "Found README.md with project documentation"
        if confirm_action "View README.md?"; then
            if command -v bat >/dev/null 2>&1; then
                bat README.md
            elif command -v less >/dev/null 2>&1; then
                less README.md
            else
                cat README.md
            fi
        fi
    fi
    
    if [ "$has_config" = false ]; then
        print_warning "No standard configuration files detected"
        echo "You may need to manually set up the development environment"
    fi
}

# Run tests if available
run_tests() {
    print_header "Testing Setup"
    
    local clone_dir
    clone_dir=$(cat /tmp/clone_dir)
    cd "$clone_dir"
    
    local test_command=""
    
    if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
        if npm run | grep -q "test"; then
            test_command="npm test"
        fi
    fi
    
    if [ -f "go.mod" ] && command -v go >/dev/null 2>&1; then
        test_command="go test ./..."
    fi
    
    if [ -f "Cargo.toml" ] && command -v cargo >/dev/null 2>&1; then
        test_command="cargo test"
    fi
    
    if [ -f "Makefile" ] && command -v make >/dev/null 2>&1; then
        if grep -q "^test:" Makefile; then
            test_command="make test"
        fi
    fi
    
    if [ -n "$test_command" ]; then
        if confirm_action "Run tests to verify setup? ($test_command)"; then
            if $test_command; then
                print_step "Tests passed"
            else
                print_warning "Some tests failed - this might be expected for initial setup"
            fi
        fi
    else
        echo "No standard test command found"
    fi
}

# Cleanup temporary files
cleanup() {
    rm -f /tmp/repo_url /tmp/clone_dir /tmp/repo_name
}

# Main execution
main() {
    print_header "Company Repository Setup"
    echo "This script will help you clone and set up your company repository."
    echo ""
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    check_prerequisites
    get_repo_info
    clone_repository
    setup_local_environment
    run_tests
    
    local clone_dir repo_name
    clone_dir=$(cat /tmp/clone_dir)
    repo_name=$(cat /tmp/repo_name)
    
    print_header "Setup Complete!"
    echo "Your repository is ready at: $clone_dir"
    echo ""
    echo "To start working:"
    echo "  cd $clone_dir"
    echo ""
    echo "Happy coding! 🚀"
}

# Run main function
main "$@"