output "cloudflare_certificate_id" {
  description = "Cloudflare Certificate ID"
  value       = try(google_certificate_manager_certificate.cloudflare_certificate[0].id, null)
}

output "gcp_certificate_id" {
  description = "GCP Certificate ID"
  value       = try(google_certificate_manager_certificate.gcp_certificate[0].id, null)
}

output "certificate_maps" {
  description = "Certificate Map"
  value       = local.certificate_map_id
}