output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = oci_core_instance.bastion_host.public_ip
}

output "application_private_ip" {
  description = "Private IP address of the Application Node"
  value       = oci_core_instance.application_node1.private_ip
}

output "load_balancer_ip" {
  description = "Public IP address of the Load Balancer"
  value       = oci_load_balancer_load_balancer.load_balancer.ip_address_details[0].ip_address
}

output "database_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.autonomous_db.id
}

output "database_display_name" {
  description = "Display name of the Autonomous Database"
  value       = oci_database_autonomous_database.autonomous_db.display_name
}