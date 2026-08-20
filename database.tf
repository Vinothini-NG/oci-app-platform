# ============================================================
# AUTONOMOUS DATABASE
# ============================================================

resource "oci_database_autonomous_database" "autonomous_db" {
  compartment_id = var.compartment_id

  display_name = "${var.app_name}-${var.environment}-database"

  db_name = var.db_name

  db_workload = "OLTP"

  admin_password = var.adb_admin_password

  is_free_tier = true
}