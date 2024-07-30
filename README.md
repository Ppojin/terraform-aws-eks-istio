# terraform-aws-eks-istio

## Providers
- [helm-provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| nlb_eip_allocations | List of AWS eip id list | `list(string)` | n/a | yes |
| nlb_ssl_cert_arn | AWS acm sertificate ARN | `string` | n/a | yes |
| pod_resource_cpu | ingress-gateways pod resource cpu limit and request | `string` | 100m | no |
| pod_resource_memory | ingress-gateways pod resource memory limit and request | `string` | 128Mi | no |

## Dependency
- [aws-load-balancer-controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller)
