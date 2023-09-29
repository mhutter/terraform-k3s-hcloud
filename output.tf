output "server_internal_ip" {
  value = local.server_ip
}
output "server_ip" {
  value = hcloud_server.server.ipv4_address
}
