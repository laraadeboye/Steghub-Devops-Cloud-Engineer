
# NGINX AS A REVERSE PROXY aND OPTIONAL CONFIGURATION SETTINGS

An nginx reverse proxy serves as an intermediary between a client external server and an internal server. It takes a client request and passes it to one or more servers and returns the server's response back to the client. Nginx is an open source software that provides several capabilities such as TLS/SSL, load balancing, logging and acceleration that most applications lack. By using Nginx as a reverse proxy, applications can benefit from the advance capabilities of Nginx.

## Set up nginx as a reverse proxy for jenkins-ansible server

1. Update apt repo and install nginx:

   ```sh
   sudo apt update
   sudo apt install nginx -y
   ```
2. Create a file in the conf.d folder named jenkins.conf and enter the following configuration:

```sh
# Jenkins Reverse Proxy Configuration
# Place this in /etc/nginx/conf.d/jenkins.conf or within server block in nginx.conf

upstream jenkins {
    server 127.0.0.1:8080;    # Jenkins runs on port 8080 by default
    keepalive 32;             # Keep alive connections
}

server {
    listen 80;                # Listen on port 80
    server_name jenkins.yourdomain.com;    # Replace with your domain

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name jenkins.yourdomain.com;    # Replace with your domain


    # Security headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Logging
    access_log  /var/log/nginx/jenkins.access.log;
    error_log   /var/log/nginx/jenkins.error.log;

    # Proxy settings
    location / {
        proxy_pass          http://jenkins;
        proxy_redirect      off;
        proxy_http_version  1.1;

        # Required headers for Jenkins
        proxy_set_header    Host $host;
        proxy_set_header    X-Real-IP $remote_addr;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_set_header    Connection "upgrade";
        proxy_set_header    Upgrade $http_upgrade;

        # Timeouts
        proxy_connect_timeout       150;
        proxy_send_timeout          100;
        proxy_read_timeout          100;
    }
```
 
 Replace placeholders with the right details.

 You can optionally configer SSL certificates using certbox.


 ## Optional configuration settings

 Security headers: Security Headers
These HTTP headers help protect your applications from various web vulnerabilities:

```sh
# Add these headers in your server block
server {
    # Prevents your site from being embedded in iframes on unauthorized domains
    # Protects against clickjacking attacks
    add_header X-Frame-Options SAMEORIGIN;

    # Prevents browser from MIME-type sniffing
    # Stops browsers from interpreting files as something else than declared by content type
    add_header X-Content-Type-Options nosniff;

    # Enables browser's XSS filtering
    # Helps prevent Cross-Site Scripting (XSS) attacks
    add_header X-XSS-Protection "1; mode=block";

    # Controls how much information the site can gather about its referrers
    add_header Referrer-Policy "strict-origin-origin-when-cross-origin";

    # Implements Content Security Policy (CSP)
    # Controls which resources the browser is allowed to load
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; frame-ancestors 'self'; form-action 'self';";

    # HTTP Strict Transport Security
    # Forces browsers to use HTTPS for a specified time period
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

2. WebSocket Support
WebSocket enables real-time, two-way communication between client and server. It's crucial for features like:


- Jenkins: Real-time build logs and console output
- Artifactory: Real-time upload/download progress
Live updates and notifications

Here's how WebSocket configuration works:

```sh
location / {
    proxy_pass http://backend;
    
    # Required for WebSocket
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    # Example of how WebSocket connection works:
    # 1. Client requests upgrade: 
    #    Upgrade: websocket
    #    Connection: Upgrade
    
    # 2. Server accepts:
    #    HTTP/1.1 101 Switching Protocols
    #    Upgrade: websocket
    #    Connection: Upgrade

    # Prevent timeout during long-running WebSocket connections
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
}

# Specific WebSocket endpoint example (e.g., for Jenkins)
location /jenkins/ws {
    proxy_pass http://jenkins-backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

3. Timeouts
Timeouts are crucial for managing server resources and maintaining stability. Here are the key timeout directives:

```sh
http {
    # How long to wait for the client accept/receive a response
    client_body_timeout 12;
    client_header_timeout 12;

    # How long to keep idle keepalive connections open
    keepalive_timeout 65;

    # How long to wait when sending response to client
    send_timeout 10;

    # Proxy timeouts
    location / {
        # Maximum time to wait for establishing connection with proxied server
        proxy_connect_timeout 60s;

        # Maximum time between two successive read operations from proxied server
        proxy_read_timeout 60s;

        # Maximum time between two successive write operations to proxied server
        proxy_send_timeout 60s;

        # For file uploads - maximum time between two successive write operations
        client_body_timeout 60s;

        # Buffer settings for stability
        proxy_buffer_size 4k;
        proxy_buffers 4 32k;
        proxy_busy_buffers_size 64k;

        # Example timeout scenarios:
        # 1. Large file upload: Increase client_body_timeout
        # 2. Slow API: Increase proxy_read_timeout
        # 3. WebSocket connection: Use higher timeouts
        # 4. Download large artifacts: Increase proxy_read_timeout
    }
}
```


**Sample configuration file**

```sh

# HTTP Block for Redirection
server {
    listen 80;
    server_name ci.infradev.laraadeboye.com;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS Block
server {
    listen 443 ssl;
    server_name ci.infradev.laraadeboye.com;

    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/artifactory.infradev.laraadeboye.com/fullchain.pem; # SAN certificate
    ssl_certificate_key /etc/letsencrypt/live/artifactory.infradev.laraadeboye.com/privkey.pem; # SAN certificate
    include /etc/letsencrypt/options-ssl-nginx.conf; # Recommended by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Proxy settings
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Logging
    access_log  /var/log/nginx/ci.access.log;
    error_log   /var/log/nginx/ci.error.log;

    # Security Headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Optional WebSocket Headers
    proxy_set_header Connection "upgrade";
    proxy_set_header Upgrade $http_upgrade;

    # Timeout Settings
    proxy_connect_timeout       150;
    proxy_send_timeout          100;
    proxy_read_timeout          100;
}

```




