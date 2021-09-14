terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 2.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "durbin_casa_dns" {
  source = "./modules/durbin_casa_dns"
}
