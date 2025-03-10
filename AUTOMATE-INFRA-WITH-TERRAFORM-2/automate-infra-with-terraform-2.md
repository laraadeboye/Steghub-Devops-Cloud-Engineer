
# AUTOMATE INFRASTRUCTURE PROVISIONING ON AWS PLATFORM WITH TERRAFORM 2

![automate infra with terraform](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AUTOMATE-INFRA-WITH-TERRAFORM-2/images/automate%20infra%20with%20terraform.drawio.png)

Here, I go further by creating the remaining networking resources:
- Internet gateway
- Elastic IP and Nat gateway
-AWS routes and route tables.

The Internet gateway and NAT gateway are created in separate files named `internet_gateway.tf` and `natgateway.tf`

- I used the string interpolation and format() function to tag the resources and merge() function to assign multiple tags.

- The element() function to assign the subnet id
After running `terraform plan`, we see the resources to be created:
![terraform plan_networking](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AUTOMATE-INFRA-WITH-TERRAFORM-2/images/terraform%20plan_networking.png)
![terraform plan_networking_1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AUTOMATE-INFRA-WITH-TERRAFORM-2/images/terraform%20plan_networking_1.png)
![terraform plan_networking_2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AUTOMATE-INFRA-WITH-TERRAFORM-2/images/terraform%20plan_networking_2.png)

When we run `terraform apply`, 20 resources are created.

![terraform apply_20resources](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AUTOMATE-INFRA-WITH-TERRAFORM-2/images/terraform%20apply_20resources.png)

The code is found in this [repo](https://github.com/laraadeboye/PBL/blob/main/internet_gateway.tf)

Next, I create the access control configuration and compute resources with terraform:

**Access control configuration:**
- Create a separate file named `roles.tf`
- Create an IAM role for EC2 instances to have access to specific resources. We will do this by creating an `AssumeRole`, creating a policy for the role, attach the policy to the role and create an instance profile

The code is found in this [repo](https://github.com/laraadeboye/PBL/blob/main/roles.tf)


**Compute Resources with terraform**
The following resources will be created based on our architecture:
- Security groups
- Certificate from Amazon Certificate Manager
- External Load Balancer and Internal Load Balancer
- Target group and listeners for Nginx reverse proxy, Wordpress and Tooling website
- Launch templates and Autoscaling group for bastion, tooling, nginxx and Wordpress
- Datalayer: Elastic Filesystem and Relational Database (RDS)


1. **Security groups**
I will create the security groups in a single file named `security.tf`. 
The security group will be referenced within each resource that needs it using the [terraform aws security group rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule). It allows rules to be added/removed without modifying the main security group

- Security group for external Application load balancer (`ext_alb_sg`)

- Security group for bastion (`bastion_sg`). The port range is too broad for now, We can later adjust it with our specific IP range in a production environment.

- Security group for nginx reverse proxy (`nginx_sg`). 

- Security group for internal Application load balancer (`int_alb_sg`)

- Security group for webservers (`webserver_sg`)

- Security group for datalayer: EFS and RDS
(`datalayer_sg`)

2. **Certificate from Amazon Certificate Manager**
Ensure you have a registered domain. Create a file named `cert.tf` and create a certificate on AWS, public zone and validate the certificate using DNS method.
An example block for creating the public zone, if not already created:

```tf
# Create the Route53 hosted zone
resource "aws_route53_zone" "laraadeboye" {
  name = "laraadeboye.com"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-hosted-zone"
    }
  )
}

```

In my terraform code, I referenced the existing public hosted zone I previously created from the manual creation of the infrastructure.

**`cert.tf`**

```tf
# Reference the existing Route 53 hosted zone
# This ensures we use the already created hosted zone instead of creating a new one
data "aws_route53_zone" "laraadeboye" {
  name         = "laraadeboye.com"
}

# Create the ACM certificate
resource "aws_acm_certificate" "laraadeboye" {
  domain_name               = "*.laraadeboye.com"
  validation_method         = "DNS"
  subject_alternative_names = ["laraadeboye.com"]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-certificate"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# Create records to validate the certificate
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.laraadeboye.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.laraadeboye.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "laraadeboye" {
  certificate_arn         = aws_acm_certificate.laraadeboye.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# Create alias record for tooling
resource "aws_route53_record" "tooling" {
  zone_id = data.aws_route53_zone.laraadeboye.zone_id
  name    = "tooling.laraadeboye.com"
  type    = "A"

  alias {
    name                   = aws_lb.ext-alb.dns_name
    zone_id                = aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}

# Create alias record for wordpress
resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.laraadeboye.zone_id
  name    = "wordpress.laraadeboye.com"
  type    = "A"

  alias {
    name                   = aws_lb.ext-alb.dns_name
    zone_id                = aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}

```

If your `terraform validate` at this point, we will face an error of undeclared load balancer resource:

![undeclared resource](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AUTOMATE-INFRA-WITH-TERRAFORM-2/images/undeclared%20alb.png)

3. External Load Balancer and Internal Load Balancer
Next, we will create the external and internal load balancers. 
Create a file named `alb.tf` and enter the code to create the load balancers. code [here]()

4. Target group for Nginx reverse proxy, Wordpress and Tooling website

The load balancers will need to route traffic to the appropriate target groups. External load balancer to the nginx target group `nginx_tgt` and Internal load banlancer to the wordpress and tooling websites target .

5. Launch templates and Autoscaling group for bastion, nginx, tooling, and Wordpress.

To create the autoscaling group, we need to create the launch template. We will use a random AMI from AWS console. We need autoscaling groups for bastion and nginx; wordpress and tooling websites. 
Create two files: `asg-bastion-nginx-tf` and `asg-wordpress-tooling.tf` respectively. 

Within the`asg-bastion-nginx-tf` file, create the sns topic. There is a line of code to conditionally create the email notificaton only if the email is set. This avoids unnecessary resources – If no email is provided, Terraform won’t create an empty subscription.kk

In the code I wrote for `asg-bastion-nginx-tf`, I only created an autoscaling attachment for the Nginx ASG but not for the bastion ASG. This was intentional, as bastion hosts typically don't need to be associated with a load balancer's target group.
The aws_autoscaling_attachment resource is used to register an Auto Scaling Group with a load balancer target group. For Nginx, this makes sense because:

- Nginx serves web traffic that needs to be distributed across multiple instances
- Users access Nginx through the load balancer, not directly
- The load balancer needs to health-check Nginx instances

For bastion hosts, we typically don't need load balancer attachments because:

- Bastion hosts are SSH jump servers accessed directly via SSH
- Users connect directly to the bastion host's IP address or DNS name
- There's no need to distribute traffic across multiple bastion hosts
- You don't typically need health checks for bastion instances from a load balancer.

Find code [here](https://github.com/laraadeboye/PBL/blob/main/asg-bastion-nginx.tf)

Within the `asg-wordpress-tooling.tf`, enter the code found [here](https://github.com/laraadeboye/PBL/blob/main/asg-wordpress-tooling.tf)


This setup complements the code for the bastion and Nginx servers. 

The full architecture consists of:

- External ALB + Nginx (in public subnets) as the front-facing layer
- Internal ALB routing to WordPress and Tooling servers (in private subnets)
- Bastion hosts (in public subnets) for SSH access to the private instances


6. Datalayer: Elastic Filesystem and Relational Database (RDS)
Next, we will write the terraform code for the datalayer. We must first create the KMS key from AWS Key Managament Service. Create a file name `efs.tf` and `rds.tf` respectively.

Find code [here](https://github.com/laraadeboye/PBL/blob/main/efs.tf)

Run the terraform commands, correcting errors where necessary:
- `terraform fmt`
- `terraform validate`
- `terraform plan`

Finally, apply the terraform configuration to create the infrastructure

```
terraform apply
```

Ensure to destroy the infrastructure immediately to avoid excessive bills:

```
terraform destroy
```


                                                                                       
