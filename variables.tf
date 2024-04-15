variable "name" {
  description = "Name of the certificate"
  type        = string
}

variable "domain" {
  description = "Domain"
  type        = string
}

variable "domain_cloud" {
  description = "valid options: gcp, cloudflare"
  type        = string
}

variable "hostnames" {
  description = "Hostnames to create certificates for"
  type        = list(string)
}

variable "wildcard" {
  description = "Wildcard"
  type        = bool
  default     = false
}

variable "certificate_map" {
  description = "Certificate Map toggle"
  type        = string
  default     = false
}

variable "certificate_name" {
  description = "Name of the certificate"
  type        = string
  default     = ""
}

variable "default" {
  description = "Default Certificate in Certificate Map"
  type        = bool
  default     = false
}
