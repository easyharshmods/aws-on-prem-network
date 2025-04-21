# Output values

# AWS VPC outputs
output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "aws_public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.tgw.id
}

# Digital Ocean VPC outputs
output "do_vpc_id" {
  value = digitalocean_vpc.main.id
}

output "do_vpc_cidr" {
  value = digitalocean_vpc.main.ip_range
}

output "do_vpn_gateway_ip" {
  value = digitalocean_reserved_ip.vpn_ip.ip_address
}

# VPN connection outputs
output "vpn_connection_id" {
  value = aws_vpn_connection.main.id
}

output "vpn_tunnel1_address" {
  value = aws_vpn_connection.main.tunnel1_address
}

output "vpn_tunnel1_preshared_key" {
  value     = aws_vpn_connection.main.tunnel1_preshared_key
  sensitive = true
}

output "vpn_tunnel2_address" {
  value = aws_vpn_connection.main.tunnel2_address
}

output "vpn_tunnel2_preshared_key" {
  value     = aws_vpn_connection.main.tunnel2_preshared_key
  sensitive = true
}

# Setup instructions
output "vpn_setup_instructions" {
  value = <<-EOT
    Next steps to complete the VPN setup:

    1. SSH into your Digital Ocean VPN gateway droplet
       ssh root@${digitalocean_reserved_ip.vpn_ip.ip_address}

    2. Configure strongSwan with the following tunnel information:
       - Tunnel 1 Address: ${aws_vpn_connection.main.tunnel1_address}
       - Tunnel 1 Pre-shared Key: Use 'terraform output -raw vpn_tunnel1_preshared_key' to view
       - Tunnel 2 Address: ${aws_vpn_connection.main.tunnel2_address}
       - Tunnel 2 Pre-shared Key: Use 'terraform output -raw vpn_tunnel2_preshared_key' to view

    3. Set up routing on the Digital Ocean VPN gateway to route traffic between the VPCs

    Sample strongSwan configuration:

    # File: /etc/ipsec.conf
    conn aws-vpn-tunnel1
      auto=start
      authby=secret
      type=tunnel
      left=%defaultroute
      leftsubnet=${var.do_vpc_cidr}
      right=${aws_vpn_connection.main.tunnel1_address}
      rightsubnet=${var.aws_vpc_cidr}
      ike=aes256-sha256-modp2048
      esp=aes256-sha256-modp2048
      keyexchange=ikev2
      keyingtries=%forever
      leftid=${digitalocean_reserved_ip.vpn_ip.ip_address}
      rightid=${aws_vpn_connection.main.tunnel1_address}
      mark=100

    # File: /etc/ipsec.secrets
    ${digitalocean_reserved_ip.vpn_ip.ip_address} ${aws_vpn_connection.main.tunnel1_address} : PSK "your-preshared-key"

    4. Test connectivity between VPCs

    For detailed IPsec VPN setup guidance, refer to AWS documentation:
    https://docs.aws.amazon.com/vpn/latest/s2svpn/SetUpVPNConnections.html
  EOT
}
