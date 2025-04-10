terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26"
    }
  }
  required_version = ">= 1"
}
