# ============================================================
# LOAD BALANCER
# ============================================================

resource "oci_load_balancer_load_balancer" "load_balancer" {
  compartment_id = var.compartment_id

  display_name = "${var.app_name}-${var.environment}-load-balancer"

  shape = "flexible"

  is_private = false

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }

  subnet_ids = [
    oci_core_subnet.public_subnet.id
  ]
}


# ============================================================
# BACKEND SET
# ============================================================

resource "oci_load_balancer_backend_set" "application_backend_set" {
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id

  name = "${var.app_name}-${var.environment}-backend-set"

  policy = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = 3000
    url_path          = "/"
    return_code       = 200
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
}


# ============================================================
# APPLICATION NODE AS BACKEND
# ============================================================

resource "oci_load_balancer_backend" "application_node1_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id

  backendset_name = oci_load_balancer_backend_set.application_backend_set.name

  ip_address = oci_core_instance.application_node1.private_ip

  port = 3000

  backup  = false
  drain   = false
  offline = false

  weight = 1
}


# ============================================================
# HTTP LISTENER
# ============================================================

resource "oci_load_balancer_listener" "http_listener" {
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id

  name = "${var.app_name}-${var.environment}-http-listener"

  default_backend_set_name = oci_load_balancer_backend_set.application_backend_set.name

  port = 80

  protocol = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds = 60
  }
}