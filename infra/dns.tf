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

# ALB hosted zone IDs per region — required for apex A-alias (CNAME not allowed at zone apex)
# https://docs.aws.amazon.com/general/latest/gr/elb.html
locals {
  alb_hosted_zone_id = {
    "us-east-1"      = "Z35SXDOTRQ7X7K"
    "us-east-2"      = "Z3AADJGX6KTTL2"
    "us-west-1"      = "Z368ELLRRE2KJ0"
    "us-west-2"      = "Z1H1FL5HABSF5"
    "eu-west-1"      = "Z32O12XQLNTSW2"
    "eu-west-2"      = "ZHURV8PSTC4K8"
    "eu-central-1"   = "Z215JYRZR1TBD5"
    "ap-southeast-1" = "Z1LMS91P8CMLE5"
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"
    "ap-northeast-1" = "Z14GRHDCWA56QT"
  }[var.aws_region]
}

# A-alias mallamshehusuya.com → ALB (apex domain requires alias, not CNAME)
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = local.alb_hosted_zone_id
    evaluate_target_health = true
  }
}
