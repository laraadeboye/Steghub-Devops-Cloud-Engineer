# AWS Identity and Access Management (IAM)
Here's a breakdown of the key concepts:

## 1. What are Policies?
Policies are objects in AWS that define permissions. They determine what actions an IAM principal (user or role) can perform on AWS resources.

AWS evaluates these policies when a principal makes a request to determine if the request should be allowed or denied.

Most policies are stored as JSON documents.

## 2. Policy Types
AWS supports several types of policies, each serving a different purpose:

- **Identity-based Policies**: These are attached to IAM identities (users, groups, or roles) and grant permissions to the identity. They determine what the user/group/role can do.

- **Managed Policies**: Standalone policies that can be attached to multiple identities.

- **AWS Managed Policies**: Created and managed by AWS.

- **Customer Managed Policies**: Created and managed by you, offering more precise control.

- **Inline Policies**: Directly embedded within a single user, group, or role. They have a one-to-one relationship with the identity and are deleted when the identity is deleted.

- **Resource-based Policies**: Attached to AWS resources (like an S3 bucket). They grant permissions to the principal specified in the policy, allowing that principal to access the resource. Principals can be in the same AWS account or another account. These are always inline policies. A key example is an IAM Role trust policy.

- **Permissions Boundaries**: These define the maximum permissions that an identity-based policy can grant to an IAM entity (user or role). They don't grant permissions themselves but act as a ceiling.

- **Organizations SCPs (Service Control Policies)**: Used within AWS Organizations to define the maximum permissions for IAM users and roles within accounts in your organization or organizational unit (OU). Like permissions boundaries, they limit permissions; they don't grant them.

- **Organizations RCPs (Resource Control Policies)**: Used within AWS Organizations to define the maximum permissions for resources within accounts in your organization or organizational unit (OU). Like permissions boundaries, they limit permissions; they don't grant them.

- **Access Control Lists (ACLs)**: Used to control which principals in other accounts can access a resource. They are cross-account permission policies. They are the only policy type that doesn't use the JSON format.

- **Session Policies**: Advanced policies passed when you assume a role or federated user session using the AWS CLI or API. They limit the permissions granted by the role or user's identity-based policies for the duration of that session. They don't grant permissions on their own.

## 3. Key Concepts related to Policies

- **JSON Structure**: Most policies are written in JSON format.

- **Statements**: A policy contains one or more statements. Each statement defines a single permission. Multiple statements are evaluated with a logical "OR".

  - Elements of a Statement:
    - **Version**: The policy language version (recommend using 2012-10-17).

    - **Statement ID (Sid)**: Optional identifier for the statement.

    - **Effect**: Allow or Deny, indicating whether access is granted or denied.

    - **Principal**: (Required for resource-based policies) Specifies the account, user, role, or federated user to whom the policy applies.

    - **Action**: List of AWS actions that are allowed or denied (e.g., s3:GetObject, ec2:RunInstances).

    - **Resource**: (Required for identity-based policies) Specifies the AWS resources to which the actions apply (e.g., an S3 bucket ARN, an EC2 instance ARN). Use "*" to specify all resources.

    - **Condition**: (Optional) Specifies conditions under which the policy is in effect (e.g., requiring multi-factor authentication).

    - **Multiple Policies**: You can attach multiple policies to an identity or resource. AWS evaluates all applicable policies together.

    - **Explicit Deny**: An explicit Deny in any policy always overrides an Allow.

## 4. Policies and the Root User
You cannot directly attach identity-based policies or permissions boundaries to the AWS account root user.

However, you can specify the root user as a principal in a resource-based policy or ACL.

The root user is affected by SCPs and RCPs if the account is part of an AWS Organization.

## Conclusion

Think of policies as rulebooks that define who can do what in your AWS environment.
IAM uses these rulebooks to ensure that only authorized users and services have access to your resources. 
There are different kinds of rulebooks for different situations: some are attached to users, some to resources, and some are used to set overall limits on what can be done.

## Reference:
- [AWS Documentation on IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
