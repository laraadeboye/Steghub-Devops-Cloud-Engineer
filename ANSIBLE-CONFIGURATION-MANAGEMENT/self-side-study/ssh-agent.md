
# SSH Agent Explained

## What is the SSH Agent?

The SSH agent (`ssh-agent`) is a key manager for SSH that holds your keys and certificates in memory, unencrypted, and ready for use by `ssh`. It eliminates the need to type a passphrase every time you connect to a server. The agent runs in the background on your system, typically starting up the first time you run `ssh` after a reboot. 

### Key Features:
- **Security**: The SSH agent keeps private keys safe by not writing any key material to disk and not allowing private keys to be exported. Keys stored in the agent can only be used for signing messages.
- **Authentication Process**: During the SSH handshake, the client presents a public key to the server, which sends a random message for the client to sign using their private key. The client asks the SSH agent to sign this message, proving possession of the private key without exposing it.

## How Does It Work?

The SSH agent communicates with the SSH client via a Unix domain socket using the SSH agent protocol. Typical operations include adding or removing keys, listing stored keys, and signing messages. The command `ssh-add` is used to manage keys in the agent.

### Agent Forwarding
SSH's agent forwarding feature allows your local SSH agent to authenticate on remote servers through an existing SSH connection. For example, if you SSH into an EC2 instance and want to clone a private GitHub repository from there, agent forwarding lets you use your local keys without needing to store them on the EC2 host.

## Security Considerations
While agent forwarding is convenient, it introduces security risks. If an attacker gains root access on a remote host where agent forwarding is enabled, they could access your local SSH agent and use your keys. To mitigate this risk:
- Avoid enabling `ForwardAgent` by default.
- Lock your SSH agent when using forwarding.
- Consider alternatives like `ProxyJump`, which does not require forwarding.



## Two methods of setting up SSH Agent for Ansible

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

 
 **Alternative method**

  When managing multiple servers, you may need different settings for different servers, you can use the method of editting the SSH config file below: 

  - Create or edit the SSH config file

```sh
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    vi ~/.ssh/config

```

  - Add the following configuration (Modify for other additional servers):

```
    Host jenkins-ansible
    HostName your.server.ip.address
    User your_username
    IdentityFile ~/.ssh/your_private_key
    ForwardAgent yes
```
  - Set the proper permissions:

```
    chmod 600 ~/.ssh/config
```
  - Copy the SSH Key to `jenkins-ansible-server`
    
```sh
    # Copy your public key
    ssh-copy-id -i ~/.ssh/your_private_key.pub     your_username@your.server.ip.address

    # Test the connection
    ssh jenkins-ansible
```
## Conclusion
The SSH agent simplifies secure authentication by managing your SSH keys efficiently while minimizing security risks. Understanding how it works and its implications is crucial for maintaining secure DevOps practices.

Reference(s)
- [Smallstep's blog on SSH Agent](https://smallstep.com/blog/ssh-agent-explained/).