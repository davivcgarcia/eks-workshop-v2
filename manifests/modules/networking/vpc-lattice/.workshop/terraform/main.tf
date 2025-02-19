module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.9.2"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn
}

module "iam_assumable_role_lattice" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.5.5"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-lattice"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.lattice.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:gateway-api-controller:gateway-api-controller"]

  tags = var.tags
}

resource "aws_iam_policy" "lattice" {
  name        = "${var.addon_context.eks_cluster_id}-lattice"
  path        = "/"
  description = "Policy for Lattice controller"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "vpc-lattice:*",
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeSecurityGroups",
                "logs:CreateLogDelivery",
                "logs:GetLogDelivery",
                "logs:UpdateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:ListLogDeliveries",
                "tag:GetResources"
            ],
            "Resource": "*"
        }
    ]
}
EOF
  tags   = var.tags
}

data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

output "environment" {
  description = "Evaluated by the IDE shell"
  value       = <<EOF
export VPC_ID=${data.aws_vpc.this.id}
export LATTICE_IAM_ROLE="${module.iam_assumable_role_lattice.iam_role_arn}"
EOF
}
