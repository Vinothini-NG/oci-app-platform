# ============================================================
# VCN
# ============================================================

resource "oci_core_vcn" "main_vcn" {
  compartment_id = var.compartment_id

  cidr_block = "10.0.0.0/16"

  display_name = "${var.app_name}-${var.environment}-vcn"
  dns_label    = "${var.app_name}${var.environment}"
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "oci_core_internet_gateway" "main_igw" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-igw"

  enabled = true
}


# ============================================================
# PUBLIC ROUTE TABLE
# ============================================================

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-public-rt"

  route_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    network_entity_id = oci_core_internet_gateway.main_igw.id
  }
}


# ============================================================
# PUBLIC SECURITY LIST
# ============================================================

resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-public-security-list"


  # Allow all outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }


  # Allow HTTP
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 80
      max = 80
    }
  }


  # Allow HTTPS
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 443
      max = 443
    }
  }


  # Allow SSH
  # For production, restrict source to your trusted IP.
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 22
      max = 22
    }
  }


  # Allow ICMP
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"

    icmp_options {
      type = 3
    }
  }
}


# ============================================================
# PUBLIC SUBNET
# ============================================================

resource "oci_core_subnet" "public_subnet" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  cidr_block = "10.0.1.0/24"

  display_name = "${var.app_name}-${var.environment}-public-subnet"

  dns_label = "publicsubnet"

  route_table_id = oci_core_route_table.public_rt.id

  security_list_ids = [
    oci_core_security_list.public_security_list.id
  ]

  # Resources in this subnet can receive public IPs.
  prohibit_public_ip_on_vnic = false
}


# ============================================================
# NAT GATEWAY
# ============================================================

resource "oci_core_nat_gateway" "private_nat_gateway" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-nat-gateway"
}


# ============================================================
# OCI SERVICES DATA SOURCE
# ============================================================

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}


# ============================================================
# SERVICE GATEWAY
# ============================================================

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-service-gateway"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}


# ============================================================
# PRIVATE ROUTE TABLE
# ============================================================

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-private-rt"


  # Private resources can access the internet through NAT.
  route_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    network_entity_id = oci_core_nat_gateway.private_nat_gateway.id
  }


  # Allow access to OCI services through Service Gateway.
  route_rules {
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"

    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}


# ============================================================
# PRIVATE SECURITY LIST
# ============================================================

resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  display_name = "${var.app_name}-${var.environment}-private-security-list"


  # Allow outbound traffic.
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }


  # Allow SSH from inside the VCN.
  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "6"

    tcp_options {
      min = 22
      max = 22
    }
  }


  # Allow HTTP from inside the VCN.
  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "6"

    tcp_options {
      min = 80
      max = 80
    }
  }


  # Allow HTTPS from inside the VCN.
  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "6"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow application traffic from Load Balancer / VCN
  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "6"

    tcp_options {
      min = 3000
      max = 3000
    }
  }


  # Allow ICMP inside the VCN.
  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "1"

    icmp_options {
      type = 3
    }
  }
}


# ============================================================
# PRIVATE SUBNET
# ============================================================

resource "oci_core_subnet" "private_subnet" {
  compartment_id = var.compartment_id

  vcn_id = oci_core_vcn.main_vcn.id

  cidr_block = "10.0.2.0/24"

  display_name = "${var.app_name}-${var.environment}-private-subnet"

  dns_label = "privatesubnet"

  route_table_id = oci_core_route_table.private_rt.id

  security_list_ids = [
    oci_core_security_list.private_security_list.id
  ]

  # Private resources cannot receive public IP addresses.
  prohibit_public_ip_on_vnic = true
}