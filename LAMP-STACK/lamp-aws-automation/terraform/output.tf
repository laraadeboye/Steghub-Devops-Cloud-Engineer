output "db_instance_endpoint" {
  description = "The connection endpoint for the database"
  value       = aws_db_instance.lamp_db_primary.endpoint
}

output "db_replica_endpoint" {
  description = "The connection endpoint for the RDS read replica"
  value       = aws_db_instance.lamp_db_replica.endpoint
}

# This data source allows us to get information about the instances in the ASG
data "aws_instances" "asg_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.web_asg.name
  }

  instance_state_names = ["running", "pending"]

  depends_on = [aws_autoscaling_group.web_asg]
}

output "asg_instance_ids" {
  description = "The IDs of the instances in the Auto Scaling Group"
  value       = data.aws_instances.asg_instances.ids
}

output "asg_instance_public_ips" {
  description = "The public IPs of the instances in the Auto Scaling Group"
  value       = data.aws_instances.asg_instances.public_ips
}