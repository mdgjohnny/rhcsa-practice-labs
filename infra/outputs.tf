# =============================================================================
# Outputs
# =============================================================================

output "session_id" {
  description = "Session identifier"
  value       = var.session_id
}

output "node1_public_ip" {
  description = "Public IP of node1 (rhcsa1)"
  value       = oci_core_instance.node1.public_ip
}

output "node1_private_ip" {
  description = "Private IP of node1 (rhcsa1)"
  value       = oci_core_instance.node1.private_ip
}

output "node2_public_ip" {
  description = "Public IP of node2 (rhcsa2)"
  value       = oci_core_instance.node2.public_ip
}

output "node2_private_ip" {
  description = "Private IP of node2 (rhcsa2)"
  value       = oci_core_instance.node2.private_ip
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.practice_vcn.id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = oci_core_subnet.practice_subnet.id
}

# SSH connection info
output "ssh_private_key" {
  description = "Generated SSH private key (only if no public key was provided)"
  value       = local.ssh_private_key
  sensitive   = true
}

output "ssh_connection_node1" {
  description = "SSH connection command for node1"
  value       = "ssh -i <private_key> opc@${oci_core_instance.node1.public_ip}"
}

output "ssh_connection_node2" {
  description = "SSH connection command for node2"
  value       = "ssh -i <private_key> opc@${oci_core_instance.node2.public_ip}"
}

# Instance OCIDs (for lifecycle management)
output "node1_ocid" {
  description = "OCID of node1 instance"
  value       = oci_core_instance.node1.id
}

output "node2_ocid" {
  description = "OCID of node2 instance"
  value       = oci_core_instance.node2.id
}

# Full connection info as JSON (for API consumption)
output "session_info" {
  description = "Complete session information as JSON"
  value = jsonencode({
    session_id = var.session_id
    nodes = {
      node1 = {
        hostname   = "rhcsa1"
        public_ip  = oci_core_instance.node1.public_ip
        private_ip = oci_core_instance.node1.private_ip
        ocid       = oci_core_instance.node1.id
      }
      node2 = {
        hostname   = "rhcsa2"
        public_ip  = oci_core_instance.node2.public_ip
        private_ip = oci_core_instance.node2.private_ip
        ocid       = oci_core_instance.node2.id
      }
    }
    network = {
      vcn_id    = oci_core_vcn.practice_vcn.id
      subnet_id = oci_core_subnet.practice_subnet.id
    }
  })
}
