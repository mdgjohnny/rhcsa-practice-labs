# RHCSA Practice Labs - Setup Guide

This guide explains how to set up the RHCSA Practice Labs with cloud VMs.

## Quick Start (Local Only)

If you just want to run the grader locally without cloud VMs:

```bash
# Clone and setup
git clone https://github.com/yourusername/rhcsa-practice-labs.git
cd rhcsa-practice-labs
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run the app
python api/app.py

# Open http://localhost:8080
```

This runs the grader locally - tasks will be checked on your local machine.

---

## Full Setup with Cloud VMs

For the complete experience with real cloud VMs, follow these steps.

### Prerequisites

1. **Oracle Cloud Account** (Free Tier)
   - Sign up at https://www.oracle.com/cloud/free/
   - Free tier includes 2 always-free AMD VMs (perfect for this lab)

2. **Required Tools**
   ```bash
   # Terraform
   # macOS
   brew install terraform
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_*.zip && sudo mv terraform /usr/local/bin/

   # OCI CLI
   pip install oci-cli

   # Python 3.8+
   python3 --version
   ```

### Step 1: Configure OCI CLI

1. Log into OCI Console: https://cloud.oracle.com

2. Generate API Key:
   - Click your profile icon (top right) → User Settings
   - Under "Resources" → API Keys → Add API Key
   - Download the private key file
   - Copy the configuration snippet shown

3. Create OCI config file:
   ```bash
   mkdir -p ~/.oci
   # Paste the configuration snippet into ~/.oci/config
   # Move your private key to ~/.oci/oci_api_key.pem
   chmod 600 ~/.oci/oci_api_key.pem
   ```

4. Test the configuration:
   ```bash
   oci iam tenancy get --query 'data.name' --raw-output
   # Should print your tenancy name
   ```

### Step 2: Run Setup Script

```bash
cd rhcsa-practice-labs
./scripts/setup-oci.sh
```

This script:
- Checks prerequisites
- Verifies OCI authentication
- Creates `infra/terraform.tfvars` from your OCI config
- Initializes Terraform

### Step 3: Start the Application

```bash
source .venv/bin/activate
python api/app_socketio.py
```

Open http://localhost:8080 in your browser.

### Step 4: Create Cloud Session

1. Go to **Settings** in the web UI
2. Click **Create Cloud Session**
3. Wait ~2 minutes for VMs to provision
4. Once ready, the terminal will connect automatically

---

## Manual Terraform Setup

If you prefer to configure Terraform manually:

1. Copy the example config:
   ```bash
   cp infra/terraform.tfvars.example infra/terraform.tfvars
   ```

2. Edit `infra/terraform.tfvars`:
   ```hcl
   tenancy_ocid     = "ocid1.tenancy.oc1..aaaa..."
   user_ocid        = "ocid1.user.oc1..aaaa..."
   fingerprint      = "aa:bb:cc:dd:..."
   private_key_path = "~/.oci/oci_api_key.pem"
   region           = "us-ashburn-1"  # or your region
   compartment_ocid = "ocid1.compartment.oc1..aaaa..."  # or tenancy OCID
   ```

3. Initialize and validate:
   ```bash
   cd infra
   terraform init
   terraform validate
   ```

---

## Environment Variables (Alternative)

Instead of `terraform.tfvars`, you can use environment variables:

```bash
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..."
export TF_VAR_user_ocid="ocid1.user.oc1..."
export TF_VAR_fingerprint="aa:bb:cc:..."
export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
export TF_VAR_region="us-ashburn-1"
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..."
```

---

## Troubleshooting

### "Service error: NotAuthenticated"
- Check that `~/.oci/config` exists and is correct
- Verify the API key fingerprint matches OCI Console
- Ensure private key permissions: `chmod 600 ~/.oci/oci_api_key.pem`

### "Out of capacity"
- OCI Free Tier has limited availability
- Try a different availability domain
- Try a different region

### "Shape not found"
- The free tier shape `VM.Standard.E2.1.Micro` may not be available
- Check OCI Console for available shapes in your region

### Terraform state issues
- Each session uses isolated workspace in `workspaces/`
- To reset: delete the session from the UI or `rm -rf workspaces/<session_id>`

---

## Architecture Notes

- **VMs**: 2x Oracle Linux 8 (RHEL-compatible)
- **Networking**: VCN with public subnet, security lists allow SSH
- **Session Timeout**: 30 minutes (auto-terminates)
- **SSH Keys**: Auto-generated per session, stored in SQLite DB

---

## Alternative: Local VMs with Vagrant

If you can't use OCI, you can use local VMs:

```bash
# Install Vagrant and VirtualBox
vagrant up

# Configure the app to use local VMs
cp config.example config
# Edit config with local VM IPs
```

See `Vagrantfile` for the VM configuration.
