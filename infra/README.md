# RHCSA Practice Labs - OCI Infrastructure

This directory contains Terraform configurations to provision Oracle Cloud Infrastructure resources for RHCSA practice sessions.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Oracle Cloud Infrastructure                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  VCN (10.0.0.0/16)                                  │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  Public Subnet (10.0.1.0/24)                │    │   │
│  │  │  ┌──────────────┐    ┌──────────────┐      │    │   │
│  │  │  │   rhcsa1     │    │   rhcsa2     │      │    │   │
│  │  │  │  10.0.1.11   │◄──►│  10.0.1.12   │      │    │   │
│  │  │  │  (node1)     │    │  (node2)     │      │    │   │
│  │  │  └──────────────┘    └──────────────┘      │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Oracle Cloud Account** with Always Free tier
2. **Terraform** >= 1.0.0
3. **OCI CLI** (optional, but helpful)

## Getting OCI Credentials

### Step 1: Get Tenancy OCID
1. Log in to [Oracle Cloud Console](https://cloud.oracle.com)
2. Click your profile icon (top right) → **Tenancy: <name>**
3. Copy the **OCID** (starts with `ocid1.tenancy.oc1..`)

### Step 2: Get User OCID
1. Click your profile icon → **User Settings**
2. Copy the **OCID** (starts with `ocid1.user.oc1..`)

### Step 3: Create API Key
1. In User Settings, scroll to **API Keys**
2. Click **Add API Key**
3. Select **Generate API Key Pair**
4. Click **Download Private Key** → save as `~/.oci/oci_api_key.pem`
5. Click **Add**
6. Copy the **Configuration File Preview** (contains fingerprint)

```bash
# Set correct permissions
chmod 600 ~/.oci/oci_api_key.pem
```

### Step 4: Get/Create Compartment OCID
- Use your **Tenancy OCID** for the root compartment, OR
- Create a dedicated compartment:
  1. Go to **Identity & Security** → **Compartments**
  2. Click **Create Compartment**
  3. Name it `rhcsa-practice` and copy the OCID

### Step 5: Choose Region
Pick a region close to you:
- `us-ashburn-1` (US East)
- `us-phoenix-1` (US West)
- `eu-frankfurt-1` (Europe)
- `uk-london-1` (UK)
- `ap-tokyo-1` (Asia Pacific)

## Setup

```bash
cd infra

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your credentials
vim terraform.tfvars

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan
```

## Usage

### Create a Practice Session

```bash
# Create VMs with a unique session ID
terraform apply -var="session_id=practice-$(date +%Y%m%d-%H%M%S)"
```

### Get Connection Info

```bash
# Show outputs
terraform output

# Get SSH private key (if auto-generated)
terraform output -raw ssh_private_key > session_key.pem
chmod 600 session_key.pem

# Connect to node1
ssh -i session_key.pem opc@$(terraform output -raw node1_public_ip)
```

### Destroy Session

```bash
# Clean up all resources
terraform destroy
```

## Free Tier Limits

Oracle Cloud Always Free includes:
- **2x VM.Standard.E2.1.Micro** (AMD, 1 OCPU, 1GB RAM each)
- **4x VM.Standard.A1.Flex** OCPUs total (ARM Ampere, up to 24GB RAM total)
- **200GB total boot volume storage**

For RHCSA practice, the Micro instances are sufficient but tight. Consider:
- Using ARM instances (`VM.Standard.A1.Flex`) for more resources
- Note: ARM is compatible with RHEL/Oracle Linux but some x86-specific tasks may differ

## Troubleshooting

### "Out of capacity"
Free tier instances are limited. Try:
- Different availability domain
- Different region
- Waiting and trying later

### "Authorization failed"
Check your:
- API key is correctly configured
- Private key permissions (`chmod 600`)
- Compartment OCID is correct
- User has required IAM policies

### SSH connection refused
- Wait 2-3 minutes for cloud-init to complete
- Check security list allows port 22
- Verify public IP is assigned
