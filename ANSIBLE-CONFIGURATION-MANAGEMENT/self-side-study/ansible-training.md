# Comprehensive Ansible Training Manual

## A Practical Guide for DevOps Implementation

### Table of Contents
1. [Fundamental Concepts](#fundamental-concepts)
2. [Installation and Configuration](#installation-and-configuration)
3. [Core Components](#core-components)
4. [Playbook Development](#playbook-development)
5. [Variables and Facts](#variables-and-facts)
6. [Managing Inventory](#managing-inventory)
7. [Role Development](#role-development)
8. [Advanced Topics](#advanced-topics)
9. [Best Practices](#best-practices)
10. [Real-World Applications](#real-world-applications)

## 1. Fundamental Concepts

### 1.1 What is Ansible?
- Ansible is an **agentless automation tool**.
- It utilizes **SSH** for communication.
- Employs a **declarative language** (YAML) for configuration.
- Ensures **idempotent execution**, meaning repeated runs produce the same result.
- Operates on a **push-based architecture**.

### 1.2 Key Advantages
- No agents are necessary on managed nodes.
- Utilizes a straightforward **YAML syntax**.
- Offers an extensive library of **modules**.
- Supports **reusable configurations**.
- Compatible with **version control systems**.

## 2. Installation and Configuration

### 2.1 Control Node Requirements
To install Ansible, use the following commands:

```sh
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# RHEL/CentOS
sudo yum install ansible

# Verify installation

ansible --version
```

### 2.2 Initial Configuration

```ini
# /etc/ansible/ansible.cfg
[defaults]
inventory = ./inventory
remote_user = ansible
host_key_checking = False
timeout = 30

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

## 3. Core Components

### 3.1 Inventory Structure

```ini
# Basic inventory (inventory/dev.yml)
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[dbservers]
db1.example.com ansible_host=192.168.1.20

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### 3.2 Advanced Inventory (YAML format)

```yaml
# inventory/prod.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
          http_port: 80
        web2:
          ansible_host: 192.168.1.11
          http_port: 8080
    dbservers:
      hosts:
        db1:
          ansible_host: 192.168.1.20
          mysql_port: 3306
  vars:
    ansible_user: ec2-user
    ansible_become: yes
```

## 4. Playbook Development

### 4.1 Simple Playbook Structure

```yaml
# playbooks/webserver.yml
---
- name: Configure webservers
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
      when: ansible_os_family == "Debian"
    
    - name: Start Apache service
      service:
        name: apache2
        state: started
        enabled: yes
```

### 4.2 Handlers and Notifications

```yaml
# playbooks/advanced-webserver.yml
---
- name: Configure advanced webserver
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
      notify: Restart Apache
    
    - name: Configure Apache
      template:
        src: templates/apache.conf.j2
        dest: /etc/apache2/apache2.conf
      notify: Restart Apache
  
  handlers:
    - name: Restart Apache
      service:
        name: apache2
        state: restarted
```

## 5. Variables and Facts

### 5.1 Variable Types

```yaml
# group_vars/all.yml
---
# Global variables
global_timeout: 30
ntp_servers:
  - ntp1.example.com
  - ntp2.example.com

# group_vars/webservers.yml
---
http_port: 80
doc_root: /var/www/html

# host_vars/web1.example.com.yml
---
backup_folder: /backup/web1
```

### 5.2 Using Variables in Playbooks

```yaml
# playbooks/variables-demo.yml
---
- name: Demonstrate variables
  hosts: webservers
  vars:
    local_var: "Local Value"
  vars_files:
    - vars/external_vars.yml
    
  tasks:
    - name: Show variable usage
      debug:
        msg: "HTTP Port is {{ http_port }}"
    
    - name: Create backup directory
      file:
        path: "{{ backup_folder }}"
        state: directory
        mode: '0755'
```


## 6. Inventory Management

### 6.1 Dynamic Inventory

```py
#!/usr/bin/env python3
# dynamic_inventory.py
import json

def get_inventory():
    return {
        'webservers': {
            'hosts': ['web1', 'web2'],
            'vars': {
                'http_port': 80
            }
        },
        '_meta': {
            'hostvars': {
                'web1': {
                    'ansible_host': '192.168.1.10'
                },
                'web2': {
                    'ansible_host': '192.168.1.11'
                }
            }
        }
    }

if __name__ == '__main__':
    print(json.dumps(get_inventory()))
```

## 7. Role Development

### 7.1 Role Structure

```plaintext
roles/
└── webserver/
    ├── defaults/
    │   └── main.yml
    ├── files/
    ├── handlers/
    │   └── main.yml
    ├── meta/
    │   └── main.yml
    ├── tasks/
    │   └── main.yml
    ├── templates/
    │   └── vhost.conf.j2
    └── vars/
        └── main.yml
```

## 7.2 Example Role

```yaml
# roles/webserver/tasks/main.yml
---
- name: Install required packages
  apt:
    name: "{{ item }}"
    state: present
  loop: "{{ web_packages }}"

- name: Configure virtual hosts
  template:
    src: vhost.conf.j2
    dest: /etc/apache2/sites-available/{{ item.domain }}.conf
  loop: "{{ virtual_hosts }}"
  notify: Reload Apache

# roles/webserver/defaults/main.yml
---
web_packages:
  - apache2
  - php
  - libapache2-mod-php

virtual_hosts: []

# Using the role in a playbook
---
- name: Configure web servers
  hosts: webservers
  roles:
    - role: webserver
      vars:
        virtual_hosts:
          - domain: example.com
            port: 80
```

## 8. Advanced Topics

### 8.1 Error Handling
```yaml
# playbooks/error-handling.yml
---
- name: Demonstrate error handling
  hosts: webservers
  
  tasks:
    - name: Attempt risky operation
      command: /risky/operation
      ignore_errors: yes
      register: operation_result
    
    - name: Handle failure
      when: operation_result.failed
      block:
        - name: Cleanup after failure
          file:
            path: /temp/cleanup
            state: absent
          
        - name: Notify on failure
          mail:
            to: admin@example.com
            subject: Operation failed
            body: Cleanup completed
      rescue:
        - name: Handle cleanup failure
          debug:
            msg: "Cleanup failed, manual intervention required"
```

### 8.2 Async Operations

```yaml
# playbooks/async-tasks.yml
---
- name: Long-running tasks
  hosts: webservers
  
  tasks:
    - name: Start backup
      command: /usr/local/bin/backup.sh
      async: 3600  # 1 hour timeout
      poll: 0      # Don't wait
      register: backup_job
    
    - name: Check backup status
      async_status:
        jid: "{{ backup_job.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 30
      delay: 60
```

## 9. Best Practices

### 9.1 Directory Structure

```plaintext
ansible-project/
├── ansible.cfg
├── inventory/
│   ├── prod/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── dev/
│       ├── hosts.yml
│       └── group_vars/
├── roles/
├── playbooks/
├── vars/
└── templates/
```

### 9.2 Version Control

```gitignore
# .gitignore
*.retry
*.pyc
.vault_pass
inventory/*/host_vars/*
!inventory/*/host_vars/.gitkeep
```

### 9.3 Vault Usage

```sh
# Create encrypted variables
ansible-vault create group_vars/all/vault.yml

# Edit encrypted files
ansible-vault edit group_vars/all/vault.yml

# Using vault in playbooks
ansible-playbook site.yml --ask-vault-pass
```

## 10. Real-World Applications
### 10.1 Complete Three-Tier Application

```yaml
# playbooks/three-tier-app.yml
---
- name: Configure Load Balancer
  hosts: lb
  roles:
    - haproxy
    - monitoring

- name: Configure Web Servers
  hosts: webservers
  roles:
    - common
    - php
    - apache
    - app-deploy

- name: Configure Database
  hosts: dbservers
  roles:
    - common
    - mysql
    - backup

# roles/haproxy/templates/haproxy.cfg.j2
global
    log /dev/log local0
    maxconn 4096
    
defaults
    log global
    mode http
    option httplog
    
frontend http_front
    bind *:80
    default_backend http_back
    
backend http_back
    balance roundrobin
    {% for host in groups['webservers'] %}
    server {{ host }} {{ hostvars[host]['ansible_host'] }}:80 check
    {% endfor %}
```

### 10.2 CI/CD Integration

```yaml
# Jenkinsfile
pipeline {
    agent any
    
    environment {
        ANSIBLE_CONFIG = "${WORKSPACE}/ansible.cfg"
    }
    
    stages {
        stage('Deploy to Development') {
            steps {
                ansiblePlaybook(
                    playbook: 'playbooks/site.yml',
                    inventory: 'inventory/dev',
                    credentialsId: 'ansible-ssh-key'
                )
            }
        }
        
        stage('Run Tests') {
            steps {
                ansiblePlaybook(
                    playbook: 'playbooks/tests.yml',
                    inventory: 'inventory/dev',
                    credentialsId: 'ansible-ssh-key'
                )
            }
        }
    }
}
```


This guide provides a foundation for working with Ansible in real-world scenarios. Key areas to focus on next:

- Security hardening
- Performance optimization
- Custom module development
- Advanced inventory management
- Integration with other tools (Terraform, Docker, etc.)

Remember to always:

- Use version control
- Document your code
- Test in development before production
- Follow the principle of least privilege
- Keep playbooks idempotent
- Use roles for reusability
