resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-ecs-asg"
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids

  health_check_type = "EC2"

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-ecs-instance"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity, tag]
  }
}