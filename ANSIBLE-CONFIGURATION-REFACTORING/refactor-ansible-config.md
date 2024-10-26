
# Ansible Refactoring and Static Assignments

![Architecture Diagram](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/Configuration%20mgt%20with%20Ansible-Refactoring.png)

When we refactor in computer programming, it means making changes to the source code without changing the expected behaviour of the software. We often do this to enhance the readability of the code, increase it's maintainability, reduce its complexity and add proper comments.

In DevOps, we constantly interate for better efficiency. Before we refactor, we must question the purpose or motive and ask, "Why  do we need to change something if it works well and serves our purpose?"

For our infrastructure, we will be adjusting the code while maintaining the overall state of our infrastructure.

## Steps
## Step 0 Prerequisites
Note: If you have stopped your instance, you will need to start it again, configure ssh forwarding and connect to your instance to continue the task. You may also need to allocate and associate an elastic IP, if you deleted it in the previous setup to save cost. Refer to the previous task [here](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/edit/main/ANSIBLE-CONFIGURATION-MANAGEMENT/ansible-automate-tasks.md)

*Troubleshooting connection errors*
If you encounter issues connecting to your instance via vs-code.
- Check that the correct key is being forwarded. You may need to delete the existing key and add your specific key again:

```sh
# Clear current ssh-agent
ssh-add -D

# Add the correct key
ssh-add ~/path/to/stapleskey.pem # Replace keyname

# confirm the key is added
ssh-add -l
```

When you have run the above commands connect to the instance again through Remote SSH.

- Check your security group rules and ensure inbound access is allowed on port 22 from your local system IP.

- You may need to specify the right key explicitly in SSH config. you can configure SSH to always use `stapleskey.pem` (replace with your key) for the Jenkins machine. Add or modify your SSH config (~/.ssh/config):

```sh
Host jenkins-server
    HostName <jenkins-server-ip>
    User ubuntu # change this to the appropriate user
    IdentityFile ~/path/to/stapleskey.pem
    ForwardAgent yes

```

![connect remotely to jenkin-server from vscode ](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/connect%20remotely%20to%20jenkin-server%20from%20vs%20code.png)
You will notice form the bottom left corner that VS code has been connected.

## Step 1 Enhancing the Jenkins Job
Currently, every new change in the code creates a separate directory in our Jenkins server which is not convenient as it consumes space on the Jenkins server. 

- First, we will create a new directory called `ansible-config-artifact`. In this directory all artifacts will be stored after each build. We will modify the permissions of the directory appropriately to allow Jenkins access.

```sh
# Make directory
mkdir /home/ubuntu/ansible-config-artifact

# Modify permissions
chmod -R 777 /home/ubuntu/ansible-config-artifact
```
![ls created folder](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/ls%20created%20folder.png)

- Log in to the jenkins console at `<http://jenkinsinstance-IP:8080>` with the username and password you configured in the previous task.
Install the `Copy Artifact` plugin from the Jenkins console:

```plaintext
# Navigate to:
Manage Jenkins >> Manage Plugins >> Available >> Search for 'Copy Artifact'
```
![copy-artifact plugin](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/copy-artifact%20plugin.png)

![Installed copy artifact](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/Installed%20copy%20artifact.png)

- We will create a new Freestyle job and name it `save_artifacts` which we will configure to be triggered by our existing ansible project.
- 

```plaintext
# Navigate to:

Configure >> Source Code Management >> Under "Projects to watch", write `ansible-jobs`
```
![save-artifacts](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/save-artifacts.png)

In the configure page, also set the maximum builds to keep to 2. This will help to maximize the availability of space on our jenkins server as jenkins is resource intensive.

![max build](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/max%20build.png)

- The `save_artifacts` job saves artifacts into the `/home/ubuntu/ansible-config-artifact` directory. We will create a build step, choose **Copy artifacts from other project**. For source project, choose **ansible-job**, for the target directory, choose `/home/ubuntu/ansible-config-artifact`. For build trigger, choose **build after other projects are built**, then fill in the `ansible-job` as the project to watch.The save-artifact job depends on the ansible-job, so setting the trigger is necessary.

![build trigger for the save-artifact](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/build-trigger%20for%20save-artifact.png)

- We will test the build step by making some changes in the README inside the `ansible-config-mgt` repository. All new jobs should now be stored in our new folder.

The following image shows that the save-artifact build was successful:

![save-artifact build succesful](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/save-artifact%20buid%20succesful.png)

See the console output shows that the artifact has been copied from ansible job:
![console output of save-artifact](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/console%20output%20of%20save%20artifact.png)

Going to the jenkins-ansible server, we see the artifacts after running the `ls` command
![content of the ansible-config artifact](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/content%20of%20the%20ansible-config%20artifact.png)

*Troubleshooting*
If at this point, you cannot see your build running, 
- check that you have configured your webhook payload URL with the right address.
- Also, note that it is necessary to set the build trigger of the save-artifact build

We have made our Jenkins to be cleaner.

## Step 2 Refactor Ansible code by importing other playbooks into `site.yml`

First git pull the latest code from the `main` branch and create a new branch called `refactor`

![create refactor branch](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/create%20refactor%20branch.png)

We previously used a single playbook `common.yml` that contained all our codes for the two different OS. It can become tedious to manage if we want to use it for other servers with different requirements.

Making the task more modular is a better way of organising our task so that we can re-use them if needed.

Create a new file named `site.yml` in the **playbooks** directory. This file becomes the entry point or parent to all other playbooks.

```sh
touch playbooks/site.yml
```

Create a folder named `static-assignments` in the root folder. In this folder, we will save other children playbooks. We will move the `common.yml` into the `static-assignments` folder

- Open `site.yml` with an editor and import the `common.yml` playbook by including the following lines in the file:

```yaml
---
- hosts: all
- import_playbook: ../static-assignments/common.yml
```
**explanation of the code**

`- hosts: all`
This line specifies that the playbook or task should be executed on all hosts (servers) listed in the inventory file.

`- import_playbook: ../static-assignments/common.yml`
This line imports another playbook called common.yml located in the static-assignments directory, which is one level up (hence the ..) from the current directory.
The above code uses the builtin ansible module called `import_playbook`

If not already installed, Install `tree` utility (which helps to display directory structure) and check the folder structure of the project:

The image below shows how the directory structure should look like:

![tree ansible-config-mgt directory](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/tree%20ansible-cofig-mgt%20directory.png)

- Next we will run the ansible-playbook command against the 'dev` environment with the following command:

```sh
cd /home/ubuntu/ansible-config-mgt #if not already in this directory, run this
ansible-playbook -i inventory/dev.yml playbooks/site.yml
```
![ansible-play against dev](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/anible-play%20against%20dev.png)

*Troubleshooting*
If you get this error: `fatal: [172.31.46.249]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ubuntu@172.31.46.249: Permission denied (publickey).", "unreachable": true}`: as the image below:

![permission denied host](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/permission%20denied%20host.png)

-  indicates that the SSH connection to the remote host is being denied because the public key authentication is failing. The solution is to correctly set the ssh-forwarding on the local linux machine and verify it has been added to the jenkins-server.

If ssh-forwarding is not been used, ensure to verify that the private key is present on the jenkins server while the correct public key is in the `.ssh/authorized_keys` in the host machine

- If you are using VS code to connect to your instance, note that sometimes, VS Code sessions have isolation issues with SSH forwarding. You may want to use an external terminal as a temporary workaround.

We have already installed wireshark. We can create another playbook to configure its deletion. Create a file named `common-del.yml`

Enter the following yaml code:

```yaml
--- 
- name: update web, nfs and db servers
  hosts: webservers, nfs
  remote_user: ec2-user
  become: yes
  become_user: root
  tasks:
  - name: delete wireshark
    yum:
      name: wireshark
      state: removed


- name: update db and LB server
  hosts: lb, db
  remote_user: ubuntu
  become: yes
  become_user: root
  tasks:
  - name: delete wireshark
    apt:
      name: wireshark-qt      
      state: absent
      autoremove: yes
      purge: yes
      autoclean: yes
    
```

update the `site.yml` with the following and run it against the `dev` servers:

```yaml
- hosts: all
- import_playbook: ../static-assignments/commondel.yml
```

Confirm that wireshark has been deleted on all the servers by running `wireshark --version`

**Checking the presence of wireshark on webserver01**
![wireshark version on web server](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/wireshark%20version%20on%20webserver%2001.png)

**Checking the presence of wireshark on nfs server**
![wireshark version on nfs server](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/wireshark%20version%20on%20nfs%20server.png)

## Step 3 Configure UAT webservers with a role 'webserver'
We will configure two new RHEL webservers as UAT (User Acceptance Testing) servers.
To make our configuration re-usable, we will use a dedicated role named `webserver`

- First launch two fresh EC2 instances using RHEL 9 named `web1-UAT` and `web2-UAT`

![UAT servers running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/UAT%20servers%20running.png)

- We will create a role by creating a directory named `roles/`
in the `ansible-config-mgt` directory. The folder structure can be created in two ways:

  1. use ansible utility called `ansible-galaxy` inside the `ansible-config-mgt/roles` directory. Note that the `roles/` directory must be created in the `ansible-config-mgt` directory.

  ```sh
  cd ansible-config-mgt
  mkdir roles
  cd roles
  ansible-galaxy init webserver
  ```
    ![ansible-galaxy init](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/ansible-galaxy%20init.png)

  2. Create the directory/file structure manually

It is recommended to create folders and files on github rather than locally on the Jenkin-ansible server

View the file structure after creating the directory using ansible-galaxy. 
![ansible-galaxy tree file structure](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/ansible-galaxy%20tree%20file%20structure.png)

We will remove the irrelevant files `tests`, `files`, `vars`.

![delete unwanted file](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/delete%20unwanted%20file.png)

- Next we will update `ansible-config-mgt/inventory/uat.yml` file with the IP addresses of the UAT web servers we created.

```
[uat-webservers]

<web1-UAT-server-PRivate IP> ansible_ssh_user='ec2-user'
<web2-UAT-server-PRivate IP> ansible_ssh_user='ec2-user'

```
```
[uat-webservers]

172.31.90.131 ansible_ssh_user='ec2-user'
172.31.85.227 ansible_ssh_user='ec2-user'

```

- In order for ansible to find configured roles, uncomment the `roles_path` string in `/etc/ansible/ansible.cfg` and provide a full path to the roles directory `roles_path = /home/ubuntu/ansible-config-mgt/roles`

```sh
sudo vi /etc/ansible/ansible.cfg
```

![set role path](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/set%20roles%20path.png)

- We will add logic to the webserver role. Navigate to the `task`directory and enter configuration tasks within the `main.yml` file to:

  - Install and configure Apache (httpd service)
  - Clone Tooling website from Github `https://github.com/laraadeboye/tooling.git`
  - Ensure the tooling website code is deployed to `var/www/html` on each of the 2 UAT web servers.
  - Make sure the httpd service is started
  - Delete unwanted directory

**Configuration tasks to perform the above tasks:**

```yaml
# Install Apache
- name: install the latest version of Apache
  become: true
  ansible.builtin.yum:
    name: httpd
    state: latest

# Install Git and clone repo
- name: install the latest version of Git
  become: true
  ansible.builtin.yum:
    name: git
    state: latest

# Configure Git safe directory to allow cloning in /var/www/html
- name: Set /var/www/html as a safe directory for Git
  become: true
  command: git config --global --add safe.directory /var/www/html
  
- name: Clone a repo 
  become: true
  ansible.builtin.git:
    repo: https://github.com/laraadeboye/tooling.git
    dest: /var/www/html
    force: yes

# Deploy tooling website on each of the 2 UAT webservers
- name: Copy html content one level up 
  become: true
  command: cp -r /var/www/html/html /var/www/

# Start and enable Apache
- name: Start service httpd, if not started
  become: true
  ansible.builtin.service:
    name: httpd
    state: started
    enabled: yes # Make sure Apache starts on server reboot

# Delete unwanted directory
- name: Recursively remove /var/www/html/html directory
  become: true
  ansible.builtin.file:
    path: /var/www/html/html
    state: absent
```

![tasks for webserver](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/tasks%20for%20webserver.png)

## Step 4 Reference `webserver` role
In the `static-assignments` folder, we will create a new assignment for the UAT webservers named `uat-webservers.yml`. We will reference the role `webservers` in this yml file.

```yaml
---
- hosts: uat-webservers
  roles:
    - webserver
```
Note that the entry point to the ansible configuration is `site.yml`. we will import the `uat-webservers.yml` playbook inside the `site.yml`

```yaml
--- 
- hosts: all
- import_playbook: ../static-assignments/common.yml

- hosts: uat-webservers
- import_playbook: ../static-assignments/uat-webservers.yml
```

Here is what the structure of the ansible-config-mg directory looks like after refactoring:

![final tree post refactor](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/final%20tree%20post%20refactor.png)

## Step 5 Commit and Testing
Commit the changes to the github repo. Create a pull request and merge to main branch. 

```sh
# Push branch to repo
git push -u origin feat/refactor

```
![git push refactor](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/git%20push%20refactor.png)

On the Git UI, we will see similar to the following image:

Click on `compare and pull request`

![UI git push refactor](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/UI%20git%20push%20refactor.png)


After pushing, you can merge `feat/refactor` into main locally:

```sh
git checkout main
git pull origin main     # Update main with the latest changes
git merge feat/refactor
```
![git pull origin](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/git%20pull%20origin.png)

![git merge refactor](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/git%20merge%20refactor.png)

Run the playbook against your `uat` inventory:

```sh
cd /home/ubuntu/ansible-config-mgt
ansible-playbook -i /inventory/uat.yml playbooks/site.yml
```

*Troubleshooting*
I got the following error (Check image) when I run the playbook againsta my `uat` inventory

![error looking for webserver role](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/error%20looking%20for%20webserver%20role.png)

This error indicates that Ansible cannot find the role named `webserver`.

So I resolved this by setting the path of the role in the ansible.cfg in my root directory:

![edit ansible.cfg](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/edit%20ansible.cfg.png)


When I run the playbook aginst my `uat` inventory again, it worked!

![webserver role in action](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/webserver%20role%20in%20action.png)

Testing the presence of apache on the webservers:

**httpd running on web1-UAT**
![httpd running uat1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/httpd%20running%20uat1.png)

I got a similar result when I tested `web2-UAT`

When I visit the IP, I get the RHEL test page:
![RHEL test page](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/redhat%20test%20page.png)

We will modify our `tasks/main.yml` to:
- Ensure that the proper ownership is set for our `/var/www/html/`
- Ensure Selinux permissions are correct if enabled
- Disable the default welcome page
- Add handlers section. The handlers section runs specific tasks when notified. They're useful for:
  - Restarting services when config changes
  - Running only when needed (not every time)

We will add the following to our `tasks/main.yml`

```sh
# Set proper ownership and permissions
- name: Set ownership and permissions on web files
  become: true
  file:
    path: /var/www/html
    owner: apache
    group: apache
    mode: '755'
    recurse: yes

# Ensure SeLinux permissions are correct if SELinux is enabled
- name: Set SELinux context for web content
  become: true
  command: chcon -R -t httpd_sys_content_t /var/www/html
  when: ansible_selinux.status == "enabled"

# Disable the default welcome page
- name: Remove default welcome.conf
  become: true
  file:
    path: /etc/httpd/conf.d/welcome.conf
    state: absent
  notify: restart httpd

```
![modify tasksmain.yml](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/modify%20tasksmain.yml.png)

- Add the handlers section in the `handlers/main.yml` file:

```sh
- name: restart httpd
  become: true
  service: 
    name: httpd
    state: restarted
```
![modify handlersmain.yml](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/modify%20handlersmain.yml.png)

You can verify the syntax with the following command. The playbook will not run if the yaml syntax is incorrect

```sh
ansible-playbook -i inventory/uat.yml playbooks/site.yml --syntax
```

Then navigate to the root directory again, and  run the playbook against the UAT webservers with the following command:

```sh
ansible-playbook -i inventory/uat.yml playbooks/site.yml 
```
When we visit the web application through the server's public IP:

```
http://<webserver-public-IP>/index.php
```
We will see something similar to the following image, showing that our web application was deployed on the UAT servers using ansible:

**web1-UAT**
![WEb app deployed web1-UAT](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/web%20app%20deployed.png)

**web2-UAT**
![Web2-UAT deployed](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/images/uAT%20server%202%20deployed.png)

## Conclusion
We refactored our ansible configuration to deploy our web application using ansible roles. We also used Ansible `imports` and `roles` to modularise our ansible configuration.







