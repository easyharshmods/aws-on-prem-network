# aws-on-prem-network

# AWS-DigitalOcean Hybrid EKS

This project creates a hybrid network environment connecting AWS and Digital Ocean, which can be used to run Amazon EKS with hybrid nodes across both environments.

## Project Structure

The project is organized into separate Terraform files for clarity:

```
.
├── README.md
├── aws_vpc.tf              # AWS VPC and Transit Gateway
├── do_vpc.tf               # Digital Ocean VPC and Gateway
├── site2site_vpn.tf        # Site-to-Site VPN configuration
├── variables.tf            # Variable definitions
├── providers.tf            # Provider configurations
├── outputs.tf              # Output values
├── terraform.tfvars        # Variable values (gitignored)
├── terraform.tfvars.example # Example variable values
└── .gitignore
```

## Prerequisites

- AWS account with appropriate permissions
- Digital Ocean account with API token
- SSH key registered with Digital Ocean
- Terraform installed
- AWS CLI configured

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/your-username/aws-on-prem-network.git
cd aws-on-prem-network
```

### 2. Create terraform.tfvars file

Create a `terraform.tfvars` file with your specific values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars` with your specific values:

```hcl
aws_region   = "us-west-2"
do_region    = "nyc1"
aws_vpc_cidr = "10.0.0.0/16"
do_vpc_cidr  = "172.16.0.0/16"
ssh_key_name = "your-ssh-key-name"
do_token     = "your-digitalocean-api-token"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Apply the configuration

```bash
terraform plan    # Preview changes
terraform apply   # Apply changes
```

## VPN Configuration

After Terraform creates the infrastructure, you need to configure the VPN connection on the Digital Ocean side:

1. SSH into the Digital Ocean VPN gateway droplet:
   ```bash
   ssh root@$(terraform output -raw do_vpn_gateway_ip)
   ```

2. Configure strongSwan with the values from Terraform output:
   ```bash
   # View VPN tunnel information (run this on your local machine)
   terraform output

   # Get the pre-shared keys (run this on your local machine)
   terraform output -raw vpn_tunnel1_preshared_key
   terraform output -raw vpn_tunnel2_preshared_key
   ```

3. Create the strongSwan configuration on the Digital Ocean droplet:
   ```bash
   # On the DO droplet, create ipsec.conf
   cat > /etc/ipsec.conf <<EOF
   config setup
       charondebug="all"
       uniqueids=yes

   conn aws-vpn-tunnel1
       auto=start
       authby=secret
       type=tunnel
       left=%defaultroute
       leftsubnet=172.16.0.0/16
       right=<TUNNEL1_ADDRESS>
       rightsubnet=10.0.0.0/16
       ike=aes256-sha256-modp2048
       esp=aes256-sha256-modp2048
       keyexchange=ikev2
       keyingtries=%forever
       leftid=<DROPLET_PUBLIC_IP>
       rightid=<TUNNEL1_ADDRESS>
       mark=100
   EOF

   # Create the ipsec.secrets file
   cat > /etc/ipsec.secrets <<EOF
   <DROPLET_PUBLIC_IP> <TUNNEL1_ADDRESS> : PSK "<TUNNEL1_PRESHARED_KEY>"
   EOF

   # Secure the secrets file
   chmod 600 /etc/ipsec.secrets

   # Restart strongSwan
   systemctl restart strongswan
   ```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.95 |
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | ~> 2.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.95.0 |
| <a name="provider_digitalocean"></a> [digitalocean](#provider\_digitalocean) | 2.51.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_customer_gateway.do_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_route.to_do_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.to_do_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.interconnection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpn_connection.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |
| [digitalocean_droplet.vpn_gateway](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet) | resource |
| [digitalocean_firewall.vpc_interconnection](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/firewall) | resource |
| [digitalocean_reserved_ip.vpn_ip](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/reserved_ip) | resource |
| [digitalocean_vpc.main](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/vpc) | resource |
| [aws_ec2_transit_gateway_route_table.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway_route_table) | data source |
| [digitalocean_droplet.vpn_gateway](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/data-sources/droplet) | data source |
| [digitalocean_ssh_key.main](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/data-sources/ssh_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to deploy to | `string` | `"us-west-2"` | no |
| <a name="input_aws_vpc_cidr"></a> [aws\_vpc\_cidr](#input\_aws\_vpc\_cidr) | CIDR block for AWS VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_do_region"></a> [do\_region](#input\_do\_region) | Digital Ocean region to deploy resources | `string` | `"nyc1"` | no |
| <a name="input_do_token"></a> [do\_token](#input\_do\_token) | Digital Ocean API token | `string` | n/a | yes |
| <a name="input_do_vpc_cidr"></a> [do\_vpc\_cidr](#input\_do\_vpc\_cidr) | CIDR block for Digital Ocean VPC | `string` | `"172.16.0.0/16"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key in Digital Ocean | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_private_subnet_ids"></a> [aws\_private\_subnet\_ids](#output\_aws\_private\_subnet\_ids) | n/a |
| <a name="output_aws_public_subnet_ids"></a> [aws\_public\_subnet\_ids](#output\_aws\_public\_subnet\_ids) | n/a |
| <a name="output_aws_vpc_id"></a> [aws\_vpc\_id](#output\_aws\_vpc\_id) | AWS VPC outputs |
| <a name="output_do_vpc_cidr"></a> [do\_vpc\_cidr](#output\_do\_vpc\_cidr) | n/a |
| <a name="output_do_vpc_id"></a> [do\_vpc\_id](#output\_do\_vpc\_id) | Digital Ocean VPC outputs |
| <a name="output_do_vpn_gateway_ip"></a> [do\_vpn\_gateway\_ip](#output\_do\_vpn\_gateway\_ip) | n/a |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | n/a |
| <a name="output_vpn_connection_id"></a> [vpn\_connection\_id](#output\_vpn\_connection\_id) | VPN connection outputs |
| <a name="output_vpn_setup_instructions"></a> [vpn\_setup\_instructions](#output\_vpn\_setup\_instructions) | Setup instructions |
| <a name="output_vpn_tunnel1_address"></a> [vpn\_tunnel1\_address](#output\_vpn\_tunnel1\_address) | n/a |
| <a name="output_vpn_tunnel1_preshared_key"></a> [vpn\_tunnel1\_preshared\_key](#output\_vpn\_tunnel1\_preshared\_key) | n/a |
| <a name="output_vpn_tunnel2_address"></a> [vpn\_tunnel2\_address](#output\_vpn\_tunnel2\_address) | n/a |
| <a name="output_vpn_tunnel2_preshared_key"></a> [vpn\_tunnel2\_preshared\_key](#output\_vpn\_tunnel2\_preshared\_key) | n/a |
<!-- END_TF_DOCS -->
## Security Considerations

- This project creates open security group rules for demonstration purposes
- For production, restrict security groups and firewall rules
- Consider using environment variables or AWS Secrets Manager for sensitive values
- Use a proper SSH key pair management system

## License

[MIT License](LICENSE)
