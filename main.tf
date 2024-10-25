terraform {
  required_providers {
    commonfate = {
      source  = "common-fate/commonfate"
      version = ">= 2.25.3, < 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
data "aws_region" "current" {}


data "aws_caller_identity" "current" {}
locals {
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
}


//data source to look up proxy that has already been registered
data "commonfate_ecs_proxy" "proxy_data" {
  id = var.proxy_id
}



data "aws_eks_cluster" "eks-cluster" {
  name = var.cluster_name
}


resource "commonfate_proxy_eks_cluster" "cluster" {
  proxy_id                 = var.proxy_id
  name                     = var.name == "" ? var.cluster_name : var.name
  region                   = local.aws_region
  aws_account_id           = local.aws_account_id
  cluster_name             = var.name
  cluster_access_role_name = data.aws_eks_cluster.eks-cluster.role_arn
  users                    = var.users
}

//allow proxy to describe cluster
resource "aws_iam_policy" "eks_describe_cluster" {
  // use a name prefix so that multiple or this module may be deployed
  name_prefix = "${var.namespace}-${var.stage}-describe-cluster"
  description = "Allow the Common Fate AWS EKS Proxy (${var.proxy_id}) to describe clusters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        "Action" : [
          "eks:DescribeCluster"
        ],
        "Resource" : data.aws_eks_cluster.eks-cluster.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "describe_cluster" {
  role       = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_task_role_name
  policy_arn = aws_iam_policy.eks_describe_cluster.arn
}



data "aws_iam_role" "proxy_task_role" {
  name = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_task_role_name
}

//create the access entry for the new role
resource "aws_eks_access_entry" "proxy_access_entry" {
  cluster_name      = var.cluster_name
  kubernetes_groups = [""]
  principal_arn     = data.aws_iam_role.proxy_task_role.arn
  type              = "STANDARD"
}


//make the default rbac roles for the cluster to allow for the service account access
module "k8s_rbac" {
  source       = "./modules/k8s-rbac"
  cluster_name = var.cluster_name
}
