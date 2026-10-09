output "instance_profile_name" {
  value = aws_iam_instance_profile.ecs_instance.name
}

output "task_execution_role_arn" {
  value = aws_iam_role.task_execution.arn
}