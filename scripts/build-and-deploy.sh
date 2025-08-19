#!/bin/bash

# Build and Deploy Script for casey.click website
# This script provides a complete workflow for building and deploying the React app

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATIC_FE_DIR="$PROJECT_ROOT/static-fe"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo -e "${CYAN}🚀 Casey.click Build and Deploy Workflow${NC}"
echo -e "${CYAN}=========================================${NC}"

# Function to print colored output
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "\n${CYAN}📋 Step $1: $2${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_step 1 "Checking prerequisites"
    
    # Check Node.js
    if ! command_exists node; then
        log_error "Node.js is not installed"
        exit 1
    fi
    log_success "Node.js is installed ($(node --version))"
    
    # Check npm
    if ! command_exists npm; then
        log_error "npm is not installed"
        exit 1
    fi
    log_success "npm is installed ($(npm --version))"
    
    # Check AWS CLI
    if ! command_exists aws; then
        log_error "AWS CLI is not installed"
        log_info "Install from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    log_success "AWS CLI is installed ($(aws --version 2>&1 | head -n1))"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials are not configured"
        log_info "Run: aws configure"
        exit 1
    fi
    log_success "AWS credentials are configured"
    
    # Check if we're in the right directory
    if [[ ! -d "$STATIC_FE_DIR" ]]; then
        log_error "static-fe directory not found at $STATIC_FE_DIR"
        exit 1
    fi
    log_success "Project structure verified"
}

# Install dependencies
install_dependencies() {
    log_step 2 "Installing dependencies"
    
    cd "$STATIC_FE_DIR"
    
    if [[ ! -d "node_modules" ]] || [[ "package.json" -nt "node_modules" ]]; then
        log_info "Installing npm dependencies..."
        npm install
        log_success "Dependencies installed"
    else
        log_success "Dependencies are up to date"
    fi
}

# Run linting
run_linting() {
    log_step 3 "Running linting"
    
    cd "$STATIC_FE_DIR"
    
    if npm run lint >/dev/null 2>&1; then
        log_success "Linting passed"
    else
        log_warning "Linting issues found, but continuing..."
        npm run lint || true
    fi
}

# Build the application
build_application() {
    log_step 4 "Building application"
    
    cd "$STATIC_FE_DIR"
    
    # Clean previous build
    if [[ -d "dist" ]]; then
        rm -rf dist
        log_info "Cleaned previous build"
    fi
    
    # Build the application
    log_info "Building React application..."
    npm run build
    
    # Verify build output
    if [[ -f "dist/index.html" ]]; then
        log_success "Build completed successfully"
        
        # Show build stats
        log_info "Build statistics:"
        du -sh dist/
        find dist/ -name "*.js" -o -name "*.css" -o -name "*.html" | wc -l | xargs echo "  Files:"
    else
        log_error "Build failed - index.html not found"
        exit 1
    fi
}

# Deploy to AWS
deploy_to_aws() {
    local dry_run=$1
    local step_num=$2
    
    if [[ "$dry_run" == "true" ]]; then
        log_step "$step_num" "Deployment preview (dry run)"
    else
        log_step "$step_num" "Deploying to AWS"
    fi
    
    cd "$PROJECT_ROOT"
    
    if [[ "$dry_run" == "true" ]]; then
        node scripts/deploy.js --dry-run
    else
        node scripts/deploy.js
    fi
}

# Show deployment information
show_info() {
    log_step 6 "Deployment Information"
    
    echo -e "\n${CYAN}🌐 Your website is deployed at:${NC}"
    echo -e "   ${GREEN}https://www.casey.click${NC} (when DNS propagates)"
    echo -e "   ${GREEN}https://casey.click${NC} (redirects to www)"
    echo -e "   ${GREEN}https://d1sk918hgzx1la.cloudfront.net${NC} (CloudFront direct)"
    
    echo -e "\n${CYAN}🔧 Management URLs:${NC}"
    echo -e "   S3 Bucket: ${BLUE}https://s3.console.aws.amazon.com/s3/buckets/casey-click-website-prod${NC}"
    echo -e "   CloudFront: ${BLUE}https://console.aws.amazon.com/cloudfront/v3/home#/distributions/E20H6JIYEH8AXW${NC}"
    echo -e "   Route53: ${BLUE}https://console.aws.amazon.com/route53/v2/hostedzones#ListRecordSets/Z071783729IOP1J69O6V1${NC}"
    
    echo -e "\n${CYAN}📝 Useful commands:${NC}"
    echo -e "   Quick deploy: ${YELLOW}npm run deploy${NC} (from static-fe/)"
    echo -e "   Deploy preview: ${YELLOW}npm run deploy:dry-run${NC} (from static-fe/)"
    echo -e "   Full workflow: ${YELLOW}./scripts/build-and-deploy.sh${NC}"
    echo -e "   Dry run: ${YELLOW}./scripts/build-and-deploy.sh --dry-run${NC}"
}

# Main function
main() {
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--help]"
                echo ""
                echo "Options:"
                echo "  --dry-run    Preview deployment without making changes"
                echo "  --help       Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}🧪 DRY RUN MODE - No changes will be made${NC}"
    fi
    
    # Execute workflow
    check_prerequisites
    install_dependencies
    run_linting
    build_application
    deploy_to_aws "$dry_run" 5
    show_info
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "\n${GREEN}🧪 Dry run completed successfully!${NC}"
        echo -e "${YELLOW}Run without --dry-run to actually deploy${NC}"
    else
        echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
        echo -e "${YELLOW}Your website will be available once DNS propagates (up to 48 hours)${NC}"
    fi
}

# Run main function with all arguments
main "$@"
