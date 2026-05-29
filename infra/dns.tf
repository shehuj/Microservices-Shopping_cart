data "aws_route53_zone" "main" {
  name         = "mallamshehusuya.com"
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  domain_name       = "mallamshehusuya.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ClusterIP service — ALB targets pods directly via IP (target-type: ip)
resource "kubernetes_service_v1" "app" {
  metadata {
    name      = "mallam-shehu-suya-svc"
    namespace = var.namespace
  }

  spec {
    selector = {
      app        = local.app_label
      tier       = "backend"
      phase      = "production"
      deployment = "v1"
    }

    type = "ClusterIP"

    port {
      name        = "http"
      port        = 8070
      target_port = 8070
      protocol    = "TCP"
    }
  }
}

# ALB Ingress — internet-facing, HTTPS with ACM cert, HTTP→HTTPS redirect
resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "mallam-shehu-suya-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"                             = "alb"
      "alb.ingress.kubernetes.io/scheme"                        = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"                   = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"               = aws_acm_certificate_validation.app.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"                  = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"                  = "443"
      "alb.ingress.kubernetes.io/healthcheck-path"              = "/"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds"  = "30"
      "alb.ingress.kubernetes.io/healthy-threshold-count"       = "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"     = "3"
      "alb.ingress.kubernetes.io/load-balancer-attributes"      = "idle_timeout.timeout_seconds=60"
    }
  }

  spec {
    rule {
      host = "mallamshehusuya.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.app.metadata[0].name
              port {
                number = 8070
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true

  depends_on = [aws_acm_certificate_validation.app]
}

# CNAME mallamshehusuya.com → ALB hostname
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = ""
  type    = "CNAME"
  ttl     = 300
  records = [kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].hostname]
}
