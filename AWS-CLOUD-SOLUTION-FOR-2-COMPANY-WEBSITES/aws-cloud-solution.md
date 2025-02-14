
# AWS CLOUD SOLUTION FOR 2 TWO COMPANY WEBSITES USING REVERSE PROXY TECHNOLOGY

In this task, we will build a secure infrastructure inside AWS VPC network for a fictitious company named `laraadeboye`. This company uses Wordpress CMS for its main business website and a tooling website (`https//github.com/laraadeboye/tooling`) for their devops team. As part of the company's desire for improved security and performance, we will use nginx reverse proxy technology.

Specific requirements:
- Cost
- Security
- Scalability
- Resilience: Infrastructure for both the wordpress and tooling website must be resilient to webserver failures, can accomodate increased traffic.

Here is the architecture we want to achieve:
![Architecture diagram](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/aws_cloud_solution.png)


**Prerequisites**

To start with, the following must be configured as prerequisites

1. Set up AWS account and organization unit
  - Create an AWS Root account
  - Create a sub account and organization unit

2. Create a domain name for `laraadeboye`company at a domain registrar of your choice. You can use free options like [freenom](https://www.freenom.com/en/index.html?lang=en).

3. Create a hosted zone in AWS and map it to your free domain name.

4. Ensure that all the resources are tagged appropriately:
Project: [project name]
Environment: [dev]
Automated: [No] (If the resource is created using and automation tool, it would be yes)

![tagging](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tagging.png)

Note that this just sets the tagging policy. For each AWS service created we will tag them appropriately.

**Directions**

1. Set Up AWS Account and Organization Unit
**AWS Account**:
- Go to the [AWS Management Console](https://aws.amazon.com/console/) and create a new account.
- Enable MFA (Multi-Factor Authentication) for the root user and IAM users. 
- Create IAM users for individual team members with the least privilege principle.

I have previously created an AWS account with an admin group having a user named `iamadmin` which inherits the admin properties of the admin group. This satisfies the least privilege principle.
We will use this existing account as the **management account**.

You can create a sub-account (referred to as a **member account**) directly from the Management Account within the AWS Organizations console. This eliminates the need to create a separate account outside of AWS and then link it later. 

Login to the management account: Use the root user or an IAM user/role with appropriate permissions to manage AWS Organizations.

![aws organisation](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/aws%20organization.png)

- Click on **Add an AWS account** to create a sub-account named `DevOps` (another email address will be needed to complete  `larboyedevops@gmail.com`)
![add an aws account](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/add%20an%20aws%20account.png)

Note that sub account is created in the Root on the same level as the manaagement account

![on the same level](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/on%20the%20same%20level.png)

When we create a sub-account this way, there is no need to manually register a new account as AWS handles the creation and linking of the new account. The sub-account inherits policies, permissions, and billing rules from the organization. The billing is centralized under the management account.

Next we will create an Organization Unit (OU).
- The OU will be created in the Root. Navigate to the Root of the Organization, 

![click on Root and Actions](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/click%20on%20Root%20Actions.png)

Click on **Actions** >> **Create New**.

![click on create new](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/click%20on%20create%20new.png)

Create an OU for this project. Mine is named `Dev-OU` (This is where dev resources will be launched).


- Move the `DevOps` account into the `Dev-OU`
![move devops account to DevOU](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/move%20devops%20account%20to%20Dev%20OU.png)

![success move devops](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/success%20move%20devops.png)

- You can attach service control policies (SCPs) to restrict actions at the organization level if necessary.

** Domain name registration**

2. I have a registered domain name `laraadeboye.com` (Paid)

** Creation of Hosted zone in AWS**
This is not a free service. As at the time of this project, it is $0.5 per hosted zone per month for the first 25 hosted zone, then $0.1 per hosted zone per month for additional hosted zones.

3. We will create a hosted zone in AWS Route 53 since we will be using a lot of AWS services like EC2, ALB. DNS management becomes easier and more powerful with a hosted zone, especially if you want to leverage AWS-specific features (like ALB alias records or health checks)

- Navigate to Route 53 Console from the AWS management Console.
- click on **Hosted zones** in the left navigation panel > **Create hosted zone**

Fill out the details:
  - Domain name: `laraadeboye` (Enter your unique domain name)
  - Type: Select **Public hosted zone**
  - Click **Create hosted zone**

![create hosted zone 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20hosted%20zone%201.png)

![create hosted zone 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20hosted%20zone%202.png)

After creating the hosted zone, you will automatically be presented with a set of default DNS records. You’ll see an **NS record** (Name Server) and a **SOA record** (Start of Authority).
NS record will list the nameservers that you need to configure at your domain registrar.

Next, update the DNS Records in your domain registrar. 

You can verify that the domain name has been propagated by entering the following command on the terminal, replacing the domain name with your domain name. (It should output that the Route 53 name servers):

```
nslookup -type=NS laraadeboye.com
```
You can also visit [dnschecker](https://dnschecker.org/) to verify.

## Step 1 Set up a Virtual Private Network (VPC)

We will create the following:
1. VPC
2. 6 subnets consisting of two public subnets and four private subnets.
3. NAT gateway
4. Internet gateway
5. Route tables 
6. Elastic IPs
7. Security groups (for the nginx servers, Bastion servers, Application Load balancers, webservers, Database)

We will be using the CIDR range `10.0.0.0/16` for the VPC as seen in our architecture diagram. This CIDR range gives us a total number of 65,536 IPs for our use.

### Create VPC
1. Navigate to VPC in the list of AWS services and choose **Create VPC** >> Choose **VPC only**. Name the vpc `Dev-vpc` and Click **Create VPC**

![create dev vpc](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20dev%20vpc.png)

### Create Public and Private Subnets
2. Next, we will create the subnets. From our architecture, we have two public subnets and 4 private subnets. The public-facing reources are launched in the public subnets while the private subnet is used for resources that should not be accessed from the internet.

We will create the Public Subnets
Choose **Subnets** in the left navigation pane, then **Create Subnet**
Enter the following the the dialogue box:

- VPC ID: Dev-vpc
- Subnet name: PublicSubnet1
- Availability zone: us-east-1a
- IPV4 subnet CIDR block: 10.0.1.0/24
Select **Create Subnet**

![PublicSubnet1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/PublicSubnet1.png)

Create another public subnet named  `PublicSubnet2` in a second availability zone `us-east-1b` with a CIDR block range of `10.0.2.0/24`

![PublicSubnet2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/PublicSubnet2.png)

In choosing the appropriate Subnet CIDR ranges, there must be no overlap or intersection. Each subnet must also be within the overall VPC CIDR block.

Creating the private subnets follow the same steps. We will use the following details:

**PrivateSubnet1**
- VPC ID: Dev-vpc
- Subnet name: PrivateSubnet1
- Availability zone: us-east-1a
- IPV4 subnet CIDR block: 10.0.3.0/24

![privatesubnet1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/privatesubnet1.png)

**PrivateSubnet2**
- VPC ID: Dev-vpc
- Subnet name: PrivateSubnet2
- Availability zone: us-east-1b
- IPV4 subnet CIDR block: 10.0.4.0/24

![privatesubnet2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/privatesubnet2.png)

**PrivateSubnet3**
- VPC ID: Dev-vpc
- Subnet name: PrivateSubnet3
- Availability zone: us-east-1a
- IPV4 subnet CIDR block: 10.0.5.0/24

![privatesubnet3](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/privatesubnet3.png)

**PrivateSubnet4**
- VPC ID: Dev-vpc
- Subnet name: PrivateSubnet4
- Availability zone: us-east-1b
- IPV4 subnet CIDR block: 10.0.6.0/24

![privatesubnet4](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/privatesubnet4.png)

The resources that must be isolated from the internet i.e the webservers and the databases will be launched into the private subnets.

### Create NAT gateway (NATgw)

To create a NAT gateway, navigate to the left navigation pane and choose **NAT gateways**, next, choose **Create NAT gateway** and configure it with the following details:
- Name: `Dev-vpcNATgw`
- subnet: PublicSubnet1
- Connectivity type: Public
- Elastic IP allocation ID: (Select **Allocate elastic IP**)

![create NAT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20NAT.png)

[create-NAT 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create-NAT%202.png)

### Create Internet gateway (IGw)
Next we will create the internet gateway (IGw).  Navigate to the left navigation pane and choose **Internet gateway**. Name it `Dev-vpcIGw`, then click **Create Internet Gateway**

![create IGw](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20IGw.png)

For our Vpc to be able to make use of the newly created internet gateway, we must attach it to the VPC we created.

Select Dev-vpcIGw > Choose **Actions** > **Attach to VPC** (select **Dev-vpc**)
![select dev vpc](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/select%20dev%20vpc.png)

![attach to dev vpc 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/attach%20to%20dev%20vpc%201.png)

![attached to VPC](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/attached%20to%20vpc.png)

### Configure Route tables
It is not sufficient to just create the IGw for Internet access. we will need to associate it with a route table (RT). A RT consists of rules that determine where the network traffic is directed. The public and private subnets of the Dev-vpc must be associated with a RT.


**Creating the public route table**
In the left navigation pane, choose **Route tables** > **Create route table**

![create RT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20RT.png)

Configure it with the following details:
Name: Public-RT
VPC: Dev-vpc

Select **Create Route table**

![public-rt](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/public-rt.png)

Select the public route table you created and navigate to the **Routes tab**, select **add route**. Set the destination as `0.0.0.0/0` (which is an IP range that applies to anywhere on the internet), the target as `internet Gateway`, then choose the internet gatway you created earlier. Click **Save Changes**

![edit route 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/edit%20route%201.png)

![edit route 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/edit%20route%202.png)

You will notice that all the subnets are associated with the main route table.

![associated with main RT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/associated%20with%20main%20RT.png)

For the route table to work, it must be associated with the public subnet.

![public rt subnet asso](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/public%20rt%20subnet%20asso.png)

Navigate to the **Subnet associations tab**, choose **Edit subnet asssociations**
[public rt subnet asso]

In the dialogue box, choose the two public subnets we created and click **Save associations**

![choose public subnet](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/public%20rt%20subnet%20asso.png)

To verify the public RT subnet associations, navigate to public-RT >> actions >> edit subnet associations

![verify public RT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/verify%20public%20RT.png)

We should observe the associations as seen below:

![public subnet associated](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/public%20subnet%20associated.png)

**Creating the private route table**
Similarly, the private route table must be created. 

Configure it with the following details:
Name: `Private-RT`
VPC: Dev-vpc

Select **Create Route table**

[private-rt](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/private-rt.png)

Select the private route table you created and navigate to the **Routes tab**, select **add route**. Set the destination as `0.0.0.0/0` (which is an IP range that applies to anywhere on the internet), the target as `NAT gateway`, then choose the nat gateeway you created earlier. Click **Save Changes**

![edit NAT gateway 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/edit%20nat%20gateway%201.png)
![edit NAT gateway 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/edit%20nat%20gateway%202.png)

For the private route table to work, it must be associated with the private subnet.

Navigate to the **Subnet associations tab**, choose **Edit subnet associations**. Select all the four private subnets and click **Save associations**

![private rt subnet asso](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/private%20rt%20subnet%20asso.png)

Note: Ensure that the auto-assign of the public IPv4 is enabled for the public subnets.

### Create Security groups
Security groups are virtual firewalls that control inbound and outbound traffic to instances in the VPC. We will be creating security groups for :
- application load balancers
- nginx servers
- bastion servers
- application webservers
- database

To create the security groups, navigate to the navigation pane and choose **Security groups**. Select **Create security group**  and configure it with the details below:

**application load balancer security group**
- Security group name: ALB-sg
- Description: Allows access from the internet.
- VPC: Dev-vpc

For the inbound rules, Choose **Add rule**. Configure it with the details below:
- Type: All traffic
- Sourece type: Anywhere IPV4
- Source: 0.0.0.0/0 

For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:

Key: Name
Value: ALB-sg

Click **Create security group**

![alb-sg 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/alb-sg%201.png)
![alb-sg 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/alb-sg%202.png)

** nginx security group**
- Security group name: nginx-sg
- Description: Allows access from application load balancer. 

- VPC: Dev-vpc

For the inbound rules, Choose **Add rule**. Configure it with the details below: (These details will be changed later)

- Type: Custom TCP
- Port range: 80
- Source type: Custom
- Source: ALB-sg 
For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:

Key: Name
Value: nginx-sg

Click **Create security group**
![nginx-sg 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/nginx-sg%201.png)
![nginx-sg 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/nginx-sg%202.png)


**webservers security group**
The application webservers should be accessed from the bastion servers for administration and from the nginx servers for internet access from clients. We will create it with 2 inbound rules.

- Security group name: webserver-sg
- Description: Allows access from nginx servers and bastion
- VPC: Dev-vpc

For the inbound rules, Choose **Add rule**. Configure it with the details below. This IP range will be adjusted later to match my specific IP from my worksystem.

- Type: SSH
- Port range: 22
- Source type: Custom
- Source: bastion-SG (The one that we created)
For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:

 Choose **Add rule** again:

- Type: Custom TCP
- Port range: 80
- Source type: HTTP
- Source: nginx-SG (The one that we created)
For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:
Key: Name
Value: webserver-sg

Click **Create security group**
![webserver-sg 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/webserver-sg%201.png)
![webserver-sg 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/webserver-sg%202.png)


**bastion servers security group**
Also known as jumphost. Access to the bastion servers should only be from workstations that need to SSH into the bastion servers.

- Security group name: bastion-sg
- Description: Allows access from workstation.
- VPC: Dev-vpc

For the inbound rules, Choose **Add rule**. Configure it with the details below. This IP range will be adjusted later to match my specific IP from my worksystem.

- Type: SSH
- Port range: 22
- Source type: Custom
- Source: [IP range of worksystem]
For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:

Key: Dev
Value: bastion-sg

Click **Create security group**
![bastion-sg 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/bastion-sg%201.png)
![bastion-sg 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/bastion-sg%202.png)


** datalayer security group**
The datalayer of this set up consists of Amazon Relational Database Service (RDS) and Amazon Elastic File System(EFS). Only the webservers have access to the RDS while nginx and the webservers have access to the EFS mountpoint.

**(RDS-sg)**
- Security group name: RDS-sg
- Description: Allows access from webservers

- VPC: Dev-vpc

For the inbound rules, Choose **Add rule**. Configure it with the details below: 

- Type: Custom TCP
- Port range: 3306 (port rage for MySQL/Aurora)
- Source type: Custom
- Source: webserver-sg 
For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:

Key: Name
Value: RDS-sg

Click **Create security group**
![RDS-sg 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/RDS-sg%201.png)
![RDS-sg 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/RDS-sg%202.png)

**(EFS-sg)**
- Security group name: EFS-sg
- Description: Allows access from webservers and nginx

- VPC: Dev-vpc

For the inbound rules, Choose **Add rule**. Configure it with the details below: 

- Type: Custom TCP
- Port range: 2409 (port range for NFS)
- Source type: Custom
- Source: webserver-sg 

Choose **Add rule**, again.
- Type: Custom TCP
- Port range: 2409 (port range for NFS)
- Source type: Custom
- Source: nginx-sg 

For the **Tags-optional**, Choose **Add new tag** and configure it with the details below:

Key: Name
Value: EFS-sg

Click **Create security group**
![EFS-sg 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/EFS-sg%201.png)
![EFS-sg 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/EFS-sg%202.png)

### Create Elastic IPs
We will be using 3 elastic IPS in this set up. Note that one has been allocated to our NAT gateway in the process of its configuration as seen in this image step:

![show allocated eip](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/show%20allocated%20eip.png)

We will also create 2 Elastic IPs for the Bastion hosts

The VPC and its resources have been created. Next, we will create the compute resources

## Create the Compute resources
The compute resources we will be creating are :
- EC2 instances for nginx, bastion and webservers
- Launch Templates
- Target groups
- Autoscaling groups
- TLS certificate 
- Application Load balancers


## Compute Resources for nginx
Nginx will be used as our reverse proxy in this infrastructure set up. As seen in our infrastructure diagram, It runs in an autoscaling group. 

** Create Nginx Autoscaling Group**
First, create a Custom AMI:

- Launch a RHEL EC2 instance. 
Create an `t2.small` size EC2 instance based on `CENTOS` ami in `us-east-1` region in `us-east-1a` and `us-east-1b` availability zones as seen in our infrastructure diagram.

Name: `Dev-nginx-custom-AMI`
AMI: RHEL free-tier
Instance type: `t2.small`
VPC: `Dev-vpc`
Security group: nginx-sg
Create a key-pair named `devkey`. You can also make use of existing keypair
Number of Instance: 1

After launching the instance, we will observe that the instance is running but the public Ipv4 address has not been assigned.
![dev custom ami launched](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/dev%20custom%20ami%20launched.png)

This is because the auto-assign of the public IPv4 was not enabled during the creation of of the EC2 instance as shown:
![auto assign not done](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/auto%20assign%20not%20done.png) 

We will manually do this by navigationg to VPC Dashboad >> Subnets. Select the subnet your instance is launched in. (I launched it in the PublicSubnet1). Check **Auto-assign public IPv4 addresss**:
   - If it is set to No, instances launched in this subnet won't have public IPs by default.
   ![Auto assign No](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Auto%20assign%20No.png)

   - Click **Edit subnet settings** and enable **Auto-assign public IPv4 addresses** and click **Save**

![enable auto assign](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/enable%20auto%20assign.png)

Go ahead and enable auto-assign public subnet for the PublicSubnet2
![auto assign Public Subnet2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/auto%20assign%20Public%20Subnet2.png)

I terminated the previously created instance and relaunched it. Once, an instance has been created without a public IP, AWS does not allow you to assign a public IP to it unless you use an Elastic IP. I do not want to use an Elastic IP for this particular instance because it is just for generating a custom AMI.

The new instance is automatically assigned a public IP as shown:

![instance running with IP add](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/instance%20running%20with%20IP%20add.png)

Next, add an SSH inbound rule allowing access from on the internet. Note that, this IP range is too broad and shouldn't be used in production. I am using this for testing purposes, so that the necessary software packages can be installed. Ideally, the IP ranges should be only from the IP of the local system used to access the virtual server.

![ssh adjust for testing](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ssh%20adjust%20for%20testing.png)

I connected to the server via my local system through SSH on port 22 and updated the server.

```
sudo yum update -y
```

Then I [installed intance connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html). (RHEL systems do not come pre-installed with instance connect)

Next, 
- We will install the following software packages: `Python`, `ntp`, `net-tools`, `vim`, `wget`, `telnet`, `epel-release`, `htop`, 

```sh
# First enable EPEL repository
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install all packages
sudo dnf install -y htop chrony 

# Start and enable chronyd (replacement for ntp)
sudo systemctl start chronyd
sudo systemctl enable chronyd

# Install php8.3 from remi repo
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf clean all
sudo dnf makecache
sudo dnf module reset php -y
sudo dnf module enable php:remi-8.3 -y
sudo dnf install -y php php-cli php-mysqlnd php-fpm

# Install net-tools
sudo dnf install -y net-tools vim wget telnet
```

```sh
# Install python3.12 (Install from source code)
# ---------------------

# Install development tools and dependencies
sudo dnf groupinstall "Development Tools" -y
sudo dnf install -y gcc gcc-c++ make zlib-devel bzip2 bzip2-devel \
    readline-devel sqlite sqlite-devel openssl-devel libffi-devel xz-devel tar wget

# Download and extract Python 3.12.1 source code
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tgz
sudo tar xzf Python-3.12.1.tgz

# Configure, compile, and install
cd Python-3.12.1
sudo ./configure --enable-optimizations
sudo make -j$(nproc)
sudo make altinstall

# Verify installation
python3.12 --version

# (Optional) Set Python 3.12 as default
sudo alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.12 20
python3 --version

```
![php8.3 installed](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/php8.3%20%20installed.png)

Note:
- On RHEL 9, `chrony` is used instead of ``ntp for time synchronization
- If you need a specific PHP version, you can append it to the package name (e.g., php81)
- Most of these packages are available in the base repositories except for `htop` which comes from `EPEL`

Having installed all the necessary packages on our RHEL instance, we will create an AMI out of the EC2 instance using the AWS Management Console:

- Navigate to the EC2 Dashboard
- Select your instance
- Click "Actions" > "Image and templates" > "Create image"
![ami images and template](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ami%20images%20and%20template.png)

Fill in the required fields:

  - Image name (required): `Dev-EC2-custom-AMI`
  - Image description (optional): Insert your chosen description
  - No reboot (optional - select if you don't want the instance to reboot)


Click "Create image"
![create AMI image](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20AMI%20image.png)
![create AMI image with tagging](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20ami%20image%20with%20tag.png)

Go to the left navigation pane and choose **AMIs**. The AMI is still in the pending state as shown:

![ami image pending](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ami%20image%20pending.png)

Once the status displays as **available**, the instance can be deleted.

**Launch template for Nginx servers **
To launch instances in an autoscaling group, it is important to create a launch template. A launch template saves the configuration parameters needed to launch EC2 instances.

- Navigate to **Launch Templates** >> **Create Launch template**
Configure the following in the dialog box:
- Launch template name (required): `Nginx-LT`
- Template version description: `Nginx ASG Template v1`
- Tick the box for Auto Scaling guidance
- Set the Tags with the Key and Value named Appropriately
- AMI: Choose **My AMIs** >> **Owned by me** >> Select the AMI you created
- Instance type: `t2.small` (I had memory constraint issues when using t2.micro to create the AMI)
- Key pair name: Choose your existing keypair that you have access to
- Under the Network settings. Leave it empty as it will be set in the Auto Scaling Group
- Select **Select existing security group** > `Nginx-sg`
- Scroll down to **Advanced Details** > **User data**, and paste this script:
  
```sh
#!/bin/bash

yum update -y
yum install -y nginx
systemctl enable nginx
systemctl start nginx
```

Click **Create Launch Template**

![create Launch template 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20Launch%20template%201.png)
![create Launch template 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20Launch%20template%202.png)
![create Launch template 3](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20Launch%20template%203.png)
![create Launch template 4](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20Launch%20template%204.png)
![create Launch template 5](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20Launch%20template%205.png)

![launch template details](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/launch%20template%20details.png)

## Configure ALB To Route Traffic to Nginx
**Target groups for Nginx servers**
We will be distributing traffic accross multiple instances using an application load balancer (ALB) as seen in our architecture diagram, hence, we need to create a target group. Creating a target group also supports health checks at the application level.

- First navigate to the left navigation panel and select **Target Groups** under Load Balancing. Click  **Create target group**.
- Under Basic Configuration > Choose a Target type , Choose **Instances**. Set the following:
Target group name: `Nginx-TG`
Protocol: https
Port: 443
Ip address type: IPv4
VPC: Dev-vpc
health check path: `/healthstatus`

![create target group](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20target%20group.png)
![create target group](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20target%20group%202.png)

Click Next > **Create Target group** (Without registering any instances)

** Create an ACM for your domain name**
Public SSL/TLS certificates provisioned through AWS Certificate Manager (ACM) are free.

Navigate to Amazon Certificate manager and configure the following:
- Certificate type: Request public certificate
- Domain name: Yor registered domain name
- Validation method: DNS Validation
- Add appropriate tags
- Choose **Request**

You will notice that the certificate is pending validation.
![ACM creation 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ACM%20creation%201.png)
![ACM creation 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ACM%20creation%202.png)
![ACM creation 3](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ACM%20creation%203.png)

IF you are using Route53 to host and manage your domain name, on the Certificate console, Click on **Create records in Route 53** and follow the prompts.

After some time 5minutes to an hour, it should be issued.

**Application Load Balancer for Nginx**
- Go to the left navigation panel, choose **Load Balancer** > **Create Application Load Balancer**

Configure:
- Load balancer name: `Nginx-LB`
- Scheme: Internet-facing
- VPC: Dev-vpc
- Availability Zones: `us-east-1a` (Select **PublicSubnet1); `us-east-1b` (Selevt **PublicSubnet2)
- Security groups: Nginx-sg
- Listeners and routing: Protocols: Https, Port: 443; Default action: Nginx-TG
- Certificate: Choose your created certificate
- Add load balancer tags
- Choose **Create Load balancer**
![Nginx LB created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Nginx%20LB%20created.png)

**Autoscaling groups for Nginx servers**
An Autoscaling group automatically manages the number of EC2 instances to ensure you  have the right amount of compute capacity for your workload. It scales out (adds instances) when demand increases and scales in (removes instances) when demand decreases based on various metrics like CPU utilization, network traffic.

- Go to the left navigation panel, choose **Auto Scaling Groups** > **Create Auto Scaling Group**
- Configure the following:
  - Auto Scaling Group Name: `Nginx-ASG`
  - Launch template: `Nginx-LT`
  - VPC: Dev-vpc
  - Availability Zones and subnets: `PublicSubnet1`, `PublicSubnet2`
  - Availability Zone Distribution: Balanced best effort
  - Load balancing: Attach to an existing load balancer
  - Existing load balancer target groups: Nginx-TG | HTTPS
  - Add appropriate tags
  - Health Checks: Turn on Elastic Load Balancing health checks
  - Health check grace period: 300 seconds
  - Desired capacity: 2
  - Minimum capacity: 2
  - Maximum capacity: 4
  - Select **Target tracking scaling policy** > Average CPU utilization
  - Target value: 90
  - Instance warmup: 300 seconds Click **Next**
  - Add notification. Here , first navigate to Simple Notification Service on the management console in another tab to create an SNS topic:
  
** SNS Topic creation**
Cost:  Amazon Simple Notification Service (SNS) topics are not free, but there is a free tier. First 1 million Amazon SNS requests per month are free, $0.50 per 1 million requests thereafter.

- Go to Amazon SNS in the AWS console.
- In the **Create Topic** box, enter the name of the topic:`ASG-Notifications` .
- Select Standard as the topic type.
- Click **Create topic**.
![SNS Topic Created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/SNS%20Topic%20created.png)

Next, you need to subscribe to the Topic:
- In the SNS topic, click **Create Subscription**.
- Choose Email as the protocol (for alerts to your inbox ).
- Enter your email address.
- Click Create Subscription.
- Check your email and confirm the subscription.

![Suscription created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Suscription%20created.png)

You will get a message similar to the following image after confirming it in your mail box
![suscription confirmed](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Suscription%20confirmed.png)


Return to your ASG creation tab to finish up. Choose the notification topic you created. You may need to go back one step and Add notifications again for the topic you created to be visible.

Click **Create Auto Scaling group**
![NGinx ASG created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Nginx%20ASG%20created.png)
![Nginx ASG instances](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Nginx%20ASG%20instances.png)


## Compute Resources for Bastion host
We will create compute resources for Bastion host. 
The bastion host in this infrastructure will NOT be created in an Auto scaling group for the following reasons:
- Elastic IPS cannot be automatically assigned to new instances in an ASG
- Bastion host do not need ASG becuase they handle SSH traffic
- They typically require minimal resources and do not need scaling based on load.

For high availability, I will create the bastion hosts in two availability zones with Route 53 failover

- Create a bastion host with the following configurations in us-east-1a (PublicSubnet1) and us-east-1b (PublicSubnet2) and assign elastic IPs to the two instances

  - Name: `Dev-bastion-server-1` (Name the second,`Dev-bastion-server-2` )
  - AMI: RHEL free-tier
  - Instance type: `t2.small`
  - VPC: `Dev-vpc`
  - Security group: Bastion-sg
  - You can also make use of existing keypair `devkey`
  - Number of Instance: 1

![Bastion servers running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Bastion%20servers%20running.png)

SSH into the servers and install these software packages in each of the servers: (The installation steps are above as for nginx)
 `Python`, `ntp`, `net-tools`, `vim`, `wget`, `telnet`, `epel-release`, `htop`.

 Also install `ansible` and `git`
 
**Installation steps for Ansible and git**

```sh
# Enable Epel repository if not enabled
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install python3-pip if not installed
sudo dnf install -y python3-pip

# Install Ansible using pip
pip3 install ansible

# Install Git
sudo dnf install -y git

# Verify installations
ansible --version
git --version
```

Hint: Remember to edit Bastion-sg security group to allow internet access from your IP address. (or use 0.0.0.0/0 for testing purposes only)
- Create and Assign Elastic IPs to both Instances.
![Elastic IP associated](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/Elastic%20IP%20associated.png)
![Elastic IP assigned to bastion servers](


- Set up Route 53 Failover for high availability

First create a Route 53 health check for the Instances. Each failover record requires a health check to monitor the bastion instance.
  - Navigate to **AWS Route 53 Console > Hosted Zones > Create Health Check
  - Health Check Name: `Dev-bastion-server-1-HC`
  - Monitor Endpoint: Enter the elastic IP of `Dev-bastion-server-1`
  - Protocol: TCP
  - Port: 22 Click **Advanced configuration**
  - Failure Threshhold: 3
  - Request Interval: 30 second
  - Create Alarm: Optional

  Repeat the same steps for `Dev-bastion-server-2`
![health checks for bastion](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/health%20checks%20for%20bastion.png)
  - Navigate to **AWS Route 53 Console > Hosted Zones > Select your domain
  - Create two A records for each bastion hosts
    - Record name: `bastion.laraadeboye.com`
    - Type: A
    - Alias: No
    - Value: Enter the elastic IP of `Dev-bastion-server-1`
    - Routing Policy: Failover (This route traffic to an alternative server, if the primary server is unaccessible)
    - Failover Record Type: primary
    - Associate a Route 53 health check

    - Repeat the above steps for Dev-bastion-server-2 setting it as Secondary failover

    ![failover record for bastion](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/failover%20record%20for%20bastion.png)
    ![bastion records A created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/bastion%20records%20A%20created.png)

The bastion servers have been created with high availability using Route 53 failover routing.

## Compute Resources for the Web servers

The webservers are in an auto scaling group. we will create a separate launch template for the tooling website and the wordpress.

**Steps to create the webservers Auto Scaling Group (ASG)**
1. Create the Custom AMI for the Launch templates
2. Create the Launch templates
3. Create the target groups
4. Create the Application Load balancers
5. Create the Auto Scaling Group

To avoid repetitions, the steps have been outlined in the Nginx auto scaling group creation above with minimal alterations

I created two Custom AMIS for both the wordpress and the tooling devops website.

**Configuration details:**

Name: `Dev-tooling-custom-AMI` ; (Name the second server,`Dev-wordpress-custom-AMI` )
AMI: RHEL free-tier
Instance type: `t2.small`
VPC: `Dev-vpc`
Security group: webserver-sg. 
Create a key-pair named `devkey`. You can also make use of existing keypair
Number of Instance: 1

![webservers custom AMI](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/webservers%20custom%20AMI.png)

Note:
I editted the security group of the `webserver-sg` to allow internet access from `0.0.0.0/0`. because of this AMI. I intend to delete this rule in my security group settings as it is too open. The webservers should only be accessed by the ALB of the Nginx and from the bastion hosts.
I wanted to avoid creating too many security groups.

In addition to the software packages listed above, I installed php on the webservers:

**Php installation steps**
```sh
# Install php8.3 from remi repo
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf clean all
sudo dnf makecache
sudo dnf module reset php -y
sudo dnf module enable php:remi-8.3 -y
sudo dnf install -y php php-cli php-mysqlnd php-fpm
```
After the installation of the software packages and php, create the custom AMI from the instances

![tooling and wordpress AMI](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tooling%20and%20wordpress%20AMIS.png)

**Creating Launch Templates for the webservers**
Use `Webserver-sg` for the security group
**tooling webservers**
![tooling-LT 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tooling-LT%201.png)
![tooling-LT 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tooling-LT%202.png)
![tooling-LT 3](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tooling-LT%203.png)

**Wordpress webservers**
In the userdata section under the advanced details, we will include the following script to  install:
 - Apache (httpd)
 - PHP modules needed for WordPress
 - MySQL client (for database connectivity)
 - WordPress

```sh
#!/bin/bash
set -xe

# Update system packages
dnf update -y

# Install Apache, PHP modules, and MySQL client
dnf install -y httpd php-mysqlnd php-fpm php-json php-mbstring php-xml php-gd php-curl mariadb105

# Enable and start Apache
systemctl enable --now httpd

# Install AWS CLI if not present (needed for later configurations)
if ! command -v aws &> /dev/null; then
  dnf install -y aws-cli
fi

# Download and extract WordPress if not already installed
if [ ! -d "/var/www/html/wordpress-site" ]; then
  wget https://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz
  tar -xzf /tmp/latest.tar.gz -C /var/www/html/
  mv /var/www/html/wordpress /var/www/html/wordpress-site
  chown -R apache:apache /var/www/html/wordpress-site
  chmod -R 755 /var/www/html/wordpress-site
fi

# Restart Apache to apply changes
systemctl restart httpd

```


![wordpress LT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/wordpress%20LT.png)


![three LT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/three%20LT.png)

## Configure ALB To Route Traffic to Webservers
**Target groups for webservers**
First, create Target groups  with the following configuration details:
Target group name: `tooling-TG`
Protocol: https
Port: 443
Ip address type: IPv4
VPC: Dev-vpc
health check path: `/healthstatus`


Target group name: `wordpress-TG`
Protocol: https
Port: 443
Ip address type: IPv4
VPC: Dev-vpc
health check path: `/healthstatus`

![tooling TG](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tooling%20TG.png)

![wordpress TG](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/wordpress%20TG.png)

**Application Laod Balancer for webservers**

Set up the Applictaion Load balancer for the webservers with the following configuration:

- Load balancer name: `tooling-LB`
- Scheme: Internal
- VPC: Dev-vpc
- Availability Zones: `us-east-1a` (Select **PrivateSubnet1); `us-east-1b` (Selevt **PrivateSubnet2)
- Security groups: Webserver-sg
- Listeners and routing: Protocols: Https, Port: 443; Default action: tooling-TG
- Certificate: Choose your created certificate
- Add load balancer tags
- Choose **Create Load balancer**

![tooling LB](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/tooling%20LB.png)

- Load balancer name: `wordpress-LB`
- Scheme: Internal
- VPC: Dev-vpc
- Availability Zones: `us-east-1a` (Select **PrivateSubnet1); `us-east-1b` (Selevt **PrivateSubnet2)
- Security groups: Webserver-sg
- Listeners and routing: Protocols: Https, Port: 443; Default action: tooling-TG
- Certificate: Choose your created certificate
- Add load balancer tags
- Choose **Create Load balancer**

![wordpress LB](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/wordpress%20LB.png)

![loadbalancers created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/loadbalancers%20created.png)

**Create Auto Scaling Group for the webservers**
- Configure the following:
  - Auto Scaling Group Name: `tooling-ASG`
  - Launch template: `tooling-LT`
  - VPC: Dev-vpc
  - Availability Zones and subnets: `PrivateSubnet1`, `PrivateSubnet2`
  - Availability Zone Distribution: Balanced best effort
  - Load balancing: Attach to an existing load balancer
  - Existing load balancer target groups: tooling-TG | HTTPS
  - Add appropriate tags
  - Health Checks: Turn on Elastic Load Balancing health checks
  - Health check grace period: 300 seconds
  - Desired capacity: 2
  - Minimum capacity: 2
  - Maximum capacity: 4
  - Select **Target tracking scaling policy** > Average CPU utilization
  - Target value: 90
  - Instance warmup: 300 seconds Click **Next**
  - Add notification. Choose the created topic `ASG-Notifications`

  Also repeat the steps to create of the wordpress website, naming it appropriately `wordpress-ASG`...

All the three autoscaling groups have been created as seen in the following image

  ![All 3 ASG](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/All%203%20ASG.png)

The auto scaling group has launched all the instances and some others are being initialised. Note that, The wordpress and tooling webservers have no public IPs as expected. 

I will go ahead and terminate the instances used to create the AMis.

![ASG instances running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/ASG%20instances%20running.png)

For our infrastructure , the next step is to create the Data layer. We will create the Amazon Elastic File System (EFS), first. The EFS will helps to ensure persistent file storage.


## Create Data layer
**Elastic File System**
- Navigate to the Elastic File system console by searching the search bar, then click **Create file system**
- Provide the name of the file system `Dev-EFS` and choose `Dev-vpc` as the VPC. Click **Create**
![create-EFS](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create-EFS.png)
- Select the created file system, click edit. Choose **Network**. The EFS has been created with mount targets and default security groups. Remove them and create new mount targets in the `PrivateSubnet1`and `PrivateSubnet2` which is where the ASG instances are deployed. Modify it to use the appropriate security groups you created previously `EFS-sg` (The security group allows traffic from NFS port range `2049`)
Mount targets should be created in the same subnets (AZs) where your ASG instances are running.

![create mount target 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20mount%20target%202.png)

- Next, Create access points named `web-accesspoint` for fine-grained control (e.g., different applications sharing the same EFS).

![accesspoint created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/accesspoint%20created.png)

**Relational Database Service (RDS)**
Another component of the datalayer is the RDS, For high availability, we will configure a multi-AZ set up of RDS MySQL Database instance.

First create a KMS key from Key Management Service fro use to encrypt the database
[database key](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/database-key.png)

Then create a DB subnet group named `dev-dbsubnet`. Select the datalayer subnets and click **Create**
![select datalayer subnet](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/select%20datalayer%20subnet.png)

Next create  the database using Mysql 8.. 
The multi-AZ option is available for Dev/test  and Production. 

The configurations I used:
Database creation method: Standard create
Engine type: MySQL, 8.0.40
Template: Dev/Test
Availability and durability: Multi-AZ DB instance
DB instance identifier: dev-db
Master username: admin
Select the encryption key you created: database-key
DB instance class: Choose burstable classes db.t3.micro
Choose the `dev-vpc` and `RDS-SG` 
Add appropriate tags and create the database.

It takes time to create the database. Wait for the creation
![dev dbsubnet](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/dev%20dbsubnet.png)
![create database](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/create%20database.png)

**Routing**
From the Route 53 console, we will Create alias record for the root domain `laraadeboye.com` and `tooling.laraadeboye.com`

![alias a record tooling](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/AWS-CLOUD-SOLUTION-FOR-2-COMPANY-WEBSITES/images/alias%20a%20record%20tooling.png)


## Conclusion:
We have successfully created a secure, available, scalable and cost-effective infrastructure to host 2 enterprise websites for a company using  various cloud services from AWS.




