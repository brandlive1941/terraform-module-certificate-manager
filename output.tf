output "aws_certificate_id" {
  description = "AWS Certificate ARN"
  value       = try(google_certificate_manager_certificate.aws_certificate[0].id, null)
}

output "gcp_certificate_id" {
  description = "GCP Certificate ID"
  value       = try(google_certificate_manager_certificate.gcp_certificate[0].id, null)
}
