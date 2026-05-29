locals {
  app_label = "mallam-shehu-suya"

  docker_config = jsonencode({
    auths = {
      "https://index.docker.io/v1/" = {
        auth = base64encode("${var.dockerhub_username}:${var.dockerhub_token}")
      }
    }
  })
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
    labels = {
      app                                  = local.app_label
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

moved {
  from = kubernetes_secret.ghcr_pull
  to   = kubernetes_secret.dockerhub_pull
}

resource "kubernetes_secret" "dockerhub_pull" {
  metadata {
    name      = var.image_pull_secret_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = local.docker_config
  }
}

resource "kubernetes_network_policy" "allow_ingress" {
  metadata {
    name      = "${local.app_label}-allow-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = local.app_label
      }
    }

    ingress {
      ports {
        port     = "8070"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow_egress" {
  metadata {
    name      = "${local.app_label}-allow-egress"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = local.app_label
      }
    }

    policy_types = ["Egress"]

    egress {
      # DNS resolution
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    egress {
      # HTTPS — required for Docker Hub image pulls and AWS API calls
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "app" {
  metadata {
    name      = "${local.app_label}-pdb"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    min_available = 1

    selector {
      match_labels = {
        app = local.app_label
      }
    }
  }
}
