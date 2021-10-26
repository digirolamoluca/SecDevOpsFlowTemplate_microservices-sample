terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.6.6"
    }
  }
}
provider "proxmox" {
    pm_api_url = "https://10.224.16.41:8006/api2/json"
    pm_tls_insecure = "true"
}
