terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data block to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data block to get the default public subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data block to get the default private subnets (if needed)
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.default.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # Use the default VPC ID
  vpc_id = data.aws_vpc.default.id

  # Use the default public and private subnets
  control_plane_subnet_ids = data.aws_subnets.default.ids
  subnet_ids               = data.aws_subnet_ids.private.ids

  eks_managed_node_group_defaults = {
    instance_types = ["t2.micro"]
  }

  eks_managed_node_groups = {
    example = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t2.micro"]
    }
  }

  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

