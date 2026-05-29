output "namespace" {
  description = "The Kubernetes namespace created for the app."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "image_pull_secret" {
  description = "Name of the Docker Hub image pull secret."
  value       = kubernetes_secret.dockerhub_pull.metadata[0].name
}

output "app_url" {
  description = "Public HTTPS URL for the shopping cart app."
  value       = "https://shop.claudiq.com"
}

output "certificate_arn" {
  description = "ARN of the ACM certificate for shop.claudiq.com."
  value       = aws_acm_certificate.app.arn
}

output "load_balancer_hostname" {
  description = "AWS Load Balancer hostname assigned to the service."
  value       = kubernetes_service_v1.app.status[0].load_balancer[0].ingress[0].hostname
}
