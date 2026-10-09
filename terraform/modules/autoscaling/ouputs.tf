output "asg_arn" {
  value = aws_autoscaling_group.this.arn
}

output "asg_name" {
  value = aws_autoscaling_group.this.name
}