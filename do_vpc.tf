# Digital Ocean VPC and Gateway Configuration

# Lookup for SSH key
data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_name
}

# VPC in Digital Ocean
resource "digitalocean_vpc" "main" {
  name        = "hybrid-vpc"
  region      = var.do_region
  ip_range    = var.do_vpc_cidr
  description = "VPC for hybrid infrastructure with AWS"
}

# Create a Droplet to use for VPN connection
resource "digitalocean_droplet" "vpn_gateway" {
  name     = "vpn-gateway"
  size     = "s-1vcpu-2gb" # Adjust as needed
  image    = "ubuntu-22-04-x64"
  region   = var.do_region
  vpc_uuid = digitalocean_vpc.main.id
  ssh_keys = [data.digitalocean_ssh_key.main.id]

  # Basic setup script for the VPN gateway
  user_data = <<-EOF
    #!/bin/bash
    apt-get update && apt-get upgrade -y
    apt-get install -y strongswan strongswan-pki libcharon-extra-plugins

    # Create a file with instructions for manual IPsec configuration
    cat > /root/vpn-setup-instructions.txt << EOT
    Transit Gateway IPsec VPN Setup Instructions

    This droplet will be used to establish a VPN connection to the AWS Transit Gateway.

    To complete the setup:

    1. Get the Transit Gateway Attachment information from AWS:
       - Transit Gateway ID
       - Customer Gateway IP (this Droplet's public IP)

    2. Configure IPsec/strongSwan with the connection details from AWS

    3. Set up routing to ensure traffic between the VPCs is properly routed

    See the AWS documentation for detailed steps:
    https://docs.aws.amazon.com/vpn/latest/s2svpn/SetUpVPNConnections.html
    EOT

    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-vpn.conf
    sysctl -p /etc/sysctl.d/99-vpn.conf
  EOF

  tags = ["vpn", "aws-connectivity"]
}

# Create a reserved IP for the VPN gateway
resource "digitalocean_reserved_ip" "vpn_ip" {
  region     = var.do_region
  droplet_id = digitalocean_droplet.vpn_gateway.id
}

# Create a firewall allowing traffic between AWS and Digital Ocean
resource "digitalocean_firewall" "vpc_interconnection" {
  name = "allow-aws-traffic"

  # Apply to the VPN gateway droplet
  droplet_ids = [digitalocean_droplet.vpn_gateway.id]

  # Allow all incoming traffic from AWS VPC (IKE and IPsec for VPN)
  inbound_rule {
    protocol         = "udp"
    port_range       = "500"
    source_addresses = ["0.0.0.0/0"] # For IKE - should be restricted in production
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "4500"
    source_addresses = ["0.0.0.0/0"] # For IPsec NAT-T - should be restricted in production
  }

  # Note: Digital Ocean doesn't support ESP protocol directly
  # We'll need to enable this at the OS level with iptables
  # on the VPN gateway

  # Allow SSH for management
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"] # Should be restricted in production
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }
}
