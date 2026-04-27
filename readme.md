# Site-to-Site VPN: AWS ↔ Azure (Terraform)

Provisions a fully-encrypted IPsec site-to-site VPN tunnel between an AWS VPC and an Azure VNet, plus one test VM in each cloud to verify connectivity.

---

## Architecture

```
AWS VPC (10.0.0.0/16)               Azure VNet (10.1.0.0/16)
   |                                       |
   +-- EC2 (10.0.x.x) <-- IPsec VPN -->   +-- VM (10.1.x.x)
   |                                       |
AWS VPN Gateway + Customer Gateway   Azure Virtual Network Gateway
```

Two BGP / static-route IPsec tunnels are created (one per AWS VGW endpoint) for HA.

---

## What gets created

| Side | Resources | File |
|------|-----------|------|
| AWS  | VPC, subnets, IGW, route tables, VGW, Customer Gateway, VPN Connection, EC2 | `aws.tf`, `aws_ec2.tf` |
| Azure | Resource group, VNet, subnet, GatewaySubnet, Public IPs, Virtual Network Gateway, Local Network Gateway, VNet→VNet/VPN connection, VM | `azure.tf`, `vm.tf` |
| Outputs | VPN tunnel IPs, EC2 + VM public IPs | `output.tf` |
| Self-IP | Operator IP injected into both clouds' security groups for SSH | `self_ip.tf` |

---

## Prerequisites

1. AWS account + Administrator credential (`aws configure`).
2. Azure subscription + `az login` completed.
3. EC2 key pair on AWS side; SSH key on Azure side (`ssh-keygen`).
4. Terraform >= 1.5.

---

## Configuration

Edit `terraform.tfvars`:

```hcl
aws_region          = "ap-south-2"
aws_vpc_cidr        = "10.0.0.0/16"
aws_subnet_cidr     = "10.0.1.0/24"
aws_ami             = "ami-0bbc2f7f6287d5ca6"
aws_kp              = "Hyd-kp"
aws_private_key_path= "C:/Users/prabh/Desktop/Hyd-kp.pem"

azure_location      = "Central India"
azure_vnet_cidr     = "10.1.0.0/16"
azure_subnet_cidr   = "10.1.1.0/24"
azure_admin_user    = "azureuser"
azure_public_key_path = "C:/Users/prabh/.ssh/azure.pub"
```

---

## Deploy

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

VPN gateway provisioning on Azure can take 30-45 minutes — apply will block.

---

## Verify

After apply:

```bash
# From AWS EC2
ping <azure-vm-private-ip>
# From Azure VM
ping <aws-ec2-private-ip>
```

Both must return RTT < 100ms; otherwise check tunnel status in AWS VPN Connections console + Azure Connection blade.

---

## Tear down

```bash
terraform destroy -auto-approve
```

(Azure VPN gateway destroy also takes 20+ minutes.)