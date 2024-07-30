
variable "nlb_eip_allocations" {
  description = "List of AWS eip id list"
  type = list(string)
}

variable "nlb_ssl_cert_arn" {
  description = "AWS acm sertificate ARN"
  type = list(string)
}

variable "pod_resource_cpu" {
  description = "ingress-gateways pod resource cpu limit and request"
  type = string
  default = "100m"
}

variable "pod_resource_memory" {
  description = "ingress-gateways pod resource memory limit and request"
  type = string
  default = "128Mi"
}

# variable "spec_virtual_service" {
#   description = "virtualService spec"
#   type = string
#   default = null
# }

# variable "spec_gateway" {
#   description = "gateway spec"
#   type = string
#   default = null
# }

locals {
  eip_allocations = join(",", var.nlb_eip_allocations)
  ssl_cert_arn = join(",", var.nlb_ssl_cert_arn)
  resource = {
    cpu = var.pod_resource_cpu
    memory = var.pod_resource_memory
  }
  namespace = {
    system = "istio-system"
    ingress = "istio-ingress"
  }
}

resource "helm_release" "istio_base" {
  namespace = local.namespace.system
  create_namespace = true

  name = "istio-base"
  chart = "base"
  version = "1.22.3"
  repository = "https://istio-release.storage.googleapis.com/charts"
}

resource "helm_release" "istio_cni" {
  namespace = local.namespace.system
  create_namespace = true

  name = "istio-cni"
  chart = "cni"
  version = "1.22.3"
  repository = "https://istio-release.storage.googleapis.com/charts"
  values = [
    <<-EOT
    global:
      imagePullPolicy: IfNotPresent
    profile: ambient
    EOT
  ]

  depends_on = [ helm_release.istio_base ]
}

resource "helm_release" "istio_istiod" {
  namespace = local.namespace.system
  create_namespace = true

  name = "istiod"
  chart = "istiod"
  version = "1.22.3"
  repository = "https://istio-release.storage.googleapis.com/charts"
  values = [
    <<-EOT
    global:
      imagePullPolicy: IfNotPresent
    profile: ambient
    EOT
  ]

  depends_on = [ helm_release.istio_cni ]
}

resource "helm_release" "istio_ztunnel" {
  namespace = local.namespace.system
  create_namespace = true

  name = "ztunnel"
  chart = "ztunnel"
  version = "1.22.3"
  repository = "https://istio-release.storage.googleapis.com/charts"
  values = [
    <<-EOT
    imagePullPolicy: IfNotPresent
    EOT
  ]
  depends_on = [ helm_release.istio_istiod ]
}

resource "helm_release" "istio_ingress" {
  namespace = local.namespace.ingress
  create_namespace = true

  name = "istio-ingress"
  chart = "gateway"
  version = "1.22.3"
  repository = "https://istio-release.storage.googleapis.com/charts"
  values = [
    <<-EOT
    imagePullPolicy: IfNotPresent
    defaults:
      resources:
        limits:
          cpu: ${local.resource.cpu}
          memory: ${local.resource.memory}
        requests:
          cpu: ${local.resource.cpu}
          memory: ${local.resource.memory}
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
          service.beta.kubernetes.io/aws-load-balancer-eip-allocations: ${local.eip_allocations}
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
          service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${local.ssl_cert_arn}
          service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
          service.beta.kubernetes.io/aws-load-balancer-type: external
        ports:
          - name: status-port
            port: 15021
            protocol: TCP
            targetPort: 15021
          - name: http2
            port: 80
            protocol: TCP
            targetPort: 80
          - name: https
            port: 443
            protocol: TCP
            targetPort: 443
    EOT
  ]

  depends_on = [ helm_release.istio_ztunnel ]
}
