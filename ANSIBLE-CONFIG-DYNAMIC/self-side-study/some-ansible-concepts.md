
# Some concepts in Ansible
Ansible is an open-source automation tool that follows the Infrastructure as Code (IaC) paradigm. It uses YAML-based playbooks to describe and automate configurations, deployments, and orchestration tasks. Ansible is integral to DevOps as it promotes consistency, repeatability, and efficiency in managing IT infrastructure.

- **Reference**: [Ansible Documentation - Introduction](https://docs.ansible.com/ansible/latest/user_guide/intro_guide.html)

# Roles in Ansible
Roles provide a way to organize your playbooks and make them more modular and reusable. A role is essentially a collection of tasks, variables, and files organized in a specific directory structure. It helps in breaking down complex automation into manageable and shareable components, enhancing code maintainability.

You can create a role manually or using `ansible-galaxy`

- **Reference**: [Ansible Documentation - Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#roles)

## Dynamic Assignment in Ansible

Dynamic assignment in Ansible generally refers to defining values or inventory dynamically, such as retrieving data from an external source or using variables that change based on conditions. 

## Examples Include:

### Dynamic Inventory
Uses scripts, APIs, or cloud plugins to pull in host information at runtime, which is common when working with cloud environments (like AWS, GCP) where IPs and hostnames might change.

### Variable Evaluation
Assigning variables based on conditions, facts gathered from hosts, or external data sources (e.g., using the `set_fact` module or lookup plugins).

### Jinja2 Templating
Often used to dynamically render values within templates or playbooks based on host-specific information or conditional logic.

### Usage Example:

```yaml
- name: Assign a dynamic variable based on a condition
  set_fact:
    server_env: "{{ 'production' if inventory_hostname == 'prod-server' else 'staging' }}"

```

- **Reference**: [Ansible Documentation - Dynamic Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html)

## Static Assignment in Ansible

Static assignment refers to defining values explicitly, either in inventory files, playbooks, or variable files, where values do not change at runtime. 

### This Could Mean:

### Static Inventory
A plain `.ini` or `.yml` file listing the host IPs and group assignments directly, with no need to fetch or calculate anything dynamically.

### Static Variables
Hardcoded variables in playbooks, roles, or group vars/host vars that do not change based on conditions or external inputs.

---

## Usage Example:

```ini
# inventory/uat.yml
[uat-webservers]
172.31.90.131 ansible_ssh_user='ec2-user'
172.31.85.227 ansible_ssh_user='ec2-user'

```
- **Reference**: [Ansible Documentation - Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

## Conditional logic in ansible
Mastery of `set_fact` and `Jinja2 templating` is especially important in DevOps environments where configurations need to adapt to different environments or hosts dynamically. Assigning variables based on conditions is useful in Ansible. Practicing them can make your playbooks much more flexible and adaptable.

1. Using `set_fact` for Conditional Variable Assignment
The `set_fact` module is commonly used to define variables at runtime based on conditions.
You can evaluate conditions and assign values based on the outcome.

```yaml
- name: Set environment-specific variable
  set_fact:
    server_type: "{{ 'database' if inventory_hostname == 'db-server' else 'application' }}"

```
Here, if the `inventory_hostname` matches "`db-server`," server_type will be set to `database`; otherwise, it will be set to `application`.

**Reference**: [Ansible Documentation - set fact](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/set_fact_module.html)

2. Conditionals in Variable Definitions (`vars` block)
You can use a `vars` block within a task or play to define variables based on conditions.

```yaml
- name: Assign region based on environment
  hosts: all
  vars:
    region: "{{ 'us-east-1' if environment == 'production' else 'us-west-2' }}"

```
Here, the variable `region` will change depending on whether environment is `production`.

3. Conditional Defaults with Jinja2 Filters (`default`, `if-else` expressions)
Jinja2 templating within Ansible allows for conditional expressions, which can be used in variable assignments or templates.

```yaml
- name: Define default based on other variables
  debug:
    msg: "Service is {{ 'enabled' if enable_service | default(false) else 'disabled' }}"

```
This approach is useful when you want to use defaults that change based on existing conditions.

4. Group Variables and Host Variables with `when` Conditions
You can also define different sets of variables for different groups or hosts and control when they are applied with the when keyword.

```yaml
tasks:
  - name: Set database port for each environment
    set_fact:
      db_port: "{{ '5432' if environment == 'production' else '5433' }}"
    when: environment is defined

```

5. Using `include_vars` for Conditional Variable Files
You can conditionally include different variable files based on certain facts or variable values.

```yaml
- name: Include environment-specific variables
  include_vars: "{{ environment }}.yml"
  when: environment is defined

```
Other conditional logic include:
- Dynamic Task Inclusion: Use `include_tasks` and `import_tasks`.
- Group/Host-Specific Variables: Defined in `group_vars` and `host_vars`.
- Conditionals in Loops: `with_items` and `when` together.
- Filters for Complex Conditions: Leverage Jinja2 filters like `selectattr` and `map`.
- Logical Operators: Chain conditions with `and`, `or`, `not`.

- **Reference**: [Ansible Documentation - Conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html)

- **Reference**: [Ansible Documentation - Variables](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html)

- **Reference**: [Ansible Documentation - Ansible best practices](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)