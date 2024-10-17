# Relevance of Ansible to DevOps

Ansible is a powerful open-source automation tool that plays a significant role in DevOps by simplifying the management of IT infrastructure through automation, orchestration, and configuration management.

It enables teams to automate repetitive tasks, streamline workflows, and ensure consistent environments across development, testing, and production stages. Ansible's agentless architecture allows it to manage systems over SSH or WinRM without requiring additional software on the managed nodes. 

This makes it particularly useful for provisioning resources, deploying applications, and managing configurations at scale. 

By leveraging Ansible, organizations can enhance collaboration between development and operations teams, reduce deployment times, and improve overall system reliability.

## Setting Up Ansible

1. **Install Ansible**:
   - On a control node (e.g., Ubuntu), run:
     ```bash
     sudo apt update
     sudo apt install ansible
     ```

2. **Define Inventory**:
   - Create an inventory file (e.g., `hosts.ini`) listing your managed nodes:
     ```ini
     [webservers]
     server1 ansible_host=192.168.1.10
     server2 ansible_host=192.168.1.11
     ```

3. **Create Playbook**:
   - Write a playbook (e.g., `setup.yml`) to define tasks:
     ```yaml
     ---
     - hosts: webservers
       tasks:
         - name: Install Apache
           apt:
             name: apache2
             state: present
     ```

4. **Run Playbook**:
   - Execute the playbook using the command:
     ```bash
     ansible-playbook -i hosts.ini setup.yml
     ```

5. **Verify Installation**:
   - Check if Apache is running on the managed nodes.

## Reference
- [Ansible's website](https://docs.ansible.com/ansible/latest/index.html).