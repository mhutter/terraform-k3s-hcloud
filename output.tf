output "server_internal_ip" {
  value = local.server_ip
}
output "server_ip" {
  value = hcloud_server.server.ipv4_address
}
output "lb_ipv4" {
  value = hcloud_load_balancer.ingress.ipv4
}
output "lb_ipv6" {
  value = hcloud_load_balancer.ingress.ipv6
}
