data "exoscale_compute_template" "ubuntu" {
  zone = var.exoscale_zone
  name = "Linux Ubuntu 18.04 LTS 64-bit"
}

data "template_file" "users" {
  template = <<EOF
%{ for username,sshkey in var.users ~}
create_user ${username} ${sshkey}
%{ endfor ~}
EOF
  vars = {}
}

resource "exoscale_compute" "web" {
  display_name = var.server_hostname
  template_id = data.exoscale_compute_template.ubuntu.id
  size = var.instance_type
  disk_size = var.disk_size
  key_pair = exoscale_ssh_keypair.initial.name
  state = "Running"
  zone = "at-vie-1"

  security_groups = [
    exoscale_security_group.web.name
  ]
  ip4 = true
  ip6 = true

  user_data = <<EOF
#!/bin/bash

#region Users
function create_user() {
  useradd -m -s /bin/bash $1
  mkdir -p /home/$1/.ssh
  echo "$2" >/home/$1/.ssh/authorized_keys
  chown -R $1:$1 /home/$1
  gpasswd -a $1 sudo
  gpasswd -a $1 adm
}

sed -i -e 's/%sudo\s*ALL=(ALL:ALL)\s*ALL/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers
${data.template_file.users.rendered}
#endregion

# region Updates
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y rsync htop tcpdump tcpflow unzip mc
# endregion

# region SSH
echo '${tls_private_key.web-ecdsa.private_key_pem}' >/etc/ssh/ssh_host_ecdsa_key
echo '${tls_private_key.web-rsa.private_key_pem}' >/etc/ssh/ssh_host_rsa_key
rm /etc/ssh/ssh_host_dsa_key
rm /etc/ssh/ssh_host_ed25519_key
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key//' /etc/ssh/sshd_config
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key//' /etc/ssh/sshd_config
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/' /etc/ssh/sshd_config
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/' /etc/ssh/sshd_config
sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo '${tls_locally_signed_cert.web-ecdsa.cert_pem}' >/etc/ssh/ssh_host_ecdsa_cert
echo '${tls_locally_signed_cert.web-rsa.cert_pem}' >/etc/ssh/ssh_host_rsa_cert
echo '${tls_self_signed_cert.ca.cert_pem}' >/etc/ssh/ssh_ca_cert
echo 'HostCertificate /etc/ssh/ssh_host_ecdsa_cert' >>/etc/ssh/sshd_config
echo 'HostCertificate /etc/ssh/ssh_host_rsa_cert' >>/etc/ssh/sshd_config
sed -i -e 's/#Port 22/Port ${var.ssh_port}/' /etc/ssh/sshd_config
# endregion

# region Docker
export DEBIAN_FRONTEND=noninteractive
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir -p /srv/docker
chown -R ubuntu:ubuntu /srv/docker
# endregion

# region Traefik
mkdir -p /srv/acme
# endregion

# region Reboot
reboot --reboot
# endregion
EOF
  connection {
    host = self.ip_address
    agent = false
    type = "ssh"
    user = "ubuntu"
    port = var.ssh_port
    private_key = tls_private_key.initial.private_key_pem
    host_key = tls_private_key.web-rsa.public_key_openssh
  }
  provisioner "file" {
    source = "docker-compose.yml"
    destination = "/srv/docker/docker-compose.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "export EXOSCALE_KEY=\"${var.exoscale_key}\"",
      "export EXOSCALE_SECRET=\"${var.exoscale_secret}\"",
      "export EXOSCALE_ZONE=\"${var.exoscale_zone}\"",
      "export BACKUP_BUCKET_NAME=\"${aws_s3_bucket.backup.bucket}\"",
      "export DOMAIN=\"${local.domain_name}\"",
      "export VERSION=\"${var.container_version}\"",
      "cd /srv/docker",
      "sudo -E docker-compose up -d",
      "sudo userdel -f -r ubuntu"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {}

  depends_on = [
    "exoscale_security_group.web"
  ]
}