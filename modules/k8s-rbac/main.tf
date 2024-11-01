# Data sources for EKS cluster
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


resource "kubernetes_cluster_role" "common_fate_readonly" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "common-fate-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }
}


resource "kubernetes_cluster_role" "common_fate_admin" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "common-fate-admin"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}


resource "kubernetes_cluster_role_binding" "readonly_binding" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "common-fate-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.common_fate_readonly.metadata.name
  }

  subject {
    kind      = "User"
    name      = "common-fate-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
}


resource "kubernetes_cluster_role_binding" "admin_binding" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "common-fate-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.common_fate_admin.metadata.name
  }

  subject {
    kind      = "User"
    name      = "common-fate-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}


