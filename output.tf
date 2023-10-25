output "controller_internal_ip" {
  value = local.controller_ip
}
output "controller_ip" {
  value = hcloud_server.controller.ipv4_address
}
output "lb_ipv4" {
  value = hcloud_load_balancer.ingress.ipv4
}
output "lb_ipv6" {
  value = hcloud_load_balancer.ingress.ipv6
}
