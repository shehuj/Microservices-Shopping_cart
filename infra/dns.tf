data "aws_route53_zone" "main" {
  name         = "claudiq.com"
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  domain_name       = "shop.claudiq.com"
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

resource "kubernetes_service_v1" "app" {
  metadata {
    name      = "shopping-cart-svc"
    namespace = var.namespace
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"                = aws_acm_certificate_validation.app.certificate_arn
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"        = "http"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"               = "443"
      "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout" = "60"
    }
  }

  spec {
    selector = {
      app        = local.app_label
      tier       = "backend"
      phase      = "production"
      deployment = "v1"
    }

    type = "LoadBalancer"

    port {
      name        = "https"
      port        = 443
      target_port = 8070
      protocol    = "TCP"
    }
  }

  wait_for_load_balancer = true

  depends_on = [aws_acm_certificate_validation.app]
}

data "aws_elb_hosted_zone_id" "main" {}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "shop"
  type    = "A"

  alias {
    name                   = kubernetes_service_v1.app.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = true
  }
}
