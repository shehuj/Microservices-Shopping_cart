variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name to manage resources on."
  type        = string
  default     = "shopping-cart-eks"
}

variable "namespace" {
  description = "Kubernetes namespace to create for the shopping-cart app."
  type        = string
  default     = "shopping-cart"
}

variable "image_pull_secret_name" {
  description = "Name of the Kubernetes secret used to pull images from Docker Hub."
  type        = string
  default     = "dockerhub-credentials"
}

variable "dockerhub_username" {
  description = "Docker Hub username for image pulls."
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub access token for image pulls."
  type        = string
  sensitive   = true
}

variable "app_replicas" {
  description = "Number of deployment replicas."
  type        = number
  default     = 2
}
