terraform {
  required_version = "> 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}
variable "ans_pub_key" {}
variable "ans_pvt_key" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# this block helps us get the ID of an existing ssh key from digitalocean
data "digitalocean_ssh_key" "ansible" {
  name = "ansible-key"
}

data "digitalocean_ssh_key" "user" {
  name = "awkto-dev"
}


#PRIMARY DROPLET
#Droplet options : 
#sizes : s-2vcpu-4gb-amd | s-2vcpu-8gb-amd | s-4vcpu-16gb-amd
#images : almalinux-8-x64 | ubuntu-20-04-x64 | ubuntu-22-04-x64 | fedora-37-x64 | fedora-38-x64 | centos-7-x64 | centos-stream-7-x64 | centos-stream-8-x64 | debian-10-x64 | debian-11-x64 | debian-12-x64
resource "digitalocean_droplet" "appserver" {
  image     = "almalinux-8-x64"
  name      = "appserver.dnsif.ca"
  region    = "syd1"
  size      = "s-2vcpu-4gb-amd"
  user_data = file("cloudconfig-appserver.yaml")
  ssh_keys = [data.digitalocean_ssh_key.ansible.id, data.digitalocean_ssh_key.user.id]


  provisioner "remote-exec" {
    inline = ["sudo dnf check-update", "sudo dnf install python3 -y", "echo Done!"]
    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "ansible"
      private_key = file(var.ans_pvt_key)
    }
  }
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ~/.ssh/id_rsa -e 'pub_key=~/.ssh/id_rsa.pub' ans-appserver.yaml"    
  # }
}

output "appserver_ip_address" {
  value = digitalocean_droplet.appserver.ipv4_address
  description = "Public IP of the appserver droplet"
}

#terraform import digitalocean_domain.mydomain mytestdomain.com

# resource "digitalocean_domain" "dnsifdomain" {
#   name = "dnsif.ca"
# }

# DNS record for gitlab droplet
resource "digitalocean_record" "appserver-dns-record" {
#  domain = digitalocean_domain.dnsifdomain.id
  domain = "dnsif.ca"
  type   = "A"
  name   = "appserver"
  value  = digitalocean_droplet.appserver.ipv4_address
  ttl    = 60  
}

output "appserver_main_dns_record" {
  value = digitalocean_record.appserver-dns-record.fqdn
  description = "DNS record of appserver server"
}




#SECONDARY DROPLET
#Droplet options : 
#sizes : s-2vcpu-4gb-amd | s-2vcpu-8gb-amd | s-4vcpu-16gb-amd
#images : almalinux-8-x64 | ubuntu-20-04-x64 | ubuntu-22-04-x64 | fedora-37-x64 | fedora-38-x64 | centos-7-x64 | centos-stream-7-x64 | centos-stream-8-x64 | debian-10-x64 | debian-11-x64 | debian-12-x64
resource "digitalocean_droplet" "logger" {
  image     = "almalinux-8-x64"
  name      = "logger.dnsif.ca"
  region    = "syd1"
  size      = "s-2vcpu-4gb-amd"
  user_data = file("cloudconfig-logger.yaml")
  ssh_keys = [data.digitalocean_ssh_key.ansible.id, data.digitalocean_ssh_key.user.id]


  provisioner "remote-exec" {
    inline = ["sudo dnf check-update", "sudo dnf install python3 -y", "echo Done!"]
    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "ansible"
      private_key = file(var.ans_pvt_key)
    }
  }
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ~/.ssh/id_rsa -e 'pub_key=~/.ssh/id_rsa.pub' ans-logger.yaml"    
  # }
}

output "gitlab_ip_address" {
  value = digitalocean_droplet.logger.ipv4_address
  description = "Public IP of the gitlab droplet"
}

#terraform import digitalocean_domain.mydomain mytestdomain.com

# resource "digitalocean_domain" "dnsifdomain" {
#   name = "dnsif.ca"
# }

# DNS record for gitlab droplet
resource "digitalocean_record" "logger-dns-record" {
#  domain = digitalocean_domain.dnsifdomain.id
  domain = "dnsif.ca"
  type   = "A"
  name   = "logger"
  value  = digitalocean_droplet.logger.ipv4_address
  ttl    = 60  
}

output "logger_dns_record" {
  value = digitalocean_record.logger-dns-record.fqdn
  description = "DNS record of logger server"
}