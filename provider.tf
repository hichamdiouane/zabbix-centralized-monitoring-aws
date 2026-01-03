terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Pour AWS Academy Learner Lab, vous devez configurer les credentials
  # via les variables d'environnement ou le fichier ~/.aws/credentials
}
