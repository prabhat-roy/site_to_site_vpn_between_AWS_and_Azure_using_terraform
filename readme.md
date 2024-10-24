Site to site vpn between AWS and Azure using terraform.

Create a credential with Administrator Access in AWS and configure in cli to authenticate with AWS.

Create a key pair in AWS and add the file path in terraform.tfvars file (line number 7) to associate with ec2.

Login to cli using az login command.

Create a key pair using below command  and add the file path in vm.tf file (line number 9) to associate with vm.

ssh-keygen -m PEM -t rsa -b 2048

Run terraform apply -auto-approve to create infrastructure in both AWS & Azure and login each vm to ping private ip of the other vm.


