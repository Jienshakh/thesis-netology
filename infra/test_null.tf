resource "null_resource" "atlantis_test" {
  triggers = {
    timestamp = timestamp()
  }
}