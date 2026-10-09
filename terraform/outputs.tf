output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "frontend_ecr_url" {
  value = module.ecr.frontend_repository_url
}

output "backend_ecr_url" {
  value = module.ecr.backend_repository_url
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "autoscaling_group_name" {
  value = module.autoscaling.asg_name
}

output "capacity_provider_name" {
  value = module.capacity_provider.capacity_provider_name
}

output "frontend_service_name" {
  value = module.ecs_service.frontend_service_name
}

output "backend_service_name" {
  value = module.ecs_service.backend_service_name
}