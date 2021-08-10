variable "prefix" {
  default = "yourname"
}

variable "domain" {
  default = "yourdomain"
}

variable "admin_password" {
  default = "moresecretthanyoucanimagine"
}

variable "rancher_version" {
  default = "v2.5.9"
}

variable "k8s_version" {
  default = ""
}

variable "cluster_name" {
  default = "airgap"
}

variable "region" {
  default = "ams3"
}

variable "proxy_size" {
  default = "c-4"
}

variable "size" {
  default = "s-2vcpu-4gb"
}

variable "docker_version_server" {
  default = "20.10"
}

variable "docker_version_agent" {
  default = "20.10"
}

variable "ssh_keys" {
  default = [1000000]
}

variable "registry_auth" {
  type    = bool
  default = true
}

variable "rancher_args" {
  default = "--trace"
}

resource "digitalocean_droplet" "rancherproxy-airgap" {
  count              = "1"
  image              = "ubuntu-20-04-x64"
  name               = "${var.prefix}-rancherproxy-airgap"
  private_networking = true
  region             = var.region
  size               = var.proxy_size
  user_data          = data.template_file.userdata_proxy.rendered
  ssh_keys           = var.ssh_keys
}

resource "digitalocean_volume" "rancherproxy-airgap-volume" {
  region                  = var.region
  name                    = "${var.prefix}-rancherproxy-volume"
  size                    = 50
  initial_filesystem_type = "ext4"
  description             = "${var.prefix}-rancherproxy-volume"
}

resource "digitalocean_volume_attachment" "rancherproxy-airgap-volume-attachment" {
  droplet_id = digitalocean_droplet.rancherproxy-airgap[0].id
  volume_id  = digitalocean_volume.rancherproxy-airgap-volume.id
}

resource "digitalocean_record" "registry" {
  domain = var.domain
  type   = "A"
  name   = "${var.prefix}-registry"
  value  = digitalocean_droplet.rancherproxy-airgap[0].ipv4_address_private
  ttl    = 120
}

resource "digitalocean_record" "rancher" {
  domain = var.domain
  type   = "A"
  name   = "${var.prefix}-rancher"
  value  = digitalocean_droplet.rancherserver-airgap[0].ipv4_address
  ttl    = 120
}

resource "digitalocean_record" "rancherprivate" {
  domain = var.domain
  type   = "A"
  name   = "${var.prefix}-rancherprivate"
  value  = digitalocean_droplet.rancherserver-airgap[0].ipv4_address_private
  ttl    = 120
}

resource "digitalocean_firewall" "proxy" {
  name = "${var.prefix}-proxy"

  droplet_ids = [digitalocean_droplet.rancherproxy-airgap[0].id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = flatten([digitalocean_droplet.rancherproxy-airgap[*].ipv4_address_private, digitalocean_droplet.rancherserver-airgap[*].ipv4_address_private, digitalocean_droplet.rancheragent-airgap[*].ipv4_address_private])
  }
  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = flatten([digitalocean_droplet.rancherproxy-airgap.*.ipv4_address_private, digitalocean_droplet.rancherserver-airgap.*.ipv4_address_private, digitalocean_droplet.rancheragent-airgap.*.ipv4_address_private])
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "airgap" {
  name = "${var.prefix}-airgap"

  droplet_ids = flatten([digitalocean_droplet.rancherserver-airgap[0].id, digitalocean_droplet.rancheragent-airgap[*].id])

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = flatten([digitalocean_droplet.rancherproxy-airgap.*.ipv4_address_private, digitalocean_droplet.rancherproxy-airgap.*.ipv4_address, digitalocean_droplet.rancherserver-airgap.*.ipv4_address_private, digitalocean_droplet.rancherserver-airgap.*.ipv4_address, digitalocean_droplet.rancheragent-airgap.*.ipv4_address_private, digitalocean_droplet.rancheragent-airgap.*.ipv4_address])
  }
  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = flatten([digitalocean_droplet.rancherproxy-airgap.*.ipv4_address_private, digitalocean_droplet.rancherproxy-airgap.*.ipv4_address, digitalocean_droplet.rancherserver-airgap.*.ipv4_address_private, digitalocean_droplet.rancherserver-airgap.*.ipv4_address, digitalocean_droplet.rancheragent-airgap.*.ipv4_address_private, digitalocean_droplet.rancheragent-airgap.*.ipv4_address])
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = flatten([digitalocean_droplet.rancherproxy-airgap.*.ipv4_address_private, digitalocean_droplet.rancherproxy-airgap.*.ipv4_address, digitalocean_droplet.rancherserver-airgap.*.ipv4_address_private, digitalocean_droplet.rancherserver-airgap.*.ipv4_address, digitalocean_droplet.rancheragent-airgap.*.ipv4_address_private, digitalocean_droplet.rancheragent-airgap.*.ipv4_address])
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = flatten([digitalocean_droplet.rancherproxy-airgap.*.ipv4_address_private, digitalocean_droplet.rancherproxy-airgap.*.ipv4_address, digitalocean_droplet.rancherserver-airgap.*.ipv4_address_private, digitalocean_droplet.rancherserver-airgap.*.ipv4_address, digitalocean_droplet.rancheragent-airgap.*.ipv4_address_private, digitalocean_droplet.rancheragent-airgap.*.ipv4_address])
  }
}

data "template_file" "userdata_proxy" {
  template = file("files/proxy/userdata_proxy")

  vars = {
    domain          = var.domain
    prefix          = var.prefix
    rancher_version = var.rancher_version
    registry_auth   = var.registry_auth
  }
}

data "template_file" "userdata_server" {
  template = file("files/airgap/userdata_server")

  vars = {
    admin_password        = var.admin_password
    cluster_name          = var.cluster_name
    docker_version_server = var.docker_version_server
    domain                = var.domain
    k8s_version           = var.k8s_version
    prefix                = var.prefix
    registry_auth         = var.registry_auth
    proxy_address         = digitalocean_droplet.rancherproxy-airgap[0].ipv4_address_private
    cluster_addresses     = join(",", digitalocean_droplet.rancheragent-airgap.*.ipv4_address)
    rancher_version       = var.rancher_version
    rancher_args          = var.rancher_args
  }
}

data "template_file" "userdata_agent" {
  template = file("files/airgap/userdata_agent")

  vars = {
    admin_password       = var.admin_password
    cluster_name         = var.cluster_name
    docker_version_agent = var.docker_version_agent
    domain               = var.domain
    prefix               = var.prefix
    registry_auth        = var.registry_auth
    proxy_address        = digitalocean_droplet.rancherproxy-airgap[0].ipv4_address_private
    rancher_version      = var.rancher_version
  }
}

resource "digitalocean_droplet" "rancherserver-airgap" {
  count              = "1"
  image              = "ubuntu-20-04-x64"
  name               = "${var.prefix}-rancherserver-airgap-${count.index}"
  private_networking = true
  region             = var.region
  size               = var.size
  user_data          = data.template_file.userdata_server.rendered
  ssh_keys           = var.ssh_keys
}

resource "digitalocean_droplet" "rancheragent-airgap" {
  count              = "2"
  image              = "ubuntu-20-04-x64"
  name               = "${var.prefix}-rancheragent-airgap-${count.index}"
  private_networking = true
  region             = var.region
  size               = var.size
  user_data          = data.template_file.userdata_agent.rendered
  ssh_keys           = var.ssh_keys
}

output "rancherproxyip" {
  value = [digitalocean_droplet.rancherproxy-airgap.*.ipv4_address]
}

output "rancherserver-airgap" {
  value = [digitalocean_droplet.rancherserver-airgap.*.ipv4_address]
}

output "rancheragent-airgap" {
  value = [digitalocean_droplet.rancheragent-airgap.*.ipv4_address]
}

output "rancher-url" {
  value = ["https://${var.prefix}-rancher.${var.domain}"]
}
