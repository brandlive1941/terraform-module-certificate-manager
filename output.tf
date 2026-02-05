output "cloudflare_certificate_id" {
  description = "Cloudflare Certificate ID"
  value       = try(google_certificate_manager_certificate.cloudflare_certificate[0].id, null)
}

output "gcp_certificate_id" {
  description = "GCP Certificate ID"
  value       = try(google_certificate_manager_certificate.gcp_certificate[0].id, null)
}

output "dns_authorization_details" {
  description = "DNS Authorization details for manual DNS configuration"
  value = merge(
    {
      for k, v in google_certificate_manager_dns_authorization.gcp_auth : k => {
        name  = v.dns_resource_record[0].name
        type  = v.dns_resource_record[0].type
        value = v.dns_resource_record[0].data
      }
    },
    {
      for k, v in google_certificate_manager_dns_authorization.cloudflare_auth : k => {
        name  = v.dns_resource_record[0].name
        type  = v.dns_resource_record[0].type
        value = v.dns_resource_record[0].data
      }
    }
  )
}
