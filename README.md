# Cloud-Labs-IAC
Cloud Labs deployed quickly with Infrastructure-as-code scripts

Terraform scripts deploy 2 DigitalOcean Droplet VMs with AlmaLinux OS.
- Root user is configured with existing SSH keys in DigitalOcean
- Cloudinit script is passed which
  - Disables root user
  - Adds ansible user with sudo and pubkey
  - Adds main user with sudo and pubkey
  - Runs dnf updates, installs tools

Ansible is then hooked in, and runs remotely, configuring further items (work in progress)