
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}


resource "kubernetes_cluster_role" "common_fate_readonly" {

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

  metadata {
    name = "common-fate-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.common_fate_readonly.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "common-fate-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
}


resource "kubernetes_cluster_role_binding" "admin_binding" {
  metadata {
    name = "common-fate-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.common_fate_admin.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "common-fate-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}


