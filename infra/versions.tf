terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }

  backend "s3" {
    # Configure via TF_BACKEND_* env vars or backend config file.
    # Example:
    #   bucket  = "my-tf-state"
    #   key     = "shopping-cart/terraform.tfstate"
    #   region  = "us-east-1"
    #   encrypt = true
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
