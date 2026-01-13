# =============================================================================
# OCI Authentication
# =============================================================================

variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user calling the API"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint for the key pair being used"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI region (e.g., us-ashburn-1, eu-frankfurt-1)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# =============================================================================
# Compute Configuration
# =============================================================================

variable "instance_shape" {
  description = "Shape of the compute instance"
  type        = string
  default     = "VM.Standard.A1.Flex"  # ARM - cheapest (~$0.01/OCPU/hr)
}

variable "instance_ocpus" {
  description = "Number of OCPUs (for flex shapes)"
  type        = number
  default     = 1  # 1 OCPU is plenty for RHCSA tasks
}

variable "instance_memory_gb" {
  description = "Memory in GB (for flex shapes)"
  type        = number
  default     = 4  # 4GB needed for container tasks
}

variable "use_preemptible" {
  description = "Use preemptible (spot) instances for ~50% cost savings. May be reclaimed with 30s notice. ALWAYS USE THIS."
  type        = bool
  default     = true  # NEVER change this to false
}

variable "os_image_id" {
  description = "OCID of the OS image (leave empty to use latest Oracle Linux 8)"
  type        = string
  default     = ""
}

# =============================================================================
# Session Configuration
# =============================================================================

variable "session_id" {
  description = "Unique session identifier"
  type        = string
}

variable "session_timeout_minutes" {
  description = "Session timeout in minutes"
  type        = number
  default     = 30
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (optional - will generate if not provided)"
  type        = string
  default     = ""
}
