resource "aws_s3_bucket" "backup" {
  bucket = "${local.domain_name}-backup"
  lifecycle {
    ignore_changes = [
      "object_lock_configuration"
    ]
  }
}