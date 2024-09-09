locals {
  gcp_hostnames             = var.domain_cloud == "gcp" ? var.hostnames : []
  gcp_authorizations        = values(google_certificate_manager_dns_authorization.gcp_auth).*.id
  cloudflare_hostnames      = var.domain_cloud == "cloudflare" ? var.hostnames : []
  cloudflare_authorizations = values(google_certificate_manager_dns_authorization.cloudflare_auth).*.id
  aws_hostnames             = var.domain_cloud == "aws" ? var.hostnames : []
  aws_authorizations        = values(google_certificate_manager_dns_authorization.aws_auth).*.resource_record_name
  certificate_name          = var.certificate_name != "" ? var.certificate_name : "${var.name}"
}

#### GCP DNS Authorization ####

# GCP Domain
data "google_dns_managed_zone" "gcp_zone" {
  count = var.domain_cloud == "gcp" ? 1 : 0

  name = replace(var.domain, ".", "-")
}

# GCP Randomized ID
resource "random_string" "gcp_rand" {
  for_each = toset(local.gcp_hostnames)

  length  = 8
  special = false
  upper   = false
}

# GCP DNS Authorization
resource "google_certificate_manager_dns_authorization" "gcp_auth" {
  for_each = toset(local.gcp_hostnames)

  name        = "${data.google_dns_managed_zone.gcp_zone[0].name}-dnsauth-${random_string.gcp_rand[each.key].id}"
  description = "DNS Authorization for ${data.google_dns_managed_zone.gcp_zone[0].dns_name}"
  domain      = each.key
  labels = {
    "terraform" : true
  }
}

# GCP DNS Authorization Record
resource "google_dns_record_set" "gcp_auth_cname" {
  for_each = toset(local.gcp_hostnames)

  name         = google_certificate_manager_dns_authorization.gcp_auth[each.key].dns_resource_record[0].name
  managed_zone = data.google_dns_managed_zone.gcp_zone[0].name
  type         = google_certificate_manager_dns_authorization.gcp_auth[each.key].dns_resource_record[0].type
  ttl          = 300
  rrdatas      = [google_certificate_manager_dns_authorization.gcp_auth[each.key].dns_resource_record[0].data]
}

# GCP Certificate with GCP DNS Authorization
resource "google_certificate_manager_certificate" "gcp_certificate" {
  count = var.domain_cloud == "gcp" ? 1 : 0

  name        = "${replace(data.google_dns_managed_zone.gcp_zone[0].name, ".", "-")}-certificate"
  description = "${data.google_dns_managed_zone.gcp_zone[0].name} certificate"
  managed {
    domains            = local.gcp_hostnames
    dns_authorizations = local.gcp_authorizations
  }
  labels = {
    "terraform" : true
  }
}

### Cloudflare DNS Authorization ###

# Cloudflare Domain
data "cloudflare_zone" "domain" {
  count = var.domain_cloud == "cloudflare" ? 1 : 0

  name = var.domain
}

# Cloudflare Randomized ID
resource "random_string" "cf_rand" {
  for_each = toset(local.cloudflare_hostnames)

  length  = 8
  special = false
  upper   = false
}

# Cloudflare DNS Authorization
resource "google_certificate_manager_dns_authorization" "cloudflare_auth" {
  for_each = toset(local.cloudflare_hostnames)

  name        = "${replace(var.domain, ".", "-")}-dnsauth-${random_string.cf_rand[each.key].id}"
  description = "DNS Authorization for ${var.domain}"
  domain      = each.key
  labels = {
    "terraform" : true
  }
}

# Cloudflare DNS Authorization Record
resource "cloudflare_record" "cloudflare_auth_cname" {
  for_each = toset(local.cloudflare_hostnames)

  zone_id = data.cloudflare_zone.domain[0].id
  name    = google_certificate_manager_dns_authorization.cloudflare_auth[each.key].dns_resource_record.0.name
  value   = google_certificate_manager_dns_authorization.cloudflare_auth[each.key].dns_resource_record.0.data
  type    = "CNAME"
  proxied = false
}

# GCP Certificate with Cloudflare DNS Authorization
resource "google_certificate_manager_certificate" "cloudflare_certificate" {
  count = var.domain_cloud == "cloudflare" ? 1 : 0

  name        = local.certificate_name
  description = "${var.domain} certificate"
  managed {
    domains            = local.cloudflare_hostnames
    dns_authorizations = local.cloudflare_authorizations
  }
  labels = {
    "terraform" : true
  }
}

#### AWS DNS Authorization ####

data "aws_route53_zone" "domain" {
  count = var.domain_cloud == "aws" ? 1 : 0

  name = var.domain
}

# AWS Randomized ID
resource "random_string" "aws_rand" {
  for_each = toset(local.aws_hostnames)

  length  = 8
  special = false
  upper   = false
}

# AWS DNS Authorization
resource "google_certificate_manager_dns_authorization" "aws_auth" {
  for_each = toset(local.aws_hostnames)

  name        = "${replace(var.domain, ".", "-")}-dnsauth-${random_string.aws_rand[each.key].id}"
  description = "DNS Authorization for ${var.domain}"
  domain      = each.key
  labels = {
    "terraform" : true
  }
}

# AWS DNS Authorization Record
resource "aws_route53_record" "aws_auth_cname" {
  for_each = toset(local.aws_hostnames)

  zone_id = aws_route53_zone.domain.zone_id
  name    = google_certificate_manager_dns_authorization.aws_auth[each.key].dns_resource_record.0.name
  type    = "CNAME"
  ttl     = 300
  records = [google_certificate_manager_dns_authorization.aws_auth[each.key].dns_resource_record.0.data]
}

# GCP Certificate with AWS DNS Authorization
resource "google_certificate_manager_certificate" "aws_certificate" {
  count = var.domain_cloud == "aws" ? 1 : 0

  name        = local.certificate_name
  description = "${var.domain} certificate"
  managed {
    domains            = local.aws_hostnames
    dns_authorizations = local.aws_authorizations
  }
  labels = {
    "terraform" : true
  }
}

#### Certificate Map Entry ####

# Certificate Map Entry (Primary, created if Default is true)
resource "google_certificate_manager_certificate_map_entry" "default" {
  count       = var.default ? 1 : 0
  name        = "cert-map-entry"
  description = "${var.domain} certificate map entry"
  map         = var.certificate_map
  labels = {
    "terraform" : true,
  }
  certificates = compact([
    try(google_certificate_manager_certificate.gcp_certificate[0].id, ""),
    try(google_certificate_manager_certificate.cloudflare_certificate[0].id, ""),
    try(google_certificate_manager_certificate.aws_certificate[0].id, ""),
  ])
  matcher = "PRIMARY"
}

# Certificate Map Entry (Secondary, created if Default is false)
resource "google_certificate_manager_certificate_map_entry" "certificate" {
  count       = var.default ? 0 : 1
  name        = replace(local.certificate_name, ".", "-")
  description = "${local.certificate_name} certificate map entry"
  map         = var.certificate_map
  labels = {
    "terraform" : true
  }
  certificates = compact([
    try(google_certificate_manager_certificate.gcp_certificate[0].id, ""),
    try(google_certificate_manager_certificate.cloudflare_certificate[0].id, ""),
    try(google_certificate_manager_certificate.aws_certificate[0].id, ""),
  ])
  hostname = var.hostnames[0]
}

