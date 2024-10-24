output "aws-ec2-public-ip" {
  value = aws_instance.public-server[*].public_ip
}

output "aws-ec2-private-ip" {
  value = aws_instance.public-server[*].private_ip
}


output "azure-vm-public-ip" {
  value = azurerm_public_ip.public_ip_3.ip_address
}

output "azure-vm-private-ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
