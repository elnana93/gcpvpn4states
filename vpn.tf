
# [  0[~32u^B?&g(.+)  ] 



# Create VPN gateways in each region
resource "google_compute_vpn_gateway" "usva_vpn_gateway" {
  name    = "usva-vpn-gateway"
  network = google_compute_network.usva_network.self_link
  region  = "europe-southwest1"
}

resource "google_compute_vpn_gateway" "euro_vpn_gateway" {
  name    = "euro-vpn-gateway"
  network = google_compute_network.private_network.self_link
  region  = "europe-southwest1"
}

# Create VPNs for each network (Not implemented here as it requires external configuration)
# Create Static IPs for each network
resource "google_compute_address" "euro_static_ip" {
  name   = "euro-static-ip"
  region = "europe-southwest1"
}

resource "google_compute_address" "usva_static_ip" {
  name   = "usva-static-ip"
  region = "europe-southwest1"
}

#---VPN Tunnels

resource "google_compute_vpn_tunnel" "usva_to_euro_tunnel" {
  name               = "usva-to-euro-tunnel"
  region             = "europe-southwest1"
  target_vpn_gateway = google_compute_vpn_gateway.usva_vpn_gateway.id
  peer_ip            = google_compute_address.euro_static_ip.address # Euro VPN static IP
  shared_secret      = var.secret                                   # Replace with your shared secret .secret_data?
  ike_version        = 2

  local_traffic_selector  = ["192.168.0.0/24"]
  remote_traffic_selector = ["10.0.0.0/24"]


  depends_on = [

    google_compute_forwarding_rule.usva_esp,
    google_compute_forwarding_rule.usva_udp_500,
    google_compute_forwarding_rule.usva_udp_4500
  ]

}

#route traffic from asia to euro
resource "google_compute_route" "usva_to_euro_route" {
  name                = "usva-to-euro-route"
  network             = google_compute_network.usva_network.self_link
  dest_range          = "10.0.0.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.usva_to_euro_tunnel.id
  priority            = 1000

}


#Fowarding Rule to Link Gatway to Generated IP
resource "google_compute_forwarding_rule" "usva_esp" {
  name        = "usva-esp"
  region      = "europe-southwest1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.usva_static_ip.address
  target      = google_compute_vpn_gateway.usva_vpn_gateway.self_link
}


#UPD 500 traffic Rule
resource "google_compute_forwarding_rule" "usva_udp_500" {
  name        = "rule-2"
  region      = "europe-southwest1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.usva_static_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.usva_vpn_gateway.self_link
}
#>>>

#UDP 4500 traffic rule
resource "google_compute_forwarding_rule" "usva_udp_4500" {
  name        = "rule-3"
  region      = "europe-southwest1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.usva_static_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.usva_vpn_gateway.self_link
}








#---VPN Tunnels #2

resource "google_compute_vpn_tunnel" "euro_to_usva_tunnel" {
  name               = "euro-to-usva-tunnel"
  region             = "europe-southwest1"
  target_vpn_gateway = google_compute_vpn_gateway.euro_vpn_gateway.id
  peer_ip            = google_compute_address.usva_static_ip.address # Euro VPN static IP
  shared_secret      = var.secret                                # Replace with your shared secret .secret_data?
  ike_version        = 2

  local_traffic_selector  = ["10.0.0.0/24"]
  remote_traffic_selector = ["192.168.0.0/24"]


  depends_on = [

    google_compute_forwarding_rule.euro_esp,
    google_compute_forwarding_rule.euro_udp_500,
    google_compute_forwarding_rule.euro_udp_4500
  ]

}

#route traffic from asia to euro
resource "google_compute_route" "euro_to_usva_route" {
  name                = "euro-to-usva-route"
  network             = google_compute_network.private_network.self_link
  dest_range          = "192.168.0.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.euro_to_usva_tunnel.id
  priority            = 1000

}



#Fowarding Rule to Link Gatway to Generated IP
resource "google_compute_forwarding_rule" "euro_esp" {
  name        = "euro-esp"
  region      = "europe-southwest1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.euro_static_ip.address
  target      = google_compute_vpn_gateway.euro_vpn_gateway.self_link
}


#UPD 500 traffic Rule
resource "google_compute_forwarding_rule" "euro_udp_500" {
  name        = "rule-12"
  region      = "europe-southwest1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.euro_static_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.euro_vpn_gateway.self_link
}
#>>>

#UDP 4500 traffic rule
resource "google_compute_forwarding_rule" "euro_udp_4500" {
  name        = "rule-13"
  region      = "europe-southwest1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.euro_static_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.euro_vpn_gateway.self_link
}
