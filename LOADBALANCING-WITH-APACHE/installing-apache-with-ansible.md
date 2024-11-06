# Installing Apache Load balancer for tooling app with Ansible

Using Ansible to automate the installation and configuration of your Apache load balancer is often great approach. It will save time, ensure consistency, and make it easier to reapply configurations or set up additional load balancers if needed. We will set up Apache as a load balancer using Ansible, based on your current manual instructions found [here](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/loadbalancing-with-apache.md)

## Step 0 Install Prerequisites

- Spin up a new server named `apache_lb` for your load balancer on AWS manually or using IAC such as terraform. We will be using ubuntu LTS 24.04. Add the server private IP to the `inventory/dev.yml` under the `[lb]`

[new apache lb running]


**inventory/dev.yml content**
```sh
 [nfs]
 172.31.39.177 ansible_ssh_user=ec2-user

 [webservers]
 172.31.32.255 ansible_ssh_user=ec2-user
 172.31.35.27 ansible_ssh_user=ec2-user
 172.31.32.34 ansible_ssh_user=ec2-user

 [db]
 172.31.38.76 ansible_ssh_user=ubuntu

 [lb]
 172.31.46.249 ansible_ssh_user=ubuntu # Nginx
 172.31.16.59 ansible_ssh_user=ubuntu # Apache

 [db:vars]
 env_vars_file=../env-vars/dev.yml  # Specify environment variables file for database setup
```

Replace appropriately for your set up
[add new apache lb...]


## Step 1 Prepare the Ansible inventory and variable files
- Create a new role for the directory structure. 

```sh
ansible-galaxy init role/apache_lb
```

- Define the variable in the `roles/apache_lb/defaults/main.yml` folder.
```yaml
---
# defaults file for apache_lb

enable_apache_lb: false
load_balancer_is required: false
web_servers_hosts:
  - { ip: "172.31.32.255", hostname: "web01" }
  - { ip: "172.31.35.27", hostname: "web02" }
  - { ip: "172.31.32.34", hostname: "web03" }

backend_servers:
  - { hostname: "web01", port: "80" }
  - { hostname: "web02", port: "80" }
  - { hostname: "web03", port: "80" }

```
Replace the webserver hosts IP with the private IP of your app backend_servers

- Create the configuration template named `webserver-lb.conf.j2` in `roles/apache_lb/templates/`

```sh
vi roles/apache_lb/templates/webserver-lb.conf.j2
```

Paste the following configuration:

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Proxy "balancer://mycluster">
        {% for server in backend_servers %}
        BalancerMember "http://{{ server.hostname }}:{{ server.port}}"
        { % endfor % }
            
        # ProxySet lbmethod=byrequests
        ProxySet lbmethod=bytraffic
    </Proxy>

    ProxyPreserveHost On
    ProxyPass "/" "balancer://mycluster/"
    ProxyPassReverse "/" "balancer://mycluster/"
</VirtualHost>

```

- Use Ansible tasks to install and configure Apache in the `roles/apache_lb/tasks/main.yml` file:

```yaml
# update apt repository
- name: Update and install Apache
  become: true
  apt:
    name: apache2
    state: present
    update_cache: yes

- name: Install development package for libxml2 library
  become: true
  apt:
    name: libxml2-dev
    state: present
    update_cache: yes

# Enable apache modules 
- name: Enable Apache modules for load balancing
  become: true
  command: "a2enmod {{ item }}"
  loop:
    - proxy
    - proxy_http
    - proxy_balancer
    - lbmethod_bytraffic
    - headers
  notify: restart apache

# Configure local dns
- name: Update /etc/hosts with backend server hostnames
  become: true
  lineinfile:
    path: /etc/hosts
    line: "{{ item.ip }} {{ item.hostname }}"
    state: present
    create: yes
  loop: "{{ web_servers_hosts }}"
  tags:
    - dns

# Configure load balancer
- name: Create load balancing configuration
  become: true
  template:
    src: webserver-lb.conf.j2
    dest: /etc/apache2/sites-available/webserver-lb.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart apache
  tags:
    - apache

# enable the webserver-lb config
- name: Enable webserver load balancer configuration
  become: true
  command: a2ensite webserver-lb.conf
  notify: restart apache
  tags:
    - apache

# disable the default config
- name: Disable default Apache site configuration
  become: true
  command: a2dissite 000-default.conf
  notify: restart apache
  tags:
    - apache

``` 
- In `roles/apache_lb/handlers/main.yml`, define a handler to restart Apache when changes are made.:

```yaml
- name: restart apache
  become: true
  service:
    name: apache2
    state: restarted
```

- Now, we will create a file named `deploy-apache-lb.yml` in the `static-assignments/` folder. Enter the following task.

```yaml
---
- name: Deploy Apache Load Balancer
  hosts: apache_lb
  roles:
    - role: apache_lb
      
```

Run the playbook:

```sh
ansible-playbook -i inventory/uat.yml static-assignments/deploy-apache-lb.yml
```
*Troubleshooting*
When I run the playbook
I get the error "could not match host pattern" as shown:
[apach-error host]
This means that there no host called `apache_lb` in my dev.yml. This will be resolved by modifying my variable files to specify apache load balancer host. 

- Create a group variable called `lb.yml` in the `group_vars/` folder and enter the following:

```yaml
# group_vars/lb.yml

# Set lb_type per host
172.31.46.249:
  lb_type: "nginx"

172.31.16.59:
  lb_type: "apache"

# Common variables for all load balancers
lb_port: 80

```

[apache lb.yml]

- Modify the `inventory/uat.yml` assigning variable of lb_type to the load balancers:

```yaml
[uat-webservers]

172.31.90.131 ansible_ssh_user='ec2-user'
172.31.85.227 ansible_ssh_user='ec2-user'

[lb]
172.31.46.249 ansible_ssh_user=ubuntu lb_type=nginx # Nginx
172.31.16.59 ansible_ssh_user=ubuntu lb_type=apache # Apache
```
- Modify the `static-assignments/deploy-apache-lb.yml` file to specify the load balancer as apache

```yaml
- name: Deploy Apache Load Balancer
  hosts: lb
  become: true
  tasks:
    - name: Deploy Apache Load Balancer
      include_role:
        name: apache_lb
      when: lb_type == 'apache'

```

Then run ansible playbook against the uat environment:

```sh
ansible-playbook -i inventory/dev.yml static-assignments/deploy-apache-lb.yml
```

Testing the acessibility of the IP of the apache load balancer, I get the following image which indicates the successful deployment of the load balancer
[Ansi Apache balancer public IP]