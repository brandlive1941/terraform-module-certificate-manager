# terraform dns authorization and domain wildcard certificate module 
===========

A terraform module to provide certificates via certificate manager

Module Input Variables
----------------------

- `project` - gcp project id
- `managed_zone` - dns zone name

Usage
-----

```hcl
module "example" {
  source          = "github.com/brandlive1941/terraform-module-certificate-manager?ref=v1.0.1"

  name            = var.name
  domain          = var.domain
  domain_cloud    = var.domain_cloud
  hostnames       = var.hostnames
  wildcard        = var.wildcard (optional)
  certificate_map = var.certificate_map (optional)
  default         = var.default (optional)
}
```

Outputs
=======

Authors
=======

drew.mercer@brandlive.com
