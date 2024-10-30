terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26"
    }
  }
  required_version = ">= 1"
}
