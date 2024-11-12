# Some Ansible Modules

## The Ansible `uri` module

The Ansible `uri` module is a versatile tool for interacting with web resources, and it's useful in software deployment. It  allows you to interact with HTTP/HTTPS resources. It can be used to:
- Download files
- Send HTTP requests (e.g., GET, POST, PUT, DELETE)
- Verify the existence of a resource
- Retrieve information about a resource (e.g., headers, status code)

In software deployment, the uri module can be used in various ways:

1. Downloading artifacts
Instead of cloning a Git repository, you can use the uri module to download specific artifacts (e.g., JAR, WAR, ZIP files) from a URL. This approach is useful when you only need a specific version of the software.

```yaml
- name: Download artifact
  uri:
    url: https://example.com/software-1.2.3.jar
    dest: /path/to/destination
    method: GET
```
2. Retrieving deployment scripts
You can use the uri module to download deployment scripts (e.g., shell scripts, PowerShell scripts) from a central location.

```yaml
- name: Download deployment script
  uri:
    url: https://example.com/deploy-script.sh
    dest: /path/to/destination
    method: GETl
```

3. Triggering deployments
The uri module can be used to trigger deployments by sending HTTP requests to a deployment API.

```yaml
- name: Trigger deployment
  uri:
    url: https://example.com/deploy
    method: POST
    body: '{"environment": "production"}'
    body_format: json
```
4. 4. Verifying deployment status
You can use the uri module to verify the status of a deployment by checking the HTTP response code or headers.

```yaml 
- name: Verify deployment status
  uri:
    url: https://example.com/deployment-status
    method: GET
  register: deployment_status
  until: deployment_status.json.status == "success"
  retries: 5
  delay: 10
```
