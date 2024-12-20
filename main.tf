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



data "aws_eks_cluster" "this" {
  name = var.cluster_name
}


resource "aws_iam_role" "proxy_eks_cluster_access_role" {
  name        = "${var.namespace}-${var.stage}-integration-proxy-eks-cluster-access-role"
  description = "A role used by the proxy to access the eks cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = local.aws_account_id
        }
      }
    ]
  })
  tags = {
    "common-fate-aws-proxy-access-role" = "true"
  }
}


//allow proxy to describe cluster
resource "aws_iam_policy" "eks_cluster_access" {
  // use a name prefix so that multiple or this module may be deployed
  name_prefix = "${var.namespace}-${var.stage}-describe-cluster"
  description = "Allow the Common Fate AWS EKS Proxy (${var.proxy_id}) access to the cluster"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        "Action" : [
          "eks:DescribeCluster"
        ],
        "Resource" : data.aws_eks_cluster.this.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_access_attach" {
  role       = aws_iam_role.proxy_eks_cluster_access_role.name
  policy_arn = aws_iam_policy.eks_cluster_access.arn
}


//create the access entry for the new role
resource "aws_eks_access_entry" "proxy_access_entry" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.proxy_eks_cluster_access_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "policy_association" {
  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.proxy_eks_cluster_access_role.arn
  access_scope {
    type = "cluster"
  }
}

//create the CF resources
resource "commonfate_proxy_eks_cluster" "cluster" {
  proxy_id                 = var.proxy_id
  name                     = var.name == "" ? var.cluster_name : var.name
  region                   = local.aws_region
  aws_account_id           = local.aws_account_id
  cluster_name             = var.cluster_name
  cluster_access_role_name = aws_iam_role.proxy_eks_cluster_access_role.name
}


