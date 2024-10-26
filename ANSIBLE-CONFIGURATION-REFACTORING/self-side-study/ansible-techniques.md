
# Ansible Techniques for DevOps

## Handlers
- Used for triggering actions only when changes occur
- Common use: Restart services only when config files change

```yaml
handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```
Reference: [Handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#handlers)


## Variables and Facts
- Custom variables in `group_vars`/`host_vars`

- Using `register` to capture command outputs

- Gathering system facts with the setup module

```yaml
- name: Get command output
  command: whoami
  register: user_output
```
Reference: [Using Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)

## Templates (Jinja2)
- Dynamic configuration file generation
- Conditionals and loops in templates

```yaml
- name: Configure app
  template:
    src: app.conf.j2
    dest: /etc/app/config.conf
```
Reference: [Template Module](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)

## Vault
- Encrypt sensitive data like passwords and keys

```yaml
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
```
Reference: [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

## Tags
- Selectively run parts of playbooks

```yaml
tasks:
  - name: Install packages
    apt:
      name={{ item }}
    with_items: ['nginx', 'mysql']
    tags: ['packages']
```

Reference: [Tags](https://docs.ansible.com/ansible/latest/user_guide/playbooks_tags.html)

## Conditionals
- when clause for conditional execution
- failed_when and changed_when for custom status

```yaml
- name: Install specific package on Ubuntu
  apt:
    name=apache2
  when: ansible_distribution == "Ubuntu"
```

Reference:[Conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html)

## Error Handling
- `ignore_errors`
- `block/rescue/always` structure

```yaml
block:
  - name: Attempt risky task
    command: /risky/command
rescue:
  - name: Handle failure
    debug:
      msg="Task failed but we caught it"
```
Reference: [Error handling](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html)


## Delegation
- `delegate_to` for running tasks on different hosts
- `local_action` for running on control node

```yaml
- name: Create backup
  command: pg_dump -U postgres database
  delegate_to: backup_server
```
Reference: [Delegation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html)


## Strategy Plugins
- Control how Ansible executes tasks across hosts
- Strategies include linear (default), free, debug strategies

```yaml
- hosts: all
  strategy: free
  tasks:
    # tasks here
```
Reference:[Strategies](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)

## Custom Modules
- Write your own modules in Python
- Extend Ansible's functionality for specific needs

Reference: [Developing Modules](https://docs.ansible.com/ansible/latest/dev_guide/collections_galaxy_meta.html#developing-modules)