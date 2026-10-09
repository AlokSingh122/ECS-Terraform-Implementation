locals {
  name = "${var.project_name}-${var.environment}"
}

data "aws_instances" "ecs_instance" {
  instance_state_names = ["running"]

  filter {
    name   = "tag:Name"
    values = ["${local.name}-ecs-instance"]
  }

  depends_on = [module.autoscaling]
}

module "networking" {
  source = "./modules/networking"

  name                = local.name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "security" {
  source = "./modules/security"

  name   = local.name
  vpc_id = module.networking.vpc_id
}

module "iam" {
  source = "./modules/iam"

  name = local.name
}

module "ecr" {
  source = "./modules/ecr"

  name = local.name
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  name = local.name
}

module "launch_template" {
  source = "./modules/launch-template"

  name                  = local.name
  instance_type         = var.instance_type
  security_group_id     = module.security.ecs_instance_sg_id
  instance_profile_name = module.iam.instance_profile_name
  ecs_cluster_name      = module.ecs_cluster.cluster_name
}

module "autoscaling" {
  source = "./modules/autoscaling"

  name                    = local.name
  launch_template_id      = module.launch_template.launch_template_id
  launch_template_version = module.launch_template.latest_version
  subnet_ids              = module.networking.public_subnet_ids
  min_size                = var.min_size
  desired_capacity        = var.desired_capacity
  max_size                = var.max_size
}

module "capacity_provider" {
  source = "./modules/capacity-provider"

  name                  = local.name
  cluster_name          = module.ecs_cluster.cluster_name
  autoscaling_group_arn = module.autoscaling.asg_arn
}

module "ecs_service" {
  source = "./modules/ecs-service"

  name                    = local.name
  cluster_arn             = module.ecs_cluster.cluster_arn
  task_execution_role_arn = module.iam.task_execution_role_arn
  capacity_provider_name  = module.capacity_provider.capacity_provider_name
  frontend_image          = "${module.ecr.frontend_repository_url}:${var.frontend_image_tag}"
  backend_image           = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"
  backend_url             = "http://${data.aws_instances.ecs_instance.public_ips[0]}:5000"

  depends_on = [
    module.capacity_provider
  ]
}