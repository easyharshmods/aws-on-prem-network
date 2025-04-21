# AWS Site-to-Site VPN Configuration

# Fetch existing droplet details
data "digitalocean_droplet" "vpn_gateway" {
  id = "490665038" # Replace with your actual droplet ID
}

# Use the data in the customer gateway
resource "aws_customer_gateway" "do_gateway" {
  bgp_asn    = 65000
  ip_address = data.digitalocean_droplet.vpn_gateway.ipv4_address
  type       = "ipsec.1"

  tags = {
    Name = "do-customer-gateway"
  }

  lifecycle {
    create_before_destroy = false
  }

}

# Create the VPN connection
resource "aws_vpn_connection" "main" {
  customer_gateway_id = aws_customer_gateway.do_gateway.id
  transit_gateway_id  = aws_ec2_transit_gateway.tgw.id
  type                = "ipsec.1"
  static_routes_only  = true # Using static routes rather than BGP

  # Define the tunnel options (customize as needed)
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]

  lifecycle {
    create_before_destroy = false
  }

  tags = {
    Name = "aws-do-vpn-connection"
  }
}

# Get the default Transit Gateway route table
data "aws_ec2_transit_gateway_route_table" "default" {
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.tgw.id]
  }
  filter {
    name   = "default-association-route-table"
    values = ["true"]
  }
  depends_on = [aws_ec2_transit_gateway.tgw]
}

# Create a static route in the Transit Gateway route table
resource "aws_ec2_transit_gateway_route" "to_do_vpc" {
  destination_cidr_block         = var.do_vpc_cidr
  transit_gateway_attachment_id  = aws_vpn_connection.main.transit_gateway_attachment_id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.default.id
  depends_on                     = [aws_vpn_connection.main]
}
