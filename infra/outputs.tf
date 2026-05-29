output "namespace" {
  description = "The Kubernetes namespace created for the app."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "image_pull_secret" {
  description = "Name of the Docker Hub image pull secret."
  value       = kubernetes_secret.dockerhub_pull.metadata[0].name
}
