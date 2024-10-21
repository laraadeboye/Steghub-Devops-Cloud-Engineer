
# Ansible Configuration management for the 3-tier architecture.
![Architecture diagram for Ansible configuration mgt](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/Configuration%20mgt%20with%20Ansible-3%20tier.png)

We will be automating the management of our web application with infrastructure as code (IAC) using Ansible.

Ansible helps to speed up deployment times by automating the routine tasks of setting up servers, databases etc.

We will develop Ansible scripts to simulate the use of a jump box or bastion host. A jump box serves as an intermediary server that can be used to gain access to web servers within a secured network. It provides better security and reduces attack surface.

## Objectives
- Install and configure Ansible client to act as a jump server or bastion host

- Create a simple Ansible playbook to automate servers configuration.

## Prerequisites
- Basic AWS knowledge
- Ansible
- Git


## STEPS
## Step 0 Launch into EC2 instance and create Git repository. 
We will  be using the server we previously used to install Jenkins for the workflow [here](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/DEPLOYMENT-AUTOMATION-INTRODUCING-JENKINS/deployment-automation-with-jenkins.md). Update the name of the server to `jenkins-ansible`. We will run ansible playbooks on this server.

- SSH into the server.

- Create a repository named `ansible-config-mgt` in your Git account

## Step 1 Install and Configure Ansible on EC2 Instance.

[Ansible documentation](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu) shows the installation process.
Install ansible with the following commands:

```sh
# Update apt repository
sudo apt update -y

# Install dependencies
sudo apt install -y software-properties-common

# Update repositories
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install ansible
sudo apt install -y ansible

# Verify installation
ansible --version

```
![ansible --version](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/ansible%20version.png)

- ## Step 2 Configure jenkins to archive the repository content `ansible-config-mgt`.

We will configure a jenkins job to trigger from a github webhook set to trigger `ansible-job` build. Create a freestyle job in jenkins and click **Configure** Add the following configurations:

  - Configure Build Triggers: Github hook trigger for GITScm polling
  - Configure Post-build actions :Archive the artifact
We will test our configuration by making a little change to the Readme file in the `ansible-config-mgt` repository.
  - Ensure the build artifacts are saved in the folder:

```sh
/var/lib/jenkins/jobs/ansible-job/builds/[build_number]/archive/
```

- We will allocate an elastic IP to the `jenkins-ansible` server by following these steps:
  - Navigate to the EC2 Dashboard

  - In the console, find and click on EC2 under the "Services" menu.

  - In the left navigation pane, click on **Elastic IPs**.

  - Click on the **Allocate Elastic IP address button**.


  ```
  Actions > Allocate Elastic IP address
  ```
  - Choose VPC or EC2 from the drop-down list based on where your instance is located.

  - Click **Allocate** to confirm your choice.

  ```
  Actions > Associate Elastic IP address
  ```
  In the association dialog:

  - For Resource type, select **Instance**.
  - From the Instance drop-down, choose your desired EC2 instance which is our `jenkins-ansible-server`
  - Optionally, select a specific Private IP address if your instance has multiple private IPs.
  - Click on **Associate** to complete the process.
  
  Verify the Association

  - Go back to the Instances section in the EC2 Dashboard.
  - Select your EC2 instance and check its details at the bottom of the page.
  - You should see the associated Elastic IP listed under Public IPv4 address.

![allocate elastic ip](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/allocate%20elastic%20ip.png)

&nbsp;
![elastic ip associated](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/elastic%20IP%20allocated.png)

## Step 3 Prepare your development environment using visual Studio Code.
We will use visual studio code to prepare our dev environment.
- Connect your visual studio code to your Github repository.
- Clone the `ansible-config-mgt` repository to the the `jenkins-ansible-server`:

```
git clone https://github.com/laraadeboye/ansible-config-mgt
```

## Step 4 Begin Ansible development
- We will create a new branch named `feat/prj-11-ansible-config` that we will use for developing a new feature. From the command line enter:

```sh
git checkout -b feat/ansible
```
![git checkout b](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/git%20flow.png)

- Checkout the feature branch to the machine and build code and directory structure. 
- Create a directory named `playbooks` in which all our playbook files will be stored.
- Create another folder named `inventory` which will help keep our hosts organised. We will create **inventory files** within this folder to represent each environment: Development, Staging, Testing and Production (`dev`, `staging`, `uat` and `prod`)
- In the `playbooks` folder, we will create our first playbook named `common.yml`

## Step 5 Set up Ansible inventory

In ansible, we plan to execute linux commands on remote hosts. Ansible will use its default port `22` to SSH into target servers from the `jenkins-ansible-server` host. We will be import our existing key using the `ssh-agent` unto the `jenkins-ansible-server`

Follow the steps:
  - Setup the SSH Agent (Run this on your local machine):

  ```sh
    # Start the SSH agent
    eval "$(ssh-agent -s)"

    # Verify the agent is running
    echo $SSH_AGENT_PID
    
    # Add your SSH key If you have an existing key (private key)

    ssh-add ~/.ssh/private_key

    # Or optionally generate a new key if needed
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
    ssh-add ~/.ssh/id_rsa
    
    # Verify the added keys:
    
    ssh-add -l
  ```

  - Test the connection by SSH into the `jenkins-ansible-server` with the SSH-agent from your local machine.

  ```sh
  ssh -A ubuntu@<jenkins-ansible-server-public-ip>
  ```
  The -A flag explicitly enables agent forwarding, allowing the Jenkins-Ansible server to use your local machine's SSH keys when connecting to other servers. 
  Check out my [README]() for explanations of SSH agent and other configuration methods.

  - Verify the SSH agent forwarding on the `jenkins-ansible` server

  ```sh
   # On jenkins-ansible: Verify SSH agent is forwarded
   echo $SSH_AUTH_SOCK    # Should show a socket path
   ssh-add -l            # Should show your key(s)
  ```
 *Troubleshooting*
  - Ensure your security group settings on the instance allow SSH access on port 22 from your host IP
  - ensure you connect to your instance form your local host and accept the host key fingerprint, first.
  - If you have multiple ssh keys in your system, ensure that the key you intend to use is indeed added.
  - Also set the correct permissions for .pem keys from AWS (`chmod 400 ~/path-to-key`)


  **Connect the key to VS-code**:

  We can optionally connect VS code remotely to the `jenkins-ansible` server if we want to use VS code to edit files on the `jenkins-ansible` server:

  Follow the steps:

  - Install **Remote-SSH** extension in VS code
  - Press F1 or Ctrl+Shift+P and type "Remote-SSH: Connect to Host"
  - Enter: ubuntu@<jenkins-ansible-public-ip> 
  - or (first) create edit the `.ssh/config` file. Add the following content: Afterwards connect to the host via vscode

    ```sh
    # Replace the placeholders

    Host jenkins-machine-ip
    User ec2-user  # Replace with the appropriate username if different
    ForwardAgent yes
    ```
Viewing the bottowm left corner in the image below, we observe SSH connection to the jenkins-server elastic-public-IP.
![Connect to Jenkins server via vscode](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/connecting%20remotely%20from%20VS%20code%20to%20jenkins-server.png)
    
 ** Update `inventory/dev.yml` file**
 Update the `inventory/dev.yml` file with the connection information of the NFS server, the three webservers, the DB server and the load balancer server:

 ```text
 [nfs]
 <NFS-Server-Private-IP-Address> ansible_ssh_user=ec2_user

 [webservers]
 <webserver1-Private-IP-Address> ansible_ssh_user=ec2_user
 <webserver2-Private-IP-Address> ansible_ssh_user=ec2_user
 <webserver3-Private-IP-Address> ansible_ssh_user=ec2_user

 [db]
 <Database-Server-Private-IP-Address> ansible_ssh_user=ec2_user

 [lb]
 <loadbalancer-Server-Private-IP-Address> ansible_ssh_user=ubuntu
 ```


 Replace the placeholders as follows:
 ```text
 [nfs]
 172.31.39.177 ansible_ssh_user=ec2-user

 [webservers]
 172.31.32.255 ansible_ssh_user=ec2-user
 172.31.35.27 ansible_ssh_user=ec2-user
 172.31.32.34 ansible_ssh_user=ec2-user

 [db]
 172.31.38.76 ansible_ssh_user=ubuntu

 [lb]
 172.31.46.249 ansible_ssh_user=ubuntu
 ```

 ## Step 6 Create a Common Playbook
 We will use the `common.yml` playbook to write configuration for repeatable and re-usable tasks that can be run on multiple machines:

 Edit the `playbook/common.yml` file with the code below:

 ```yaml
 ---
 - name: update web and nfs servers
  hosts: webservers, nfs
  become: yes
  tasks:
    - name: ensure wireshark is the latest version
      yum:
        name: wireshark
        state: latest

- name: update lb and db server
  hosts: lb, db
  become: yes
  tasks:
    - name: Update apt repo
      apt:
        update_cache: yes

    - name: ensure wireshark is the latest version
      apt:
        name: wireshark
        state: latest
 ```

 *Hint*: Ensure to align the yaml file properly.

The ansible playbook automates tasks on the servers.

The playbook consists of two plays:
Play 1 updates web and NFS which are based on RHEL. It uses elevated privileges (become: yes) and installs/updates Wireshark to the latest version using yum.

Play 2 update LB server and DB. It uses elevated privileges (become: yes) and updates the apt repository cache. It also installs/updates Wireshark to the latest version using apt.

We will later update the `common.yml` to include additional tasks in another file named `common2.yml`

 Include tasks to 
 - Create a directory and a file inside it
 - Change timezone on all the servers
 - Run some shell scripts. Create shell scripts

We will update the host file as follows:
```text
[nfs]  
172.31.39.177 ansible_ssh_user=ec2_user

[webservers]
172.31.32.255 ansible_ssh_user=ec2_user
172.31.35.27 ansible_ssh_user=ec2_user
172.31.32.34 ansible_ssh_user=ec2_user

[db]
172.31.38.76 ansible_ssh_user=ubuntu

[lb]
172.31.46.249 ansible_ssh_user=ubuntu

[ubuntu_servers:children]
lb
db

[rhel_servers:children]
webservers
nfs

[all:vars]
ansible_user=ubuntu  # Default for Ubuntu servers

[rhel_servers:vars]
ansible_user=ec2-user  # Override for RHEL servers
```

To make the following changes we will create a new feature branch on the GIT User Interface and then from the jenkins server as shown:

```sh
git checkout -b feat/prj-11-ansible-config

git fetch

git branch --set-upstream-to=origin/feat/prj-11-ansible-config

# when you have made changes and need to push to the remote repo
git push --set-upstream origin feat/prj-11-ansible-config

```

Create a `common2.yml` file and paste the following content to the `common2.yml` file

**Updated `common2.yml` file**:
```yaml
---
- name: Update and configure servers
  hosts: all  # Target all servers
  become: yes
  vars:
    timezone: 'UTC'  # Change this to your desired timezone
    scripts_dir: '/opt/scripts'  # Directory for shell scripts
    
  tasks:
    # Update package cache based on OS family
    - name: Update apt repo (Ubuntu)
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"  # For Ubuntu servers

    - name: Update yum repo (RHEL)
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"  # For RHEL servers

    # Install packages based on OS family
    - name: Install packages on Ubuntu
      apt:
        name: wireshark
        state: latest
      when: ansible_os_family == "Debian"

    - name: Install packages on RHEL
      yum:
        name: wireshark
        state: latest
      when: ansible_os_family == "RedHat"

    # Create directory (works on both OS types)
    - name: Create makeshift directory
      file:
        path: ~/makeshift
        state: directory
        mode: '0755'

    - name: Create test.yml file
      copy:
        content: |
          # This is a test file
          key1: value1
          key2: value2
        dest: ~/makeshift/test.yml
        mode: '0644'

    # Set timezone (works on both OS types)
    - name: Set timezone
      timezone:
        name: "{{ timezone }}"

    # Creating and running shell scripts (works on both OS types)
    - name: Create scripts directory
      file:
        path: "{{ scripts_dir }}"
        state: directory
        mode: '0755'

    - name: Create system check script
      copy:
        content: |
          #!/bin/bash
          echo "Running system checks..."
          echo "OS Type: $(cat /etc/os-release | grep PRETTY_NAME)"
          df -h
          free -m
          uptime
        dest: "{{ scripts_dir }}/system_check.sh"
        mode: '0755'

    - name: Create backup script
      copy:
        content: |
          #!/bin/bash
          backup_dir="/backup/$(date +%Y%m%d)"
          mkdir -p $backup_dir
          echo "Starting backup to $backup_dir..."
        dest: "{{ scripts_dir }}/backup.sh"
        mode: '0755'

    - name: Execute system check script
      shell: "{{ scripts_dir }}/system_check.sh"
      register: system_check_output

    - name: Display system check results
      debug:
        var: system_check_output.stdout_lines
```

**Explanation of the script functionality**
This Ansible playbook is designed to update, configure, and perform system checks on all targeted servers, regardless of their operating system (Ubuntu/Debian or RHEL/CentOS). The playbook first updates the package cache and installs/updates Wireshark using either `apt` or `yum`, depending on the server's OS family. It then creates a makeshift directory and test YAML file, sets the system timezone, and creates a scripts directory.

The playbook also creates two shell scripts: `system_check.sh` and `backup.sh`. The `system_check.sh` script runs system checks, including OS type, disk space, memory usage, and uptime, and displays the results. The `backup.sh` script creates a backup directory and starts a backup process, although it currently only includes a placeholder message. The playbook uses conditional statements to apply tasks based on the server's operating system family, ensuring compatibility across different environments.

We will also need to create an variable file named `all.yml` in a folder named `group_vars`

```
mkdir group_vars
touch all.yml
```
- Paste the following content to the `all.yml`

```sh
timezone: 'America/New_York'  # Change timezone as needed
scripts_dir: '/opt/scripts'   # Change scripts directory if desired
```

- Execute the playbook by running:

```sh
# Verify the variables (recommended before running)
ansible-playbook -i inventory/dev.yml playbooks/common2.yml --check -v

# Run the playbook
ansible-playbook -i inventory/dev.yml playbooks/common2.yml
```

![checkmode dryrun](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/checkmode%20dryrun.png)

I ran the ansible command in dry-run mode.

## Step 7 Update Git with the latest code (Practice Git workflow)
- Push the code changes made locally to Github. This reinforces the skill to collaborate with other team members using git. 

- Commit and push the local changes to github. 

- Navigate to the github console and craete a pull request 

simulate another developer and act as a reviewer. Approve and merge

- In your local terminal, checkout from the feature branch from the main. Pull the latest changes.

- Once the code changes have been merged to the maain branch, jenkins will run the build and do its job- archive the files on the `jenkins-ansible` server

![successful build](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/successful%20build.png)
&nbsp;
![Content of the repo](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/Content%20of%20the%20repo.png)

When we check the server at the location:
```sh
cd /var/lib/jenkins/jobs/ansible-job/builds/[build-number]/archive/`

```
![content of the archive on server](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/content%20of%20the%20archive%20on%20server.png)

## Step 8 Run Ansible test
We will verify if the playbook works :

Change directory to `ansible-config-mgt`:
```sh
cd ansible-config-mgt
```

Run the playbook command:

```sh
ansible-playbook -i inventory/dev.yml playbooks/common.yml
```
*Hint Troubleshooting*
If you get errors due to inability to connect to host as shown
![image errors host](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/errors%20ansible%20hostkey.png)

![DB instance unreachable](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/db%20unreachabel%20SG.png)

- Verify you are using the correct hostname in your dev.yml file
- create the `ansible.cfg` file within your working directory and paste the following:

```sh
[defaults]
host_key_checking = False

```
- Verify security group rules for instance the DB instance should allow inbound access on port 22 from the jenkins-ansible server as shown in the image:

![Security grouip rules from jenkins sg](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/security%20group%20rules%20from%20jenkins%20server.png)

Verifying on each of the servers, we will check if wireshark has been installed by running `wireshark --version`:

**Web server 1**
![Wireshark installed on webserver1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/wireshark%20--version%20on%20webserver%201.png)

**NFS server**
![Wireshark installed on NFS server](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/wireshark%20version%20on%20NFS.png)

**DB Server**
![Wireshark installed on DB server](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/ANSIBLE-CONFIGURATION-MANAGEMENT/images/wireshark%20version%20on%20DB%20server.png)
With Ansible we can manage hundreds of servers with one command!


## Conclusion

We have successfully set up our infrastructure to automate configuration mangaement tasks with ansible.


