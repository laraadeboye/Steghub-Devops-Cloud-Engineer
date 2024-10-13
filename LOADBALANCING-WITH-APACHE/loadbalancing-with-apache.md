
# Load Balancing with Apache - Setting up a load balancer for the three-tier application

![Architecture](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/3-tier%20web%20application%20with%20database%20and%20NFS%20server.png)

## Project Overview

Previously we set up a [3-tier devops solution](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/DEVOPS-TOOLING-SOLUTION/devops-tooling-solution.md) with three web servers having different public IPS and different DNS names. We will configure a load balancer to manage traffic to each of the web servers through one dns name and IP.

This will enhance the three-tier architecture by improving scalability and providing a single point of access for users.

We will be using a dedicated Ubuntu server instance launched on AWS to configure our load balancer.  This helps to avoid resource contention and to maintain security isolation between different tiers as there is separation of concerns thereby preventing the introduction of a single point of failure.

Visit my [Readme](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/self-side-study/loadbalancing-concepts.md) for more explanation of load balancing concepts.


## Prerequisites
- Basic AWS knowledge
- Three RHEL9 webservers running
- One MySql DB server (based on ubuntu 24.04) running
- One RHEL9 NFS server running
- Root or sudo access on application webservers and ubuntu instance for the loadbalancer
- [Apache Load balancer documentation](https://httpd.apache.org/docs/2.4/mod/mod_proxy_balancer.html)


## Steps
###  Step 0. Launch an Ubuntu EC2 instance.
- Create a security group for the loadbalancer instance on AWS named `lb-sg`. Allow inbound access on port `80` from everywhere `0.0.0.0/0` on the internet. I also allowed access from HTTPS on port `443` and SSH access on port `22` to access the server for configurations.

![lb-sg security group rules](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/lb-sg%20security%20group%20rules.png)

- Launch a `t2.micro` sized ubuntu instance 24.04 LTS on AWS named `webserver-lb` with the security group `lb-sg` that we created. Depending on the specific workload, a larger instance may be needed in production settings. Valid reasons why you may want to increase instance size can be found in my [Readme](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/self-side-study/loadbalancing-concepts.md) on the subject.

![webserver-lb running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/webserver-lb%20running.png)

- Connect to the instance with instance connect or via your local system. I will be using instance connect. 

*Hint*: When using instance connect, ensure that SSH inbound access on port `22` is allowed from instance connect IP range `18.206.107.24/29`. For your local system, inbound access on port 22 from your local IP range should be allowed.

- Update and upgrade ubuntu instance:

```sh
sudo apt update -y
sudo apt upgrade -y
```

###  Step 1. Install Apache and the required modules:

The apache `mod_proxy` module is used for load balancing protocols including `HTTP` and `HTTPS`. This module is combined with other modules for effective load balancing. Install them with the following commands (comments included for explanation):

```sh
# Install Apache
sudo apt install apache2 -y

# Install development package for the libxml2 library which may be required as a dependency for other modules
sudo apt install libxml2-dev -y


# Enable the mod_rewrite module. It can be useful for URL manipulation before passing requests to backend servers.
sudo a2enmod rewrite

# Enable loadbalancing module
sudo a2enmod proxy

# For HTTP protocol
sudo a2enmod proxy_http

# For maintaining stickiness
sudo a2enmod proxy_balancer

# load balance scheduling algorithm
sudo a2enmod lbmethod_bytraffic

# Enable headers. Allows manipulation of HTTP request and response headers.
sudo a2enmod headers
```
The history of the commands run to install Apache2 and modules are shown:
![install apache and modules](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/install%20apache%20and%20modules.png)

Run `sudo systemctl status apache2` to verify that it is enabled and running:

![Apache running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/apache2%20running.png)

###  Step 2. Configure Apache as a Load balancer
We will create a new configuration file in the `sites-available` folder named `webserver-lb.conf`

```sh
sudo vi /etc/apache2/sites-available/webserver-lb.conf
```

- Add the following configuration. Replace the placeholders as necessary for your use case.

```sh
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Proxy "balancer://mycluster">
        BalancerMember "http://web1.example.com"
        BalancerMember "http://web2.example.com"
        BalancerMember "http://web2.example.com"
        # You can add more members here
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPreserveHost On
    ProxyPass "/" "balancer://mycluster/"
    ProxyPassReverse "/" "balancer://mycluster/"
</VirtualHost>
```

Replacing `http://web1.example.com` and others with my server Public-IPS which are: `184.72.181.7`, `3.81.71.198` and `18.209.111.102` for `webserver-01`, `webserver-02` and `webserver-03` respectively.

Note that If you previously stopped your instances, note that the the IPS will change as in my case unless you preserve them with AWS Elastic IP feature.

Here is my configuration:
```sh
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Proxy "balancer://mycluster">
        BalancerMember "http://184.72.181.7:80" loadfactor=5 timeout=1 
        BalancerMember "http://3.81.71.198:80" loadfactor=5 timeout=1 
        BalancerMember "http://18.209.111.102:80" loadfactor=5 timeout=1     
        # ProxySet lbmethod=byrequests
        ProxySet lbmethod=bytraffic
    </Proxy>

    ProxyPreserveHost On
    ProxyPass "/" "balancer://mycluster/"
    ProxyPassReverse "/" "balancer://mycluster/"
</VirtualHost>

```

Within the configuration, we are using the `bytraffic` scheduling  algorithm. This distributes load based on the amount of traffic (in bytes) sent to each backend server. The proportion by which the traffic load is distributed accross all the servers can be controlled by the `loadfactor` as shown in the configuration.

- `loadfactor=5`: Assigns a weight to the server, determining how many requests it handles relative to other members. Higher values mean more requests. In our case, traffic will be distributed evenly to all servers since the loadfactor is the same.

- `timeout=1`: Sets the connection timeout to 1 second.

-`ProxyPreserveHost on` maintains the original Host header.

Note that this is a very basic configuration setting and it can be improved to incorporate the following areas for improvement: 

- Lacks SSL/TLS configuration for secure communication.
- Missing health checks for backend servers.
- No sticky session configuration, which might be necessary for stateful applications.
- Timeout value is very low (1 second), which might lead to premature failovers.
- No rate limiting or request throttling mechanisms.
- Lacks detailed logging for load balancer-specific information.

Suggestions for improvement can be found in my [README.md](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/self-side-study/optimizing-apachelb-configuration.md) 

###  Step 3. Enable the new configuration and disable the default

Run the following command to enable the new configuration and disable the default:

```sh
sudo a2ensite webserver-lb.conf
sudo a2dissite 000-default.conf
```

###  Step 4. Test the configuration and restart Apache

```sh
sudo apache2ctl configtest
sudo systemctl restart apache2
```
![edit configuration](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/edit%20configuration.png)

###  Step 5. Configure Firewall
To ensure that Apache Load balance instance can communicate with the web servers and users can access the load balancer, the firewall rules should be configured:

```sh
sudo ufw status # check if the firewall is enabled. If disabled, igrore it

# if enabled allow Apache
sudo ufw allow 'Apache Full'

```

###  Step 6. Test the Load balancer

Access the load balancer's IP address in a web browser:
My load balancer public IP is `204.236.248.3`

```sh
http://[webserver-lb PUBLIC_IP]
```
Replace [webserver-lb PUBLIC_IP] with the public IP of the load balancer.

![accessing app through lb IP](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/Acessing%20app%20from%20lb%20ip.png)

&nbsp;
![login to app from lp IP](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/login%20to%20app%20from%20lb%20IP.png)

We want to test each webservers from their terminal and view their individual logs.
Open ssh terminals of the three webservers or use instance connect to access their terminals. We will first unmount the log files from the nfs server using the following commands:


First verify if /var/log/httpd is mounted on nfs server. Run this command on each of the webservers:

```sh
df -h
```
**webserver-01 `df -h`**
![df -h verify webserver-01](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/df%20-h%20verify%20webserver-01.png)

**webserver-02 `df -h`**
![df -h verify webserver-02](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/df%20-h%20verify%20webserver-02.png)

**webserver-03 `df -h`**
![df -h verify webserver-03](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/df%20-h%20verify%20webserver-03.png)


Then unmount the directory in each webserver: 
```sh
# unmount
sudo umount /var/log/httpd

# Optionally check the processes using the file with the lsof command
sudo lsof +D /var/log/httpd

# stop the services using the directory if it is busy
sudo systemctl stop httpd

# verify id /var/log/httpd is unmounted from nfs server
df -h
```

![lsof to determine processes](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/lsof%20to%20determine%20processes.png)


Notice that the directory has been unmounted.
![df -h after unmount](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/df%20-h%20after%20unmount.png)

Run the following command on each terminal of the webservers:

```sh
sudo tail -f /var/log/httpd/access_log
```
By refreshing our browser (load balancer IP) multiple times, we get the following results on each server: (Notice the access is from the load balancer IP- `204.236.248.3`)

![access-log webserver1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/access%20logwebserver%2001%20log.png)
![access-log webserver2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/access%20log%20webserver%202.png)
![access-log webserver3](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/access%20log%20webserver%203.png)


###  Step 7. [Optional] Configure Local DNS names resolution
The local DNS name of our webservers can be configured in the `/etc/hosts` file of the loadbalancer server. This is an internal configuration that is local to our load balancer server and is used for testing purposes.

Open the file as follows:

```sh
sudo vi /etc/hosts
```

Add the following lines to resolve the IP address of our `webserver1`, `webserver2` and `webserver3` into `web01`, `web02` and `web03` respectively. `184.72.181.7`, `3.81.71.198` and `18.209.111.102`

```sh
[Web1 Public IP] web01
[Web2 Public IP] web02
[Web1 Public IP] web03
```
```
184.72.181.7 web01
3.81.71.198 web02
18.209.111.102 web03
```


The load balancer config files can be updated with the new names instead of IP addresses as shown:


![resolve locally](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/resolve%20locally.png)

When we curl the addresses locally from the load balancer server, they are accessible as shown in the images:

![curl http web01](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/curl%20http%20web01.png)

&nbsp;
![curl http web02](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/curl%20http%20web02.png)

&nbsp;
![curl http web03](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/images/curl%20http%20web03.png)

## Conclusion
We have successfuly configured an Apache loadbalancer to manage web traffic to our webservers. This setup enhances performance, reliability, and scalability in the three-tier architecture.
