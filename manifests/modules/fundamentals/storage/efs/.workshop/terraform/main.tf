module "efs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-efs-csi-"

  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  eks_cluster_id = var.eks_cluster_id
  tags           = var.tags
}

output "environment" {
  description = "Evaluated by the IDE shell"
  value       = <<EOF
export EFS_CSI_ADDON_ROLE="${module.efs_csi_driver_irsa.iam_role_arn}"
EOF
}
