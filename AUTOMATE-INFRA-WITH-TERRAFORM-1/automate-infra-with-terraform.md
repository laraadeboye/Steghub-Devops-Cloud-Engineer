# AUTOMATE INFRASTRUCTURE PROVISIONING ON AWS PLATFORM WITH TERRAFORM 1

[Architecture diagram]

I previously created the above three-tier architecture manually via the AWS management console [here](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/aws-cloud-solution.md).

Now, I will automate the provisioning of this infrastructure using terraform in four project stages. This is stage 1.

## Workstation prereq
- Ubuntu Linux
- Terraform v1.10.5 
- aws-cli/2.15.48
- python3.12 and pip

## Prerequisites
- Create an iam user named `terraform` that has full admin access with only programmatic access. Note that we will be using this broad permission for our dev or test purposes.To enhance security and follow the principle of least privilege, it's best to limit Terraform's permissions to only those necessary for managing your specific infrastructure.
- Install boto3, AWS python sdk that helps us to interact with AWS services
- Create an s3 bucket to store terraform state file.

### Create iam user named `terraform`
- I created an admin group named `admin`. Then, I created the `terraform` user with no console access, then I proceeded to create the access key for programmatic access. The access key will be used to configure the AWS CLI

[create admin group]
[attach admin permissions to group]
[create terraform user]
[add terraform user to group]

- On the terminal of your workstation, where AWS CLI has been installed, run:

```
aws configure
```
Follow the prompts to set up AWS credentials, enter the following details:

- **AWS Access Key ID**: (from your Terraform IAM user)
- **AWS Secret Access Key**: (from your Terraform IAM user)
- **Default region name**: e.g., us-east-1
- **Default output format**: json (or leave blank)

To verify the setup run:

```
aws sts get-caller-identity
```
On my workstation, I have a preexisting credential set, which I do not want to override:
I run the following command to list the existing profiles:

```
aws configure list-profiles
```
[existing profile]

Use the `aws configure --profile <profile-name>` command to add the new credentials:

```
aws configure --profile terraform
```
Answer the prompt by entering the requested AWS access key and so on..
To view the AWS credentials file, run the following command, terrafom should be listed:

```
vi ~/.aws/credentials

```
To use this profile `terraform` when running terraform commands, run `export AWS_PROFILE=terraform` on the commandline to set the default profile. I also changed the default profile to terraform on my VScode. Also, ensure to specify it in the `provider.tf` file. 
 
[terraform profile added]



### Create Project folder to write terraform code
Create a project folder named `PBL` in git and clone it locally, so that all the terraform codes are version-controlled.
Also, create a feature branch `git checkout -b feature/terraform-setup`

### Install boto3
To install boto3, ensure python3 virtual environment has been installed with the following command:

```
sudo apt install python3.12-venv
```
create a virtual environment install boto3 with pip. Run the following command on your workstation. :

```sh
python3 -m venv terraform-env
source terraform-env/bin/activate
pip3 install boto3
```

Verify the installation of boto3 by running the following script:

```sh
import boto3

client = boto3.client("sts")
response = client.get_caller_identity()
print(response)
```
If configured correctly, it will print your **AWS Account ID** and **IAM user ARN**.

### Create s3 bucket 
To create the s3 bucket from the command line, run the following command on the terminal:


```sh
# creates the bucket with a unique time stamp
aws s3api create-bucket --bucket terraform-bucket-349-$(date +%s)

```
Note that you need to specify the region if you are creating the bucket in another region different from `us-east-1`.
Find the reference [here](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/create-bucket.html)

[create-terraform-bucket]

[create-terraform-bucket2]


Next, we will write reusable terraform codes to provision our infrastructure. I will include the variables in the variable file to avoid hardcoding values.

## Create terraform files and write code
Create four files `provider.tf`, `main.tf`, `variable.tf` and `terraform.tf.vars`

In the provider.tf file, write following to work with AWS provider:

```sh
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
```

Reference [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

First initialise the terraform using the `terraform init` command. You need to run this once to download the terraform plugins.

[terraform init]

[terraform init successful]

At this point, I will create a .gitignore file that includes terraform files that shouldnt be commited to my repo

`.gitignore` file:
```sh
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data, such as
# password, private keys, and other secrets. These should not be part of version 
# control as they are data points which are potentially sensitive and subject 
# to change depending on the environment.
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore transient lock info files created by terraform apply
.terraform.tfstate.lock.info

# Ignore CLI configuration files
.terraformrc
terraform.rc
```


In the `main.tf` file, enter the following code to create a vpc named `dev_vpc` with cidr block `10.0.0.0/16`(declared in the `variables.tf` file) 

```sh

resource "aws_vpc" "dev_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}
```


In the `variable.tf`:

```sh
variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "enable_dns_support" {
  default = "true"
}

variable "enable_dns_hostnames" {
  default = "true"
}

variable "enable_classiclink" {
  default = "false"
}

variable "enable_classiclink_dns_support" {
  default = "false"
}

```

In the `terraform.tfvars`:

```
vpc_cidr_block      = "10.0.0.0/16"
region              = "us-east-1"
```
Run the following to create the vpc resource
```sh
terraform fmt  # to format the code  
terraform plan  # to view the resources that are about to be created
terraform apply # to create resources
```

- terraform plan:

[create vpc with terraform]


- terraform apply:
[terraform vpc created]

Next, we will add additional code to create the subnets using count,loops, data sources, cidrsubnet() function

```sh
# Create public subnets
resource "aws_subnet" "public" {
  count                   = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

}
```
**Explanation**:
- The `count` determines how many subnets to create:
If `preferred_number_of_public_subnets` is null, it creates subnets in all available AZs.
Otherwise, it creates the specified number of subnets whic is 2 in the variables file

- Each subnet is associated with the VPC created by `aws_vpc.dev_vpc`
It gets an automatically calculated CIDR block using `cidrsubnet()` function( Reference [here]((https://developer.hashicorp.com/terraform/language/functions/cidrsubnet))
The subnets are automatically assigned public IPz(map_public_ip_on_launch = true) and they are placed in a different availability zone.

- The `count.index` in availability_zone = data.aws_availability_zones.available.names[count.index] determines which AZ each subnet goes into, starting from index 0. Each subnet gets placed in a different availability zone, distributed sequentially through the available AZs.

When terraform plan is run, the subnets will be created in availability zone `us-east-1a` and `us-east-1b`
[public subnet 1]

[public subnet 2]


[vpc created]
[subnet created]

The code for the infrastructure is found in my repository [here](https://github.com/laraadeboye/PBL)

