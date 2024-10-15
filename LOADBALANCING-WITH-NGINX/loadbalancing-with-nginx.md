# Project Title

![Architecture diagram](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/3-tier%20web%20application%20with%20database%20and%20NFS%20server.drawio%20(1).png)

We have previously configured a load balancer to manage traffic to each of the web servers using [Apache Load Balancer](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/loadbalancing-with-apache.md). We will also configure an alternative Load balancer solution with  NGINX Load Balancer. As a Devops engineer, it is important to be well versed with different tools for doing the same job.

We will configure the NGINX Load Balancer on a new server.

## Prerequisites
- Basic AWS knowledge
- Three-tier Web application running

## Steps
## Step 0 Launch an EC2 instance
- Launch a **t2.micro** sized ubuntu instance 24.04 LTS on AWS named `nginx-lb` with the security group `lb-sg` that we created. The load balancer allows inbound access on port `80` and port `443` from everywhere `0.0.0.0/0` on the internet. It  also allows SSH access on port `22` to access the server for configurations.


![lb-sg](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/lb-sg.png)

A larger instance may be needed in production settings for a load balancer. Reasons why you may want to increase instance size can be found in my [write-up](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/self-side-study/loadbalancing-concepts.md) on the subject.

![nginx-lb running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/nginx-lb%20running.png)

Ensure all the webserver instances, DB-server instance and NFS server instance are running.

- Connect to the `nginx-lb` EC2 instance via SSH. Update the `/etc/hosts` file for local DNS and their local IP addresses. 

Open the file:
```sh
sudo vi /etc/hosts
```

Add the following lines to resolve the IP address of our `webserver1`, `webserver2` and `webserver3` into `web01`, `web02` and `web03` respectively. `34.228.229.126`, `75.101.224.104` and `35.175.252.1`

```sh
[Web2 Public IP] web01
[Web2 Public IP] web02
[Web1 Public IP] web03
```

```sh
34.228.229.126 web01
75.101.224.104 web02
35.175.252.1 web03
```

![nginx-lb etc host file](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/nginx-lb%20etc%20host%20file.png)

## Step 1 Install nginx

- Install nginx on the server as follows:

```sh
# Update apt repository

sudo apt update -y && sudo apt upgrade -y

# Install nginx
sudo apt install nginx -y

# Check that nginx is running 
sudo systemctl status nginx
```
![nginx running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/nginx%20running.png)

When accessed through the public IP:

![nginx web server running 2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/nginx%20web%20server%20running%202.png)

## Step 1 Configure nginx as a load balancer.

Nginx uses the `/etc/nginx/conf.d/` directory for including additional configuration files. This is a convention adopted by Nginx to keep the main configuration file (`nginx.conf`) clean and modular.

We will create a new configuration file in the `conf.d` directory named `webserver-lb.conf` 

```sh
sudo vi /etc/nginx/conf.d/webserver-lb.conf
```

We will configure `nginx-lb` using the web servers names defined in the `etc/hosts` file.

Add the following to the configuration file:

```sh
# Define the group of application servers
upstream app_servers {
    server web01 weight=5;
    server web02 weight=5;
    server web03 weight=5;
}

server {
    listen 80;
    server_name example.com; # Replace this with the public IP or domain name of the server

    location / {
        proxy_pass http://app_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
![first nginx config](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/nginx%20first%20config.png)

If we check the public IP of nginx with the above configuration, we will still see the nginx default page. Hence, we must replace the example.com with the public IP of nginx.

![nginx config with IP](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/nginx%20config%20with%20nginx%20IP.png)

The `weight=5` parameter is used for weighted round-robin load balancing. Since all servers have the same weight, the traffic will be distributed equally among them.


Restart Nginx and make sure the service is up and running

```sh
sudo systemctl restart nginx
sudo systemctl status nginx
```

## Step 2 Register a new domain name and configure secured connection using SSL/ TLS certificates

We will make the necessary configurations to make connection to the web application secured.

- To get a valid SSL certificate, you should register a new domain name. I have a free registered subdomain from [AfraidDns](https://freedns.afraid.org/) for test purposes - `laraadeboye.mooo.com`

We will allocate an elastic IP to our EC2 (`nginx-lb`) instance 
to preserve the IP and prevent it from changing after each reboot.

To allocate an elastic IP to the EC2 instance,
  - Navigate to the EC2 Dashboard
  - In the console, find and click on **EC2** under the "Services" menu.

  - In the left navigation pane, click on **Elastic IPs**.
  - Click on the **Allocate Elastic IP address** button.
  
    ```plaintext
    Actions > Allocate Elastic IP address
    ```
  - Choose VPC or EC2 from the drop-down list based on where your  instance is located.
  - Click Allocate to confirm your choice.

    ```plaintext
    Actions > Associate Elastic IP address
    ```
  - In the association dialog:
    - For Resource type, select Instance.
    - From the Instance drop-down, choose your desired EC2 instance which is our `nginx-lb`
    - Optionally, select a specific Private IP address if your  instance has multiple private IPs.
    - Click on Associate to complete the process.

  - Verify the Association
    - Go back to the Instances section in the EC2 Dashboard.
    - Select your EC2 instance and check its details at the bottom of the page. 
    - You should see the associated Elastic IP listed under Public IPv4 address.

![elastic IP assigned](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/elastic%20IP%20assigned.png)
&nbsp;
![Elastic IP associated](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/elastic%20IP%20associated.png)

- Update the A record in your registrar to point to `nginx-lb` Elastic IP address. Verify that the web servers can be reached from the address using the HTTP protocol

![updating registrar](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/Updating%20registrar.png)

Update your `webserverlb.conf` file with the new domain name which in my case is `laraadeboye.mooo.com`. Remember to restart nginx for the changes to reflect. If you only update the records in your registrar without editting the configuration file, you will see the nginx default page when you attempt to view the domain name from the browser

**Nginx default page when the configuration file is not updated**
![view without edditting conf](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/view%20without%20edditting%20conf.png)

![update conf file with domain name](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/update%20conf%20file%20with%20domain%20name.png)

Now we can view the application from our domain name:

![now we can view the application from our domain](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/now%20we%20can%20view%20the%20application%20from%20our%20domain.png)

We can also login to our application with the username and password:

![logged in success](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/logged%20in%20successfuly.png)

- Next, we will install certbot and request for an SSL/TLS certificate

```sh
sudo apt-get update

# Ensure snapd service is active and running
sudo systemctl status snapd


# Install certbot, follow the prompt 
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx 
```

This command `sudo certbot --nginx` will look for your domain name in nginx configuration files including those in `conf.d` files

![certbox finds the name](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/certbox%20finds%20the%20name.png)

Now we can access our web application on the secured HTTPS protocol.
![Certificate deployed](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/certificate%20deployed.png)


- Test secured access to your web application using the HTTPS protocol.

![View HTTPS website](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/view%20https%20website.png)

Click on the padlock icon. You will see details of the certificate issued for the website.

![padlock icon](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/padlock%20icon.png)

Set up periodical renewal of your SSL/TLS certificate. It is recommended to renew certificate frequently , every 60 days or less because LetsEncrypt is valid for 90days

Test the renewal command in `dry-run` mode:

```sh
sudo certbot renew --dry-run
```
![renew dry run](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/renew%20dry%20run.png)

It is best practice to schedule a cron job on the server that renews the certificate periodically:
We can set a cron job as shown:

Edit the crontab file:

```sh
crontab -e
```

Assuming we want to schedule the cron job for certbot to run on the first day of every month. Add the following to the end of the crontab file:

```sh

0 0 1 * *  root /usr/bin/certbot renew > /dev/null 2>&1
```
![crontab renew](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-NGINX/images/renew%20crontab.png)

## Conclusion

We implemented an Nginx Load Balancer for our three-tier web application with secured HTTPS connection with periodically updated SSL/TLS certificates.
