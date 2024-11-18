# Ansible Dynamic Assignments (include)

![architecture](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/Configuration%20mgt%20with%20Ansible-Refactoring.png)

While static assignments use `import` module as seen in the [previous project](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIGURATION-REFACTORING/refactor-ansible-config.md), the `include` module is used for dynamic assignments. It is recommended to use static assignments for playbooks because it is more reliable. 

In this long task 😊, we will introduce dynamic assignment into our structure. We also make use of ansible community roles to make our configuration modular and reusable. I include the steps I took to troubleshoot errors and get it working. When using ansible, like several other devOps tools, you may need to iterate several times to get your app working. Let's begin...

## Step 0 Set up infrastructure
- Start your `jenkin-ansible` server , if you stopped it after the previous step. I have all my instances running in case I want to run some tests. Connect to the instance via ssh-forwarding.
![Instances running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/Instances%20running.png)

- Here is the current structure of the project:
![current project structure](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/current%20project%20structure.png)

- Create a new branch in the `ansible-config-mgt` repo named `dynamic-assignments`

```sh
# Create branch locally in the jenkins-ansible server
git checkout -b feat/dynamic-assignments

# push the branch to the remote repo
git push -u origin feat/dynamic-assignments
```
![git new dynamic branch](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/git%20new%20dynamic%20branch.png)

- Create a folder named `dynamic-assignments`and a file named `env-vars.yml` within the folder.

Our use-case can benefit from dynamic assignments because we have four different environments: dev, staging, uat, and prod respectively. We need a way to set values to variables based on specific environments.

- Create a folder of environment variables named `env-vars` in the root directory. Each environment will have separate variables hence, create yaml files within the folder to store environment-specific variables named`dev.yml`, `stage.yml`, `uat.yml` and `prod.yml` respectively.

![structure env-var](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/structure%20env-var.png)

The following yaml configuration consists of
- `with_first_found`: This is a lookup plugin that searches for the first file it finds from the list. It will:
  - Look through the files in order: dev.yml → stage.yml → prod.yml → uat.yml
  - Use the first file it finds in the `env-vars`  directory
  - Load those variables into the playbook


- {{ playbook_dir }}/../env-vars: This path tells Ansible to look in the env-vars directory that's one level up from the playbook location. 

Notes on ansible special variables can be found in the [documentation](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html). Also , details about looping over lists of items is [here](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html#standard-loops)

```yml
## This throws up some errors. I left it here for studying purposes. Check the troubleshooting section towards the end of this README for more info.
---
- name: Collate variables from environment-specific file
  include_vars:
    name: "{{ item }}"
    files:
      - dev.yml
      - stage.yml
      - prod.yml
      - uat.yml
    paths:
      - "{{ playbook_dir }}/../env-vars"
  with_first_found: "{{ item }}"
  tags:
    - always
    
```
(The upper one threw up errors at the testing phase. I left it for learning purposes)

[include ran not successfully](ithub.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/include%20ran%20successfully.png)

```yml
## Correct syntax. Check explanations in the troubleshooting section
---
- name: Collate variables from environment-specific file
  include_vars:
    file: "{{ item }}"
  with_first_found:
    - files:
        - "{{ inventory_file | basename | splitext | first }}.yml"
        - dev.yml
        - staging.yml
        - prod.yml
        - uat.yml
      paths:
        - "{{ playbook_dir }}/../env-vars"
  tags:
    - always
```
Paste the above instruction into the `env-vars.yml` file


## Step 1 Update `site.yml` with dynamic assignments
Next, we will update the `site.yml` with dynamic assignments.

```
include: ../dynamic-assignments/env-vars.yml
```

```sh
---
# Play 1: Loads dynamic variables for all hosts
- name: Include dynamic variables
  hosts: all
  tasks:
    - name: Load dynamic variables
      include_tasks: ../dynamic-assignments/env-vars.yml
      tags:
        - always

# Play 2: Imports common configuration for all hosts
- name: Import common playbook
  import_playbook: ../static-assignments/common.yml

# Play 3: Specific configuration for UAT webservers only
- name: Configure UAT webservers
  hosts: uat-webservers
  tasks:
    - name: Import UAT specific tasks
      import_tasks: ../static-assignments/uat-webservers.yml

```
Here is what the `site.yml` looks like now:

![update site.yml](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/update%20site.yml.png)

In the above yaml file, following ansible best practices for clear naming and structure and correct use of import types [here](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse.html), we have a proper name and structure for each play. There is a also a clear separation between dynamic variables loading (using `include_tasks`), common configurations (using `import_playbook`) and host-specific tasks (using `import_tasks`)

To test the configuration, you may need to start the remaining webservers, now, if they are not already started.

Change directory to the `ansible-config-mgt` root directory and run:

```sh
ansible-playbook -i inventory/dev.yml playbooks/site.yml
```

# [image: test include role]

## Step 2 Creating community role for the MySQL db

We will create a role for the MySQL db that installs the MySQL package, creates a database and configure users. Rather than, starting from scratch we will use a pre-existing production ready role from the ansible galaxy.

First we will download the Mysql ansible role. Available community roles can be found in the [ansible galaxy website](https://galaxy.ansible.com/ui/)

For the MySQL role we use a popular one by [geerlingguy](https://galaxy.ansible.com/ui/standalone/roles/geerlingguy/mysql/)

We already have git installed in our machine as well as the git initialised `ansible-config-mgt` directory. We will create a new branch named `roles-features` and switch to it.

Navigate to the roles directory and install the mySQL role with the following command:

```sh
ansible-galaxy install geerlingguy.mysql
```
![error no headers](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/error%20no-headers.png)

**Community role installed successfully**
![installing community roles](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/installing%20community%20roles.png)

Rename the created folder to mysql:

```sh
mv geerlingguy.mysql/ mysql
```

*Troubleshooting*
The image above shows the creation of a new git branch locally. I attempt to install the community role but i was met with the error above ("File contains no sectionheaders"). This indicates an error in the ansible config file in the `etc` folder specifically a missing header `[defaults]`. I include this in the file as shown:

![error corrected default header](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/error%20corrected%20default%20header.png)


Edit the roles configuration to use the correct credentials for MySQL required for the `tooling` website.

We can use the community role to:
- Manage our existing database
- Create databases for different environments.

To apply the community role to our use case, managing our existing database, first, we will define environment variables.

    - Define environment-specific MySQL database credentials in each of your `env-vars` files (like `dev.yml`, `prod.yml`, etc.)
  For instance, the `dev.yml` example:

  ```yaml
  # MySQL configuration for the development environment
mysql_root_username: "root"
mysql_root_password: "Passw0rd123#"

# Define databases and users to be created for the dev environment
mysql_databases:
  - name: "tooling"
    encoding: "utf8"
    collation: "utf8_general_ci"

mysql_users:
  - name: "webaccess"
    host: "%"
    password: "Passw0rd321#"
    priv: "my_dev_database.*:ALL"

  ```
  Replace the database name, mysql_users name and passwords as appropriate.

Update similarly for `prod.yml`, `staging.yml`, and `uat.yml` with specific database names and credentials for each environment.

Next, we update the inventory files with environment-specific variables. Each inventory file (like `inventory/dev.yml`, `inventory/prod.yml`), include the path to the relevant environment variables file.

**Example (`inventory/dev.yml)**

```yaml
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

[db:vars]
env_vars_file=../env-vars/dev.yml  # Specify environment variables file for database setup

```

Next, update playbook configuration in `playbooks/site.yml` including the variable file and specifying the renamed role `mysql` 

```sh
---
# Play 1: Loads dynamic variables for all hosts
- name: Include dynamic variables
  hosts: all
  tasks:
    - name: Load dynamic variables
      include_tasks: ../dynamic-assignments/env-vars.yml
      tags:
        - always

# Play 2: Imports common configuration for all hosts
- name: Import common playbook
  import_playbook: ../static-assignments/common.yml

# Play 3: Set up MySQL on database servers
- name: Set up MySQL
  hosts: db
  become: yes
  vars_files:
    - ../env-vars/dev.yml  # Change this to ../env-vars/prod.yml for production, etc.
  roles:
    - mysql  # Ensure this role is installed and named correctly


# Play 4: Specific configuration for UAT webservers only
- name: Configure UAT webservers
  hosts: uat-webservers
  tasks:
    - name: Import UAT specific tasks
      import_tasks: ../static-assignments/uat-webservers.yml

```
![custom db geer](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/custom%20db%20geer.png)

For the `uat-webservers.yml`, we will define the following content. This means the tasks configured in the role will be executed when ansible-playbook is run. 

```sh
- name: Configure uat-webserver
  include_role:
    name: webserver

```
Run the ansible-playbook command from the root directory.
```sh
ansible-playbook -i inventory/dev.yml playbooks/site.yml
```

*Troubleshooting*
Note that you don't need to specify the hosts directive in the `uat-webservers.yml`when you are using `import_tasks` to include `uat-webservers.yml` in your main playbook (site.yml) since the hosts context is already established in the main playbook.

**Error shown if host is defined (conflict)**
[conflict](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/conflict%20in%20env-vars.png)

When we run the ansible-playbook command we also get the with_first_found error as show:

![with first found error](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/with_first_found%20error.png)

I resolved it by modifying the `dynamic-assignments/env-var.yml` file:

```sh
---
- name: Collate variables from environment-specific file
  include_vars:
    file: "{{ item }}"
  with_first_found:
    - files:
        - "{{ inventory_file | basename | splitext | first }}.yml"
        - dev.yml
        - staging.yml
        - prod.yml
        - uat.yml
      paths:
        - "{{ playbook_dir }}/../env-vars"
  tags:
    - always
```

This configuration uses file: "{{ item }}" to specify which file to load. It properly structures the file search under `with_first_found`
It adds automatic environment detection using {{ inventory_file | basename | splitext | first }}. It maintains proper YAML hierarchy for the files and paths lists.

We were getting the "No file was found when using first_found" error - because the previous syntax wasn't correctly telling Ansible where and how to look for the files.

Stage and commit the changes to git.
Create a pull request and merge to the main branch
![git add feature-roles](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/git%20add%20feature-roles.png)

&nsbp;

![git push feature-roles](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/git%20push%20feature-roles.png)

## Step 3 Creating roles for the the load balancers

We want the flexibility to be able to choose between different load balancers: `nginx` or `apache` (remember we previously created a virtual machine for the apache load balancer, in a past project task).
 
We will create different roles for each usecase.

We can choose to develop our own roles or find available ones from the community.

We cannot use both load balancers at the same time so we will include a condition to enable either one applying our variables

**Manual setup of role for loadbalancers** 

Ansible documentation on roles can be found [here](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)

- Create a new branch to work on the manual load balancer setup:

```sh
git checkout -b feat/load-balancer-roles
```

- Navigate to the `roles/` directory and create a `nginx_lb` role for Nginx using `ansible-galaxy` command. I have existing roles called `webserver` (which was created manually) and `mysql` (which was created using community roles) from my previous tasks.

```sh
# list directory content
ls
# create nginx lb directory using ansible-galaxy
ansible-galaxy init nginx_lb

# remove irrelevant directory files: files, tests, vars
rm -rf files tests vars

## Note that this directory manually can be created by running:

# mkdir -p roles/nginx_lb/{tasks,defaults,handlers,templates}
```

![nginx_lb role with ansible-galaxy](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/nginx_lb%20role%20with%20ansible-galaxy.png)

![tree nginx_lb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/tree%20nginx_lb.png)

- Also create a role for the apache load balancer named `apache_lb`.

```sh
# list directory content
ls
# create nginx lb directory using ansible-galaxy
ansible-galaxy init apache_lb

# remove irrelevant directory files: files, tests, vars
rm -rf files tests vars

## Note that this directory manually can be created by running:

# mkdir -p roles/apache_lb/{tasks,defaults,handlers,templates}
```

- In the `defaults/main.yml` of both load balancer roles, create default variables to control whether each load balancer is enabled:


**Navigate to `roles/nginx_lb/defaults/main.yml`**

```yaml
# Enable Nginx load balancer
enable_nginx_lb: false
load_balancer_is required: false
```


**Navigate to `roles/apache_lb/defaults/main.yml`**

```yaml
# Enable Apache load balancer
enable_apache_lb: false
load_balancer_is required: false
```

Now we already have  nginx load balancer server installed and configured for load balancing in a previous tasks. (check image for the nginx lb running)

![nginx lb running on AWS](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/nginx%20lb%20running.png)

Oops😯, I just discovered I have terminated the apache load balancer server in the past. We will use ansible to install and configure it for load balancing our app. This affords an opportunity to broaden my knowledge. Here is a [link](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/LOADBALANCING-WITH-APACHE/installing-apache-with-ansible.md) within this repo explaining how I achieved it.

To use your this conditional logic in our setup, where the load balancers are already installed in the virtual machines respectively, In `env-vars/[environment.yml]`, In each load balancer role, create tasks to start or stop the respective services based on these variables we have set.

In **`roles/nginx_lb/tasks/main.yml`**

```yaml
---
- name: Ensure Nginx is started for UAT if enabled
  service:
    name: nginx
    state: started
    enabled: true
  when:
    - enable_nginx_lb
    - load_balancer_is_required

- name: Stop Nginx if not required
  service:
    name: nginx
    state: stopped
  when:
    - not enable_nginx_lb
    - load_balancer_is_required

```

In **`roles/apache_lb/tasks/main.yml`**

```yaml
---
- name: Ensure Apache is started for UAT if enabled
  service:
    name: apache2
    state: started
    enabled: true
  when:
    - enable_apache_lb
    - load_balancer_is_required

- name: Stop Apache if not required
  service:
    name: apache2
    state: stopped
  when:
    - not enable_apache_lb
    - load_balancer_is_required
```

You will also specify which load balancer to enable in specific environments. For instance,in the UAT environment for the UAT servers, if we want to enable the nginx load balancer, we will set:

**`env-vars/uat.yml`**
```yaml
enable_nginx_lb: true
enable_apache_lb: false
load_balancer_is_required: true
```

Update the `playbooks/site.yml` as follows:

```yaml
---

- name: Configure load balancer
  hosts: uat-webservers
  roles:
    - { role: nginx_lb, when: enable_nginx_lb }
    - { role: apache_lb, when: enable_apache_lb }

```

The playbook snippet:

- configures a load balancer on hosts grouped under `uat-webservers`.
It includes two roles:
  - `nginx_lb`: This role will be executed only if the variable `enable_nginx_lb` is true.
  - `apache_lb`: This role will be executed only if the variable `enable_apache_lb` is true.

- Next, we will test the set up by running:

```
ansible-playbook -i inventory/uat.yml playbooks/site.yml
```
The setup should allow you to toggle between Nginx and Apache load balancers simply by setting the appropriate variables in the environment-specific files. Initially though, I didnt get the expected result. After a couple of iterations and corrections, the errors were resolved.

*Troubleshooting*
when I ran the above command I got the error:
![first error config lb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/first%20error%20config%20lb.png)

This means variables and conditions are not properly configured. I followed a systematic approach to resolve this:

1. Verify that the `env-vars/uat.yml` defines the variables correctly
   
  ![image env-vars uat.yml](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/image%20env-vars%20uat.yml.png)

2. Confirm your `inventory/uat.yml`
  ![image inventory uat.yml](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/image%20inventory%20uat.yml.png) Notice the variable set for nginx and apache

`ansible_host` should be correctly set for the webservers and load 
balancers.

![ansible host set](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/ansible%20host%20set.png)

3. Review Role Task for Nginx Load Balance in the `roles/nginx_lb/tasks/main.yml`
![confirm roles.nginx.task.](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/confirm%20roles.nginx.task.png)

I modified tasks/main.yml to correct errors
![updated task.main to correct errors](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/updated%20nginx%20task.main%20to%20correct%20errors.png)

![Update task to include become and remove default .conf](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/task%20updated%20with%20become.png)

I also modify the configuration to include a handler to reload nginx when changes are made
![handlers for nginxlb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/handlers%20for%20nginxlb.png)

I also create a template file `nginx-lb.conf.j2`
![template file for nginx-lb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/template%20for%20nginx-lb.png)

The template file dynamically loads IP addresses from each UAT webserver in the `inventory/uat.yml`

![default file for nginxlb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/default%20variable%20for%20nginx_lb.png)

4. Update site.yml
![update site.yml](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/update%20site.yml.png)

Run playbook:
```sh
ansible-playbook -i inventory/uat.yml playbooks/site.yml
```

We are able to access the uat webservers through the nginx load balancer.

![access after choosing nginx](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/access%20web%20app%20after%20choosing%20nginx.png)

![nginx chosen success](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/nginx%20chosen%20success.png)

We will also test further by enabling apache while disabling nginx.

Also to do make the site secure using ansible


## Testing apache loadbalancer IP

- Set the `env-vars/uat.yml`
```yml
enable_nginx_lb: false
enable_apache_lb: true
load_balancer_is_required: true

```

- Set the `default/main.yaml`

```sh
# defaults file for apache_lb

enable_apache_lb: false
load_balancer_is_required: false

# Variable for server name and port
apache_server_name: 54.226.233.195  # Server name to use in nginx config
apache_listen_port: 80  # Port to listen on


```

- Configure the task. I modified my yaml file to handle the existing configuration file `webserver-lb.conf` I previously created on the apache_lb server.

```yaml
# tasks file for apache_lb
# tasks file for apache_lb
- name: Check if webserver-lb.conf exists
  stat:
    path: "/etc/apache2/sites-available/webserver-lb.conf"
  register: existing_conf
  when: lb_type == "apache"

- name: Backup existing webserver-lb.conf if it exists
  copy:
    src: "/etc/apache2/sites-available/webserver-lb.conf"
    dest: "/etc/apache2/sites-available/webserver-lb.conf.backup"
    remote_src: yes
  become: true
  when: 
    - lb_type == "apache"
    - existing_conf.stat.exists

- name: Disable existing webserver-lb.conf if it exists
  command: a2dissite webserver-lb.conf
  when: 
    - lb_type == "apache"
    - existing_conf.stat.exists
  notify: restart apache

- name: Ensure Apache is started for UAT if enabled
  service:
    name: apache2
    state: started
    enabled: true
  when:
    - enable_apache_lb
    - load_balancer_is_required
    - lb_type == "apache"

- name: Stop Apache if not required
  service:
    name: apache2
    state: stopped
  when:
    - not enable_apache_lb
    - load_balancer_is_required
    - lb_type == "apache"

- name: Configure Apache Load Balancer if enabled
  template:
    src: "apache-lb.conf.j2"
    dest: "/etc/apache2/sites-available/load-balancer.conf"
    mode: '0644'
  become: true
  when:
    - enable_apache_lb
    - load_balancer_is_required
    - lb_type == "apache"
  notify:
    - restart apache

# Enable the required modules for load balancing
- name: Enable required Apache modules
  command: "a2enmod {{ item }}"
  with_items:
    - proxy
    - proxy_http
    - proxy_balancer
    - lbmethod_byrequests
  become: true
  when: lb_type == "apache"
  notify: restart apache

# enable the load-balancer config
- name: Enable apache load balancer configuration
  command: a2ensite load-balancer.conf
  become: true
  when: lb_type == "apache"
  notify: restart apache
  tags:
    - apache

# disable the default config
- name: Disable default Apache site configuration
  command: a2dissite 000-default.conf
  become: true
  when: lb_type == "apache"
  notify: restart apache
  tags:
    - apache

# Verify configuration
- name: Verify Apache configuration
  command: apache2ctl configtest
  register: apache_config_test
  when: lb_type == "apache"

- name: Display Apache configuration test results
  debug:
    var: apache_config_test.stdout_lines
  when: lb_type == "apache"
```

- Set the `handlers/main.yaml`

```yaml
# handlers file for apache_lb
- name: restart apache
  become: true
  service:
    name: apache2
    state: restarted
  when: lb_type == "apache"

```


- Configure the template named `apache-lb.conf.j2`

```
<Proxy "balancer://uat_backend">
    {% for server in groups['uat-webservers'] %}
    BalancerMember "http://{{ hostvars[server].ansible_host }}"
    {% endfor %}
    ProxySet lbmethod=byrequests
</Proxy>

<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName {{ apache_server_name | default('_') }}

    ProxyPreserveHost On
    ProxyPass / balancer://uat_backend/
    ProxyPassReverse / balancer://uat_backend/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

```

- Check that the `inventory/uat.yml` is well configured with the appropriate variables

```ini
[uat-webservers]

172.31.90.131 ansible_ssh_user='ec2-user' ansible_host='172.31.90.131'
172.31.85.227 ansible_ssh_user='ec2-user' ansible_host='172.31.85.227'


[lb]
172.31.46.249 ansible_ssh_user=ubuntu lb_type=nginx ansible_host='172.31.46.249' # Nginx
172.31.16.59 ansible_ssh_user=ubuntu lb_type=apache ansible_host='172.31.16.59' # Apache
          
```

Replace IP as appropriate for your use case

- Ensure that your `playbooks/site.yml` has the right play for configuring the loadbalancers

```yml
---
# Play 5: Configure load balancers for UAT
- name: Configure load balancer for UAT
  hosts: lb # load balancer defined in inventory/uat.yml
  vars_files:
    - "env-vars/uat.yml"
  roles:
    - { role: nginx_lb, when: load_balancer_is_required and enable_nginx_lb }
    - { role: apache_lb, when: load_balancer_is_required and enable_apache_lb }


```

![image current `playbook/site.yml`](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/current%20playbook%20site.yml.png)

- Now run your ansible-playbook command (Be ready to correct errors and iterate. 😂)

```sh
ansible-playbook -i inventory/uat.yml playbooks/site.yml
```

View images of a successful run:

![successfully ansible play apache](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/successfully%20ansible%20play%20apache.png)

![successfully ansible play apache 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/successfully%20ansible%20play%20apache%202.png)

Checking on the web UI. Remember the apache public-IP is `54.226.233.195`. The public-IP of your apache_lb instance will be different.

![accessing wep app after choosing apache](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/ANSIBLE-CONFIG-DYNAMIC/images/access%20web%20app%20after%20choosing%20apache.png)

Here is the final project structure:


```sh
.
├── README.md
├── ansible.cfg
├── dynamic-assignments
│   └── env-vars.yml
├── env-vars
│   ├── dev.yml
│   ├── prod.yml
│   ├── staging.yml
│   └── uat.yml
├── group_vars
│   ├── all.yml
│   └── lb.yml
├── inventory
│   ├── dev.yml
│   ├── prod.yml
│   ├── staging.yml
│   └── uat.yml
├── playbooks
│   └── site.yml
├── roles
│   ├── apache_lb
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   └── templates
│   │       └── apache-lb.conf.j2
│   ├── install_apache_lb
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   └── templates
│   │       └── webserver-lb.conf.j2
│   ├── mysql
│   │   ├── LICENSE
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── molecule
│   │   │   └── default
│   │   │       ├── converge.yml
│   │   │       └── molecule.yml
│   │   ├── tasks
│   │   │   ├── configure.yml
│   │   │   ├── databases.yml
│   │   │   ├── main.yml
│   │   │   ├── replication.yml
│   │   │   ├── secure-installation.yml
│   │   │   ├── setup-Archlinux.yml
│   │   │   ├── setup-Debian.yml
│   │   │   ├── setup-RedHat.yml
│   │   │   ├── users.yml
│   │   │   └── variables.yml
│   │   ├── templates
│   │   │   ├── my.cnf.j2
│   │   │   ├── root-my.cnf.j2
│   │   │   └── user-my.cnf.j2
│   │   └── vars
│   │       ├── Archlinux.yml
│   │       ├── Debian-10.yml
│   │       ├── Debian-11.yml
│   │       ├── Debian-12.yml
│   │       ├── Debian.yml
│   │       ├── RedHat-7.yml
│   │       ├── RedHat-8.yml
│   │       └── RedHat-9.yml
│   ├── nginx_lb
│   │   ├── :wq
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   └── templates
│   │       └── nginx-lb.conf.j2
│   └── webserver
│       ├── README.md
│       ├── defaults
│       │   └── main.yml
│       ├── handlers
│       │   └── main.yml
│       ├── meta
│       │   └── main.yml
│       ├── tasks
│       │   └── main.yml
│       └── templates
└── static-assignments
    ├── common.yml
    ├── common2.yml
    ├── commondel.yml
    ├── deploy-apache-lb.yml
    └── uat-webservers.yml

```
## More areas to expore
- Use community roles to achieve the same result
- Add error handling and include 'successful deployment test' in nginx ansible playbook
- Add more..

## Conclusion

We explored ansible dynamic assignments, manual roles and community roles. We also applied it in configuring two load balancers for our web app.
