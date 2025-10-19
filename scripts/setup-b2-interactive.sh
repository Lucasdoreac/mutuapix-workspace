#!/bin/bash
#
# Backblaze B2 Interactive Setup Script
#
# This script guides you through configuring Backblaze B2 for off-site backups.
# It generates the .env configuration lines ready to paste into production.
#
# Usage:
#   ./setup-b2-interactive.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║      Backblaze B2 Setup - Interactive Configuration       ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Account Creation
echo -e "${GREEN}Step 1: Create Backblaze B2 Account${NC}"
echo ""
echo "1. Open: https://www.backblaze.com/b2/sign-up.html"
echo "2. Fill in your details and create account"
echo "3. Verify your email"
echo ""
read -p "Have you created your B2 account? (y/n): " account_created

if [[ "$account_created" != "y" ]]; then
    echo -e "${YELLOW}Please create your account first, then run this script again.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}✓ Account created${NC}"
echo ""

# Step 2: Bucket Creation
echo -e "${GREEN}Step 2: Create B2 Bucket${NC}"
echo ""
echo "1. Log in to B2: https://secure.backblaze.com/user_signin.htm"
echo "2. Go to: B2 Cloud Storage → Buckets → Create a Bucket"
echo "3. Bucket settings:"
echo "   - Name: mutuapix-backups"
echo "   - Files in Bucket: Private"
echo "   - Encryption: Disable (saves cost)"
echo "   - Object Lock: Disable"
echo ""
read -p "Have you created the bucket 'mutuapix-backups'? (y/n): " bucket_created

if [[ "$bucket_created" != "y" ]]; then
    echo -e "${YELLOW}Please create the bucket first, then run this script again.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}✓ Bucket created${NC}"
echo ""

# Step 3: Application Key
echo -e "${GREEN}Step 3: Create Application Key${NC}"
echo ""
echo "1. Go to: B2 Cloud Storage → Application Keys → Add New Key"
echo "2. Key settings:"
echo "   - Name: mutuapix-api-backup"
echo "   - Bucket: mutuapix-backups"
echo "   - Access: Read and Write"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: The key is shown ONLY ONCE!${NC}"
echo ""
read -p "Press Enter when you're on the 'Add New Key' screen..."

echo ""
echo "After creating the key, you'll see:"
echo "  - keyID: (looks like: 005a1b2c3d4e5f6g7h8i9j)"
echo "  - applicationKey: (looks like: K005AbCdEfGhIjKlMnOpQrStUvWxYz1234567890)"
echo ""

# Collect credentials
read -p "Enter your keyID: " key_id
read -p "Enter your applicationKey: " app_key

if [[ -z "$key_id" ]] || [[ -z "$app_key" ]]; then
    echo -e "${RED}Error: Both keyID and applicationKey are required${NC}"
    exit 1
fi

# Get region
echo ""
echo -e "${GREEN}Step 4: Select Region${NC}"
echo ""
echo "Which region did you create the bucket in?"
echo "  1) US West (us-west-001) - Recommended"
echo "  2) US West (us-west-002)"
echo "  3) EU Central (eu-central-003)"
echo ""
read -p "Enter choice (1-3): " region_choice

case $region_choice in
    1)
        region="us-west-001"
        endpoint="https://s3.us-west-001.backblazeb2.com"
        ;;
    2)
        region="us-west-002"
        endpoint="https://s3.us-west-002.backblazeb2.com"
        ;;
    3)
        region="eu-central-003"
        endpoint="https://s3.eu-central-003.backblazeb2.com"
        ;;
    *)
        echo -e "${RED}Invalid choice. Using default: us-west-001${NC}"
        region="us-west-001"
        endpoint="https://s3.us-west-001.backblazeb2.com"
        ;;
esac

echo ""
echo -e "${GREEN}✓ Region selected: $region${NC}"
echo ""

# Generate configuration
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Configuration Complete! ✓${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Add these lines to your production .env file:${NC}"
echo ""
echo -e "${BLUE}# Backblaze B2 Off-Site Backup Configuration${NC}"
cat << EOF

# Enable off-site backups
BACKUP_OFFSITE_ENABLED=true
BACKUP_OFFSITE_DISK=s3
BACKUP_OFFSITE_PATH=backups/database/

# B2 Credentials (S3-compatible)
AWS_ACCESS_KEY_ID=$key_id
AWS_SECRET_ACCESS_KEY=$app_key
AWS_DEFAULT_REGION=$region
AWS_BUCKET=mutuapix-backups
AWS_ENDPOINT=$endpoint
AWS_USE_PATH_STYLE_ENDPOINT=true

# Retention Policy
BACKUP_OFFSITE_DAILY_RETENTION=30
BACKUP_OFFSITE_WEEKLY_RETENTION=12
BACKUP_OFFSITE_MONTHLY_RETENTION=12

# Backup Verification
BACKUP_VERIFICATION_ENABLED=true
BACKUP_MIN_SIZE_MB=1
BACKUP_MAX_SIZE_MB=5000
EOF

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Save to file
config_file="b2-config-$(date +%Y%m%d-%H%M%S).txt"
cat > "$config_file" << EOF
# Backblaze B2 Configuration
# Generated: $(date)

BACKUP_OFFSITE_ENABLED=true
BACKUP_OFFSITE_DISK=s3
BACKUP_OFFSITE_PATH=backups/database/
AWS_ACCESS_KEY_ID=$key_id
AWS_SECRET_ACCESS_KEY=$app_key
AWS_DEFAULT_REGION=$region
AWS_BUCKET=mutuapix-backups
AWS_ENDPOINT=$endpoint
AWS_USE_PATH_STYLE_ENDPOINT=true
BACKUP_OFFSITE_DAILY_RETENTION=30
BACKUP_OFFSITE_WEEKLY_RETENTION=12
BACKUP_OFFSITE_MONTHLY_RETENTION=12
BACKUP_VERIFICATION_ENABLED=true
BACKUP_MIN_SIZE_MB=1
BACKUP_MAX_SIZE_MB=5000
EOF

echo -e "${GREEN}✓ Configuration saved to: $config_file${NC}"
echo ""

# Next steps
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. SSH to production backend:"
echo "   ${BLUE}ssh root@49.13.26.142${NC}"
echo ""
echo "2. Edit .env file:"
echo "   ${BLUE}nano /var/www/mutuapix-api/.env${NC}"
echo ""
echo "3. Paste the configuration above (or from $config_file)"
echo ""
echo "4. Clear config cache:"
echo "   ${BLUE}php artisan config:clear${NC}"
echo "   ${BLUE}php artisan config:cache${NC}"
echo ""
echo "5. Test backup upload:"
echo "   ${BLUE}php artisan db:backup --compress${NC}"
echo ""
echo "6. Verify in B2 dashboard:"
echo "   ${BLUE}https://secure.backblaze.com/b2_buckets.htm${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Setup Complete! 🚀${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Store your credentials securely!${NC}"
echo -e "Saved to: ${BLUE}$config_file${NC}"
echo -e "Add to: ${BLUE}1Password, Vault, or secure password manager${NC}"
echo ""
