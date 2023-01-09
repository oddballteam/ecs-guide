locals {
  vpc_name = "wdsops-east-dev"
}

provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = ["879613780019"]
}

terraform {
  backend "local" {
    path = ".tfstate/status-page.tfstate"
  }
}

# module "backend" {
#   source      = "../../../modules/backend"
#   bucket_name = "status-page-tfstate"
#   table_name  = "status-page-tflock"
# }

data "aws_caller_identity" "current" {}

module "dns" {
  source = "git::ssh://git@origin-github.cms.gov:2222/OC-Foundational/ocf-shared.git//modules/dns?ref=08a08880896722fa5b7da58e4a0b9cda231c9402"
  vpc_name  = local.vpc_name
  zone_name = "${var.name}-test" # route53 zone
}

module "cluster" {
  source = "git::ssh://git@origin-github.cms.gov:2222/OC-Foundational/ocf-shared.git//modules/ecs_cluster?ref=08a08880896722fa5b7da58e4a0b9cda231c9402"
  account      = data.aws_caller_identity.current.account_id
  vpc_name     = local.vpc_name
  cluster_name = "${var.name}-test"
}

# artifactory does not currently work with greenfield
# https://jira.cms.gov/browse/CBJ-6537
# module "artifactory_creds" {
#   source = "../../../modules/artifactory_creds"
#   account  = data.aws_caller_identity.current.account_id
#   username = local.name
# }

module "service" {
  source = "git::ssh://git@origin-github.cms.gov:2222/OC-Foundational/ocf-shared.git//modules/ecs_service?ref=08a08880896722fa5b7da58e4a0b9cda231c9402"
  account               = data.aws_caller_identity.current.account_id
  vpc_name              = local.vpc_name
  cluster_name          = module.cluster.cluster_name
  cluster_arn           = module.cluster.cluster_arn
  artifactory_creds_arn = "arn:aws:secretsmanager:us-east-1:879613780019:secret:artifactory-credential-xkln7A"
  service_name          = "${var.name}-test"
  zone_id               = module.dns.zone_id
  zone_name             = module.dns.zone_name
  lb_ingress_cidrs      = []
  app_port              = 80
  lb_port               = 80
  healthcheck_protocol  = "HTTP"
  healthcheck_path      = "/_health"
  healthcheck_matcher   = 200
  task_min              = 1
  task_max              = 2
  cpu_target            = 60
  memory_target         = 60
}

variable "name" {
  type = string
  default = "doug-lab"
}