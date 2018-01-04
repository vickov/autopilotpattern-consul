bind_addr = "CONTAINERPILOT_CONSUL_IP"
datacenter = "CONSUL_DATACENTER_NAME"
data_dir = "/data/CONTAINERPILOT_CONSUL_IP"
client_addr = "0.0.0.0"
addresses {
  dns = "0.0.0.0"
  http = "0.0.0.0"
}
ports {
  dns = 53
  http = 8500
}
recursors = ["8.8.8.8", "8.8.4.4"]
raft_protocol = 3
disable_update_check = true
disable_host_node_id = true
