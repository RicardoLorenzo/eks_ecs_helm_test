# EKS/ECR terraform+helm definition

Please provision the EKS cluster by executing the following:

```bash
cd scripts
bash docker_build
bash push_docker_image_to_ecr.sh
bash install.sh
```

## ECR and docker images


## Application deployment through Helm chart
The defined Helm chart will create the following:

* A k8s service account
* A k8s service which will listen in a TCP port (80 by default)
* A k8s deployment

This definition is comming by default when you create a Helm chart. The deployment can be sexucted by running the `bash install.sh` script.

**Note**: I have tested this against **minikube**.

**Service account**
```
$ kubectl describe serviceaccount application
Name:                application
Namespace:           default
Labels:              app.kubernetes.io/instance=application
                     app.kubernetes.io/managed-by=Helm
                     app.kubernetes.io/name=application
                     app.kubernetes.io/version=1.16.0
                     helm.sh/chart=application-0.1.0
Annotations:         meta.helm.sh/release-name: application
                     meta.helm.sh/release-namespace: default
Image pull secrets:  <none>
Mountable secrets:   application-token-vg4gq
Tokens:              application-token-vg4gq
Events:              <none>
```

**Service**
```
$ kubectl describe service application
Name:              application
Namespace:         default
Labels:            app.kubernetes.io/instance=application
                   app.kubernetes.io/managed-by=Helm
                   app.kubernetes.io/name=application
                   app.kubernetes.io/version=1.16.0
                   helm.sh/chart=application-0.1.0
Annotations:       meta.helm.sh/release-name: application
                   meta.helm.sh/release-namespace: default
Selector:          app.kubernetes.io/instance=application,app.kubernetes.io/name=application
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.106.58.190
IPs:               10.106.58.190
Port:              http  80/TCP
TargetPort:        http/TCP
Endpoints:         
Session Affinity:  None
Events:            <none>
```

**Deployment**
```
$ kubectl describe deployment application
Name:                   application
Namespace:              default
CreationTimestamp:      Sat, 17 Jul 2021 06:06:00 +0100
Labels:                 app.kubernetes.io/instance=application
                        app.kubernetes.io/managed-by=Helm
                        app.kubernetes.io/name=application
                        app.kubernetes.io/version=1.16.0
                        helm.sh/chart=application-0.1.0
Annotations:            deployment.kubernetes.io/revision: 1
                        meta.helm.sh/release-name: application
                        meta.helm.sh/release-namespace: default
Selector:               app.kubernetes.io/instance=application,app.kubernetes.io/name=application
Replicas:               1 desired | 1 updated | 1 total | 0 available | 1 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:           app.kubernetes.io/instance=application
                    app.kubernetes.io/name=application
  Service Account:  application
  Containers:
   application:
    Image:        804731442997.dkr.ecr.eu-west-1.amazonaws.com/app-test:latest
    Port:         8080/TCP
    Host Port:    0/TCP
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    False   ProgressDeadlineExceeded
OldReplicaSets:  <none>
NewReplicaSet:   application-5b7dd9d9f7 (1/1 replicas created)
Events:          <none>
```

Optionally, an horizontal pod autoscaller can be created if you enable it in the Helm values by parameters or by modifying the `values.yaml` file.

```
autoscaling:
  enabled: false
```

## Terraform

### VPC
One VPC will be automatically created after running terraform. The VPC contains two subnets (**internal** and **public**) each will be dynamically associated with internal and external load balancers as per the defined tag.

### EKS cluster
The Elastic Cloud Kubernetes cluster will be automatically created after running terraform. The terraform output will provide the **KUBECONFIG** file necesary to connect to the cluster using `kubectl` or `helm`.

The cluster has a defined node group with instances of a scpecific type with a specific scaling configuration.

### AWS Load Balancer Controller

The AWS Load Balancer Controller manages AWS Elastic Load Balancers for a Kubernetes cluster. The controller provisions the following resources.

* An AWS Application Load Balancer (ALB) when you create a Kubernetes Ingress.
* An AWS Network Load Balancer (NLB) when you create a Kubernetes Service of type LoadBalancer

The resources defined in `alb.tf` file will create a role with the necessary permissions to manage the load balancer. The terraform output will present the kubernetes ServiceAccount definition.

For installing the load balancer controller in the EKS cluster, you can do the following:

```
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --set clusterName=YOUR_CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set region=<REGION_CODE> \
    --set vpcId=<VPC_ID> \
    --set serviceAccount.name=aws-load-balancer-controller \
    -n kube-system
```

### Plan

```
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.aws_iam_policy_document.eks_ricardo_oidc_policy_document will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "eks_ricardo_oidc_policy_document"  {
      + id   = (known after apply)
      + json = (known after apply)

      + statement {
          + actions = [
              + "sts:AssumeRoleWithWebIdentity",
            ]
          + effect  = "Allow"

          + condition {
              + test     = "StringEquals"
              + values   = [
                  + "system:serviceaccount:default:aws-load-balancer-controller",
                ]
              + variable = (known after apply)
            }

          + principals {
              + identifiers = [
                  + (known after apply),
                ]
              + type        = "Federated"
            }
        }
    }

  # aws_eip.eks_ricardo_vpc_nat_eip will be created
  + resource "aws_eip" "eks_ricardo_vpc_nat_eip" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Name" = "ricardo-eks-vpc-nat-eip"
        }
      + tags_all             = {
          + "Name" = "ricardo-eks-vpc-nat-eip"
        }
      + vpc                  = (known after apply)
    }

  # aws_eks_cluster.eks_ricardo will be created
  + resource "aws_eks_cluster" "eks_ricardo" {
      + arn                   = (known after apply)
      + certificate_authority = (known after apply)
      + created_at            = (known after apply)
      + endpoint              = (known after apply)
      + id                    = (known after apply)
      + identity              = (known after apply)
      + name                  = "ricardo-eks"
      + platform_version      = (known after apply)
      + role_arn              = (known after apply)
      + status                = (known after apply)
      + tags_all              = (known after apply)
      + version               = (known after apply)

      + kubernetes_network_config {
          + service_ipv4_cidr = (known after apply)
        }

      + vpc_config {
          + cluster_security_group_id = (known after apply)
          + endpoint_private_access   = false
          + endpoint_public_access    = true
          + public_access_cidrs       = (known after apply)
          + subnet_ids                = (known after apply)
          + vpc_id                    = (known after apply)
        }
    }

  # aws_eks_node_group.eks_ricardo_ng will be created
  + resource "aws_eks_node_group" "eks_ricardo_ng" {
      + ami_type               = (known after apply)
      + arn                    = (known after apply)
      + capacity_type          = (known after apply)
      + cluster_name           = "ricardo-eks"
      + disk_size              = (known after apply)
      + id                     = (known after apply)
      + instance_types         = [
          + "t2.micro",
        ]
      + node_group_name        = "ricardo-eks-ng"
      + node_group_name_prefix = (known after apply)
      + node_role_arn          = (known after apply)
      + release_version        = (known after apply)
      + resources              = (known after apply)
      + status                 = (known after apply)
      + subnet_ids             = (known after apply)
      + tags_all               = (known after apply)
      + version                = (known after apply)

      + scaling_config {
          + desired_size = 1
          + max_size     = 1
          + min_size     = 1
        }
    }

  # aws_iam_policy.eks_ricardo_lb_management_policy will be created
  + resource "aws_iam_policy" "eks_ricardo_lb_management_policy" {
      + arn         = (known after apply)
      + description = "Permissions that are required to manage AWS Application Load Balancers."
      + id          = (known after apply)
      + name        = "ricardo-eks-lb-management-policy"
      + path        = "/"
      + policy      = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "iam:CreateServiceLinkedRole",
                          + "ec2:DescribeAccountAttributes",
                          + "ec2:DescribeAddresses",
                          + "ec2:DescribeAvailabilityZones",
                          + "ec2:DescribeInternetGateways",
                          + "ec2:DescribeVpcs",
                          + "ec2:DescribeSubnets",
                          + "ec2:DescribeSecurityGroups",
                          + "ec2:DescribeInstances",
                          + "ec2:DescribeNetworkInterfaces",
                          + "ec2:DescribeTags",
                          + "ec2:GetCoipPoolUsage",
                          + "ec2:DescribeCoipPools",
                          + "elasticloadbalancing:DescribeLoadBalancers",
                          + "elasticloadbalancing:DescribeLoadBalancerAttributes",
                          + "elasticloadbalancing:DescribeListeners",
                          + "elasticloadbalancing:DescribeListenerCertificates",
                          + "elasticloadbalancing:DescribeSSLPolicies",
                          + "elasticloadbalancing:DescribeRules",
                          + "elasticloadbalancing:DescribeTargetGroups",
                          + "elasticloadbalancing:DescribeTargetGroupAttributes",
                          + "elasticloadbalancing:DescribeTargetHealth",
                          + "elasticloadbalancing:DescribeTags",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action   = [
                          + "cognito-idp:DescribeUserPoolClient",
                          + "acm:ListCertificates",
                          + "acm:DescribeCertificate",
                          + "iam:ListServerCertificates",
                          + "iam:GetServerCertificate",
                          + "waf-regional:GetWebACL",
                          + "waf-regional:GetWebACLForResource",
                          + "waf-regional:AssociateWebACL",
                          + "waf-regional:DisassociateWebACL",
                          + "wafv2:GetWebACL",
                          + "wafv2:GetWebACLForResource",
                          + "wafv2:AssociateWebACL",
                          + "wafv2:DisassociateWebACL",
                          + "shield:GetSubscriptionState",
                          + "shield:DescribeProtection",
                          + "shield:CreateProtection",
                          + "shield:DeleteProtection",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action   = [
                          + "ec2:AuthorizeSecurityGroupIngress",
                          + "ec2:RevokeSecurityGroupIngress",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action   = [
                          + "ec2:CreateSecurityGroup",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action    = [
                          + "ec2:CreateTags",
                        ]
                      + Condition = {
                          + Null         = {
                              + aws:RequestTag/elbv2.k8s.aws/cluster = "false"
                            }
                          + StringEquals = {
                              + ec2:CreateAction = "CreateSecurityGroup"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:ec2:*:*:security-group/*"
                    },
                  + {
                      + Action    = [
                          + "ec2:CreateTags",
                          + "ec2:DeleteTags",
                        ]
                      + Condition = {
                          + Null = {
                              + aws:RequestTag/elbv2.k8s.aws/cluster  = "true"
                              + aws:ResourceTag/elbv2.k8s.aws/cluster = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:ec2:*:*:security-group/*"
                    },
                  + {
                      + Action    = [
                          + "ec2:AuthorizeSecurityGroupIngress",
                          + "ec2:RevokeSecurityGroupIngress",
                          + "ec2:DeleteSecurityGroup",
                        ]
                      + Condition = {
                          + Null = {
                              + aws:ResourceTag/elbv2.k8s.aws/cluster = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:CreateLoadBalancer",
                          + "elasticloadbalancing:CreateTargetGroup",
                        ]
                      + Condition = {
                          + Null = {
                              + aws:RequestTag/elbv2.k8s.aws/cluster = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                    },
                  + {
                      + Action   = [
                          + "elasticloadbalancing:CreateListener",
                          + "elasticloadbalancing:DeleteListener",
                          + "elasticloadbalancing:CreateRule",
                          + "elasticloadbalancing:DeleteRule",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:AddTags",
                          + "elasticloadbalancing:RemoveTags",
                        ]
                      + Condition = {
                          + Null = {
                              + aws:RequestTag/elbv2.k8s.aws/cluster  = "true"
                              + aws:ResourceTag/elbv2.k8s.aws/cluster = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = [
                          + "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
                        ]
                    },
                  + {
                      + Action   = [
                          + "elasticloadbalancing:AddTags",
                          + "elasticloadbalancing:RemoveTags",
                        ]
                      + Effect   = "Allow"
                      + Resource = [
                          + "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
                        ]
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:ModifyLoadBalancerAttributes",
                          + "elasticloadbalancing:SetIpAddressType",
                          + "elasticloadbalancing:SetSecurityGroups",
                          + "elasticloadbalancing:SetSubnets",
                          + "elasticloadbalancing:DeleteLoadBalancer",
                          + "elasticloadbalancing:ModifyTargetGroup",
                          + "elasticloadbalancing:ModifyTargetGroupAttributes",
                          + "elasticloadbalancing:DeleteTargetGroup",
                        ]
                      + Condition = {
                          + Null = {
                              + aws:ResourceTag/elbv2.k8s.aws/cluster = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                    },
                  + {
                      + Action   = [
                          + "elasticloadbalancing:RegisterTargets",
                          + "elasticloadbalancing:DeregisterTargets",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
                    },
                  + {
                      + Action   = [
                          + "elasticloadbalancing:SetWebAcl",
                          + "elasticloadbalancing:ModifyListener",
                          + "elasticloadbalancing:AddListenerCertificates",
                          + "elasticloadbalancing:RemoveListenerCertificates",
                          + "elasticloadbalancing:ModifyRule",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id   = (known after apply)
      + tags_all    = (known after apply)
    }

  # aws_iam_role.eks_ricardo_lb_management_role will be created
  + resource "aws_iam_role" "eks_ricardo_lb_management_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = (known after apply)
      + create_date           = (known after apply)
      + description           = "Permissions required by the Kubernetes AWS Load Balancer controller to do its job."
      + force_detach_policies = true
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "ricardo-eks-lb-management-role"
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy {
          + name   = (known after apply)
          + policy = (known after apply)
        }
    }

  # aws_iam_role.eks_ricardo_node_role will be created
  + resource "aws_iam_role" "eks_ricardo_node_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "ec2.amazonaws.com"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "ricardo-eks-node-role"
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy {
          + name   = (known after apply)
          + policy = (known after apply)
        }
    }

  # aws_iam_role.eks_ricardo_role will be created
  + resource "aws_iam_role" "eks_ricardo_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "eks.amazonaws.com"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "ricardo-eks-role"
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy {
          + name   = (known after apply)
          + policy = (known after apply)
        }
    }

  # aws_iam_role_policy_attachment.eks_ricardo_cni_policy will be created
  + resource "aws_iam_role_policy_attachment" "eks_ricardo_cni_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      + role       = "ricardo-eks-node-role"
    }

  # aws_iam_role_policy_attachment.eks_ricardo_lb_management_policy_attachment will be created
  + resource "aws_iam_role_policy_attachment" "eks_ricardo_lb_management_policy_attachment" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "ricardo-eks-lb-management-role"
    }

  # aws_iam_role_policy_attachment.eks_ricardo_node_policy will be created
  + resource "aws_iam_role_policy_attachment" "eks_ricardo_node_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      + role       = "ricardo-eks-node-role"
    }

  # aws_iam_role_policy_attachment.eks_ricardo_policy will be created
  + resource "aws_iam_role_policy_attachment" "eks_ricardo_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      + role       = "ricardo-eks-role"
    }

  # aws_iam_role_policy_attachment.eks_ricardo_registry_policy will be created
  + resource "aws_iam_role_policy_attachment" "eks_ricardo_registry_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      + role       = "ricardo-eks-node-role"
    }

  # aws_iam_role_policy_attachment.eks_ricardo_vpc_policy will be created
  + resource "aws_iam_role_policy_attachment" "eks_ricardo_vpc_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      + role       = "ricardo-eks-role"
    }

  # aws_internet_gateway.eks_ricardo_vpc_ig will be created
  + resource "aws_internet_gateway" "eks_ricardo_vpc_ig" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Name" = "ricardo-eks-vpc-ig"
        }
      + tags_all = {
          + "Name" = "ricardo-eks-vpc-ig"
        }
      + vpc_id   = (known after apply)
    }

  # aws_nat_gateway.nat[0] will be created
  + resource "aws_nat_gateway" "nat" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Name" = "ricardo-eks-vpc-nat-gw"
        }
      + tags_all             = {
          + "Name" = "ricardo-eks-vpc-nat-gw"
        }
    }

  # aws_nat_gateway.nat[1] will be created
  + resource "aws_nat_gateway" "nat" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Name" = "ricardo-eks-vpc-nat-gw"
        }
      + tags_all             = {
          + "Name" = "ricardo-eks-vpc-nat-gw"
        }
    }

  # aws_nat_gateway.nat[2] will be created
  + resource "aws_nat_gateway" "nat" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Name" = "ricardo-eks-vpc-nat-gw"
        }
      + tags_all             = {
          + "Name" = "ricardo-eks-vpc-nat-gw"
        }
    }

  # aws_route_table.eks_ricardo_vpc_ig_table will be created
  + resource "aws_route_table" "eks_ricardo_vpc_ig_table" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + carrier_gateway_id         = ""
              + cidr_block                 = "0.0.0.0/0"
              + destination_prefix_list_id = ""
              + egress_only_gateway_id     = ""
              + gateway_id                 = (known after apply)
              + instance_id                = ""
              + ipv6_cidr_block            = ""
              + local_gateway_id           = ""
              + nat_gateway_id             = ""
              + network_interface_id       = ""
              + transit_gateway_id         = ""
              + vpc_endpoint_id            = ""
              + vpc_peering_connection_id  = ""
            },
        ]
      + tags_all         = (known after apply)
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.eks_ricardo_vpc_ig_table_internal[0] will be created
  + resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_internal" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.eks_ricardo_vpc_ig_table_internal[1] will be created
  + resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_internal" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.eks_ricardo_vpc_ig_table_internal[2] will be created
  + resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_internal" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.eks_ricardo_vpc_ig_table_public[0] will be created
  + resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.eks_ricardo_vpc_ig_table_public[1] will be created
  + resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.eks_ricardo_vpc_ig_table_public[2] will be created
  + resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_subnet.eks_ricardo_vpc_internal_subnet[0] will be created
  + resource "aws_subnet" "eks_ricardo_vpc_internal_subnet" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.0.0.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/internal-elb"   = "1"
        }
      + tags_all                        = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/internal-elb"   = "1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.eks_ricardo_vpc_internal_subnet[1] will be created
  + resource "aws_subnet" "eks_ricardo_vpc_internal_subnet" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.0.1.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/internal-elb"   = "1"
        }
      + tags_all                        = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/internal-elb"   = "1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.eks_ricardo_vpc_internal_subnet[2] will be created
  + resource "aws_subnet" "eks_ricardo_vpc_internal_subnet" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-1c"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.0.2.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/internal-elb"   = "1"
        }
      + tags_all                        = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/internal-elb"   = "1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.eks_ricardo_vpc_public_subnet[0] will be created
  + resource "aws_subnet" "eks_ricardo_vpc_public_subnet" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.0.100.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/elb"            = "1"
        }
      + tags_all                        = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/elb"            = "1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.eks_ricardo_vpc_public_subnet[1] will be created
  + resource "aws_subnet" "eks_ricardo_vpc_public_subnet" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.0.101.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/elb"            = "1"
        }
      + tags_all                        = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/elb"            = "1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.eks_ricardo_vpc_public_subnet[2] will be created
  + resource "aws_subnet" "eks_ricardo_vpc_public_subnet" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-1c"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.0.102.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/elb"            = "1"
        }
      + tags_all                        = {
          + "Name"                              = "ricardo-eks-vpc-subnet"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
          + "kubernetes.io/role/elb"            = "1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_vpc.eks_ricardo_vpc will be created
  + resource "aws_vpc" "eks_ricardo_vpc" {
      + arn                              = (known after apply)
      + assign_generated_ipv6_cidr_block = false
      + cidr_block                       = "10.0.0.0/16"
      + default_network_acl_id           = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_group_id        = (known after apply)
      + dhcp_options_id                  = (known after apply)
      + enable_classiclink               = (known after apply)
      + enable_classiclink_dns_support   = (known after apply)
      + enable_dns_hostnames             = (known after apply)
      + enable_dns_support               = true
      + id                               = (known after apply)
      + instance_tenancy                 = "default"
      + ipv6_association_id              = (known after apply)
      + ipv6_cidr_block                  = (known after apply)
      + main_route_table_id              = (known after apply)
      + owner_id                         = (known after apply)
      + tags                             = {
          + "Name"                              = "ricardo-eks-vpc"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
        }
      + tags_all                         = {
          + "Name"                              = "ricardo-eks-vpc"
          + "kubernetes.io/cluster/ricardo-eks" = "shared"
        }
    }

Plan: 31 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + aws_load_balancer_controller_service_account = (known after apply)
  + config_map_aws_auth                          = (known after apply)
  + kubeconfig                                   = (known after apply)
```
