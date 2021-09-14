terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 2.0"
    }
  }
}

data "cloudflare_zones" "durbin_casa" {
  filter {
    name = "durbin.casa"
  }
}

locals {
  zone_id = lookup(data.cloudflare_zones.durbin_casa.zones[0], "id")
}

resource "cloudflare_record" "durbin_casa" {
  zone_id = local.zone_id
  name = "durbin.casa"
  value = "100.86.149.128"
  type = "A"
  ttl = 3600
}

resource "cloudflare_record" "wildcard_durbin_casa" {
  zone_id = local.zone_id
  name = "*"
  value = "100.86.149.128"
  type = "A"
  ttl = 3600
}
