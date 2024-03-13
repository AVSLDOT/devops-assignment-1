#!/bin/bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor |  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt-get install terraform
sudo terraform -install-autocomplete

sudo apt-get install software-properties-common -y
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible -y

sudo ansible-galaxy collection install amazon.aws

sudo apt install python3-pip -y
pip3 install boto3

echo '[defaults]
enable_plugins = aws_ec2' | sudo tee -a /etc/ansible/ansible.cfg

echo 'host_key_checking = False' | sudo tee -a /etc/ansible/ansible.cfg

echo 'plugin: amazon.aws.aws_ec2
regions:
 - us-east-1
keyed_groups:
  # add hosts to tag_Name_value groups for each aws_ec2 hosts tags.Name variable.
 - key: tags.Name
    prefix: tag_Name_
    separator: ""
 '| sudo tee -a  /etc/ansible/aws_ec2.yml
