# Terraform config to launch Rancher 2.x in a simulated airgapped environment

## How to use

- Clone this repository
- Move the file `terraform.tfvars.example` to `terraform.tfvars` and edit (see inline explanation)
- Configure `DIGITALOCEAN_TOKEN` environment variable using `export DIGITALOCEAN_TOKEN=abc`
- Run `terraform apply`
