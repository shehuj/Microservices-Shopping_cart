output "namespace" {
  description = "The Kubernetes namespace created for the app."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "image_pull_secret" {
  description = "Name of the GHCR image pull secret."
  value       = kubernetes_secret.ghcr_pull.metadata[0].name
}
