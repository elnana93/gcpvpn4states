

resource "google_compute_network" "usva_network" {
  name = "usva-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "usva_subnet" {
  name          = "usva-subnet"
  region        = "us-east4"
  network       = google_compute_network.usva_network.self_link
  ip_cidr_range = "192.168.0.0/24"
}

resource "google_compute_firewall" "usva_firewall" {
  name    = "usva-firewall"
  network = google_compute_network.usva_network.self_link

  allow {
    protocol = "tcp"
    #i added 500 and 4500 for my iphone vpn configure
    ports    = ["3389", "500", "4500"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "usva_instance" {
  name         = "usva-instance"
  machine_type = "e2-medium" #"n2-standard-4"- original; #m2-micro -was slow af - ("e2-medium" didnt check yet)
  zone         = "us-east4-b"


  boot_disk {
    initialize_params {
      image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240415"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.usva_subnet.self_link
    network = google_compute_network.usva_network.self_link
    access_config {}
  }
  

  metadata = {
    startup-script = "#Thanks to Remo\n#!/bin/bash\n# Update and install Apache2\necho \"Running startup script. . .\"\napt update\napt install -y apache2\n\n# Start and enable Apache2\nsystemctl start apache2\nsystemctl enable apache2\n\n# GCP Metadata server base URL and header\nMETADATA_URL=\"http://metadata.google.internal/computeMetadata/v1\"\nMETADATA_FLAVOR_HEADER=\"Metadata-Flavor: Google\"\n\n# Use curl to fetch instance metadata\nlocal_ipv4=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/network-interfaces/0/ip\")\nzone=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/zone\")\nproject_id=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/project/project-id\")\nnetwork_tags=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/tags\")\n\n# Create a simple HTML page and include instance details\ncat <<EOF > /var/www/html/index.html\n<html><body>\n<h2>Welcome to your custom website.</h2>\n<h3>Created with a direct input startup script!</h3>\n<p><b>Instance Name:</b> $(hostname -f)</p>\n<p><b>Instance Private IP Address: </b> $local_ipv4</p>\n<p><b>Zone: </b> $zone</p>\n<p><b>Project ID:</b> $project_id</p>\n<p><b>Network Tags:</b> $network_tags</p>\n</body></html>\nEOF"
  }

  tags = ["web"]
}

