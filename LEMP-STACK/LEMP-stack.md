# LEMP STACK ON AWS
![Lemp](https://raw.githubusercontent.com/laraadeboye/Steghub-Devops-Cloud-Engineer/refs/heads/main/LAMP-STACK/images/LAMP-img.webp)
## Table of Content
1. [Project Overview](#project-overview)
2. [Steps](#steps)
    * [Step 0 Prepare Prerequisites](#step-0-prepare-prerequisites)
    * [Step 1 Install Nginx web server](#step-1-install-nginx-web-server)
    * [Step 2 Install MySQL](#step-2-install-mysql)
    * [Step 3 Install PHP](#step-3-install-php)
    * [Step 4 Configure Nginx to use PHP processor](#step-4-configure-nginx-to-use-php-processor)
    * [Step 5 Test server block with html](#step-5-test-server-block-with-html)
    * [Step 6 Test server block with php](#step-6-test-server-block-with-php)
    * [Step 7 Retrieve data from the MySQl database with PHP](#step-7-retrieve-data-from-the-mysql-database-with-php)
3. [Conclusion](#conclusion)

## Project Overview
The LEMP stack is a widely used software stack for serving web applications and dynamic web pages. LEMP stands for:

- Linux: The foundational operating system, known for its robustness and security.
- Engine-X (Nginx): The high-performance web server that handles incoming requests and serves static content, acting as a reverse proxy and load balancer.
- MySQL: A reliable relational database management system that stores application data in structured tables.
- PHP: A server-side scripting language used for web development, enabling dynamic content through database interactions.

**How LEMP Works**

Nginx receives HTTP requests from clients. For dynamic pages, it forwards requests to PHP, which processes them, interacts with MySQL for data retrieval or storage, and sends results back to Nginx, which then responds to the client.

In this project, i will provision the AWS EC2 instance from the commandline. The required prerequisite for this is configuration of the AWS CLI.

**Prerequisites**
- AWS Account
- Ubuntu Linux
- AWS cli

## Steps

## Step 0 Prepare Prerequisites
1. Install the AWS CLI. Follow this [guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to install the AWS CLI on your local machine.

2. Configure AWS CLI: Run the following to configure your AWS credentials:

```sh
aws configure
```
You will be required to enter your AWS Access Key ID, Secret Access Key, Region and Output format.

Run : `aws configure list` to verify the configuration.

![Aws configure list](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/aws_configure_list.png)

3. Choose an AMI: You can visit the console to choose an appropriate image or run the following command:

```sh
aws ec2 describe-images --owners amazon
```

4 Create a key pair (if required)

Create a key pair with the following command:
```sh
aws ec2 create-key-pair --key-name lempKey --query 'KeyMaterial' --output text > lempKey.pem
```
This command shows no output. The file is created in the current working directory and can be viewed with the `ls` command

![Create lempkey](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/Create-lempKey.png)

When you check the content, it should be similar to the image below:

![cat lempKey](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/cat%20lempKey.png)

Set the appropriate permission:

```sh
chmod 400 lempKey.pem
```
5. Security group: If not already created, create security group with SSH and http/https access.

Run the command:

```sh
aws ec2 create-security-group --group-name <MySecurityGroup> --description "Security group to allow ssh access"
```
This command will show the `GroupId` which be used in the next step.

![groupid-securitygrp](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/groupid-securitygrp.png)

Run the following command to authorize ssh Access

```sh
aws ec2 authorize-security-group-ingress --group-id <GroupId> --protocol tcp --port 22 --cidr <Your-Ip/32>

```

![port 22 access](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/port%2022%20access.png)

Run the following to authorize http and https access:
- **http**

```sh
aws ec2 authorize-security-group-ingress --group-id <GroupId> --protocol tcp --port 80 --cidr 0.0.0.0/0

```
![port 80 access any](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/port%2080%20access%20any.png)

- **https**

```sh
aws ec2 authorize-security-group-ingress --group-id <GroupId> --protocol tcp --port 443 --cidr 0.0.0.0/0

```
![port 443 access any](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/port%20443%20access%20any.png)

Verify that the rules were added correctly:

```sh
aws ec2 describe-security-groups --group-ids <GroupId>

```
![image: all security grp](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/all%20security%20grp.png)


6. Launch an ec2 instance: Run the command below to launch an instance

```sh
aws ec2 run-instances --image-id <ami-id> --count 1 --instance-type <instance-type> --key-name <key-pair> --security-group-ids <security-group-id>
```
Replace <ami-id>, <instance-type>, <key-pair>, <security-group-id> as appropriate

![Succesfully created instance](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/successfully%20created%20instance.png)

On the console:

![created instance on console](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/Successful%20creation%20on%20the%20console.png)

Note that to create the instance with a name, include a name tag as follows:

```sh
aws ec2 run-instances --image-id <ami-id> --count 1 --instance-type <instance-type> --key-name <key-pair> --security-group-ids <security-group-id> --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=lempserver}]'
```

7. ssh into the server. Ensure you are in the directory where your private key is and run the following command. Otherwise, use the full path of the key.

```sh
ssh -i lempKey.pem ubuntu@54.164.242.184
```
![SSh with Lemp Key](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/ssh%20with%20lempKey.png)

## Step 1 Install Nginx web server
1. Update apt packages and Install Nginx on the server

```sh
sudo apt update -y
sudo apt install nginx -y
```

2 Verify the installation of Nginx and whether it is running as a service .

```sh
sudo systemctl status nginx
```

![Nginx running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/nginx%20running.png)

3. Verify via curl on the terminal or on the web browser

**Curl**
```sh
curl http://localhost:80
```
![nginx on curl](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/nginx%20on%20curl.png)

**web browser**
Retrieve the public Ip address with the following command:

```sh
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4

```
View on browser:
```sh
http://[Ubuntu-webserver-IP]
```

![nginx on browse](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/nginx%20on%20browse.png)

## Step 2 Install MySQL
1. Mysql is a popular relational database that we can use in this project. We will install it with apt.

```sh
sudo apt install mysql-server -y
```
Verify with:
```sh
sudo systemctl status mysql
``` 

![Systemctl mysql](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/systemctl%20mysql.png)

2. Login to the mysql console:

```sh
sudo mysql
```

3. We will set a password for the root user with the following command:

```sh
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Passw0rd321@'
```
It is important to use a strong password. We used `Passw0rd321@` for simplicity. 

Exit the mysql shell with the command `exit`

4. We will run  asecurity script that comes preinstalled with Mysql to remove some insecure default settings and lock down the database system. Start the script by running:

```sh
sudo mysql_secure_installation
```
![secure mysql](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/secure-mysql.png)

4. Test login to mysql
```sh
sudo mysql -p
```

Exit

We will be asked to configure the VALIDATE PASSWORD PLUGIN.

![Secure MySQL cont](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/contine%20secure-mysql.png)

## Step 3 Install PHP

While Apache embeds the PHP interpreter in each request, Nginx requires an external program to handle PHP processing. Two packages are needed:

```sh
sudo apt install php-fpm php-mysql

```
fpm stands form FastCGI process manager

Verify:
```sh
ls /var/run/php/

```

```sh
sudo systemctl status php8.3-fpm #Replace with the appropriate version
```
![php running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/Php%20running.png)

## Step 4 Configure Nginx to use PHP processor

1. We will set up server blocks in nginx (which is similar to virtual host in Apache) to contain the configuration details. Our domain name will be project_lemp. The default server block in nginx is found at `var/www/html`. We will create another directory under `var/www/ to serve our domain:

First create a system user with no acces to login for improved security:

```sh
sudo useradd -rs /usr/sbin/nologin project_lemp
```

Then create the root directory 
```sh
sudo mkdir /var/www/project_lemp
```

This command produces no output if successful.

2. Assign ownership of the directory 
The current owner is root as seen in the image

![Current owner root](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/Root%20owner%20lemp%20dir.png)

```sh
sudo chown -R project_lemp:project_lemp /var/www/project_lemp
```

3. Open a new configuration file in the nginx sites-available directory

```sh
sudo nano /etc/nginx/sites-available/project_lemp
```

Enter the following configuration:

```sh
server {
    listen 80;
    server_name project_lemp www.project_lemp;
    root /var/www/project_lemp;  # Path to your project's root directory
    index index.html index.htm index.php;

    # Access and error logs
    access_log /var/log/nginx/project_lemp.access.log;
    error_log /var/log/nginx/project_lemp.error.log;

    # Handling static files
    location / {
        try_files $uri $uri/ =404;
    }

    # PHP-FPM Configuration
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;  # Update to the PHP version>
        
    }

    # Deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
}
```
- The breakdown of the server block is as follows:

    1. Server Configuration
       - listen 80;: Listens on port 80 (default HTTP port).
       - server_name project_lemp www.project_lemp;: Specifies the server name (domain or subdomain).
       - root /var/www/project_lemp;: Sets the document root directory for the project.

    2. Index Files
       - index index.html index.htm index.php;: Defines the index files to serve when a directory is requested.

    3. Logging
       - access_log /var/log/nginx/project_lemp.access.log;: Logs access requests.
       - error_log /var/log/nginx/project_lemp.error.log;: Logs errors.

    4. Static File Handling
       - location / { try_files $uri $uri/ =404; }: Attempts to serve files from the requested URI; if not found, returns a 404 error.

    5. PHP Configuration
       - location ~ \.php$ { ... }: Handles PHP files using PHP-FPM (FastCGI Process Manager).
include snippets/fastcgi-php.conf;: Includes PHP configuration settings.
       - fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;: Forwards PHP requests to PHP-FPM via a Unix socket (update the PHP version as needed).

    6. Security
      - location ~ /\.ht { deny all; }: Denies access to files starting with .ht (e.g., .htaccess).


Next activate the configuration by creating a link to the config file form nginx sites-enabled directory:

```sh
sudo ln -s /etc/nginx/sites-available/project_lemp /etc/nginx/sites-enabled/
```

Test the configuration by running:
```sh
sudo nginx -t
```
The configuration is ok if it shows an image similar to the one below:

![image nginx -t 1](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/nginx%20-t%201.png)


Also, disable the default nginx host configured on port 80:

```sh
sudo unlink /etc/nginx/sites-enabled/default
```

Reload nginx to apply the changes:

```sh
sudo systemctl reload nginx
```
## Step 5 Test server block with html
We will create a test `index.html` file using aws instance metadata to confirm that our server block is working as expected:

1. Create an `index.html` in /var/www/project_lemp with the following command and assign the correct permissions:

```sh
sudo touch /var/www/project_lemp/index.html;sudo chown -R project_lemp:project_lemp /var/www/project_lemp/index.html
```

Then write the following content:
```
sudo bash c 'echo 'HELLO LEMP from hostname' $(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-hostname) 'with public IP' $(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4) > /var/www/project_lemp/index.html'

```

Set the correct permissions for the file:

```
sudo chmod 644 /var/www/project_lemp/index.html
```
![metadata on index.html](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/metadata%20on%20index.html.png)

Here is the image of the metadata info of our server on browser:

![Hello lemp](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/HEllo%20lemp.png)

***Note: There is a  difference in IP. I had to unavoidably pause the configurations. Being that I am using a cloud IDE-gitpod, the workspace and hence, the EC2 instance had to be recreated***

## Step 6 Test server block with php

1. Create a file named `info.php` in `/var/www/project_lemp/`. 

```sh
sudo nano /var/www/project_lemp/info.php
```

paste the following script:

```sh
<?php
phpinfo();
?>
```

Assign the right ownership and  permissions.
```sh
sudo chown project_lemp:project_lemp /var/www/project_lemp/info.php
sudo chmod 644 /var/www/project_lemp/info.php
```


2. Visit the browser with the IP of the server referencing the `info.php` file.

```sh
http://[Public-ip]/info.php
```
This shows sensitive details about the php environment and ubuntu server as shown below:

![php info page](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/php%20info%20page.png)

Remove the file or edit the script to contain:

```sh
<?php
echo "PHP is working";
?>
```

![php is working](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/php%20is%20working.png)

## Step 7 Retrieve data from the MySQl database with PHP
We will:
- Create a test database with a simple 'To-do list'
- Configure Access to the database so that nginx will query data form the db and display it.

We will create a new user with `caching_sha2_password` authentication method which is the default authentication introduced in MySql 8.0. Modern versions of PHP e.g PHP 7.4 and above having the associated MySQL extensions support it.

To confirm this, we will visit the php info page (Use the php info script we used previously and view it on the browser) and look for the MySQL native driver (`mysqlnd`) as shown:

![mysqlnd](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/mysqlind.png)

Alternatively, you can verify the availability of the necessary driver by checking the version of php you are using and the modules installed:

Check php version
```
php -v  
```

Check php modules
```sh
php -m
```

![php version and modules](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/php%20version%20and%20php%20mod.png)

1. Connect to the MySQL console with root:
```sh
sudo mysql -p
```

2. Create the database named `example_database`:

```sh
CREATE DATABASE `example_database`;
```
![create database](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/Create%20database.png)

3. Create the user named `example_user` using `caching_sha2_password` as the default authentication method with the  password as`Passw0rd123@`

```sh
CREATE USER 'example_user'@'%' IDENTIFIED WITH caching_sha2_password BY 'Passw0rd123@';
```

![create example user](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/create%20eample%20user.png)

Using the wildcard '%' means that the user can connect form any host machine and he is not retricted to logging in from the host machine lie the root user.

4. We will give the user permission over the `example_database`:

```sh
GRANT ALL PRIVILEGES ON example_database. * TO 'example_user'@'%';
```
*(Note the period in front of the database)*

This command grants this user `example_user` full access to only the `example_user` database. He doesn't have access to any other databases on the server.


Exit the MySQL console:
```sh
exit
```

5. Test that the new user is properly authenticated by logging in again:

```sh
mysql -u example_user -p
```

Note:
In older legacy applications using old versions of php you cn use the `mysql_native_password` method of authentication.


6. View the database and create the `todo_list` table:
   
1. View database with the following command:
```sh
SHOW DATABASES;

```
![show databases](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/Show%20databases.png)

2. Select the database:

```sh
USE example_database;
```
![Use database](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/use%20database.png)

2. Create a table with the following command:

```sh
CREATE TABLE todo_list (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    task VARCHAR (255) NOT NULL,
    status ENUM('pending', 'completed') DEFAULT 'pending'    
);
```

3. Insert a few rows of content to the table
```sh
INSERT INTO todo_list (task, status) VALUES
('Buy groceries', 'pending'),
('Walk the dog', 'pending'),
('Finish the report', 'pending'),
('Read a book', 'pending'),
('Prepare dinner', 'pending'); 
```

4. Confirm the data you entered by running:

```sh
SELECT * FROM todo_list;
```

![Select from table](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/select%20from%20table.png)

Exit the MySQL console.

5. Create a PHP script that will connect to MySQL and query the content:

First create th PHP file:

```sh
vi /var/www/project_lemp/todo_list.php
```
Enter the following script that connects to the MySQL database and queries the content of the todo_list. It also displays the results in a list. If there is a problem with the database connection , it will throw an exception.

```
<?php
// Database configuration
$host = 'localhost'; // Change if necessary
$database = 'example_database';
$user = 'example_user';
$password = 'Passw0rd123@'; // Replace with your actual password
$table = "todo_list";

try {
    // Establish database connection
    $db = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    
    // Set PDO to throw exceptions on error
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Prepare and execute the query
    $query = "SELECT item_id, task, status FROM $table";
    $stmt = $db->query($query);
    $todos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Display results
    if ($todos) {
        echo "<h1>To-Do List</h1>";
        echo "<ul>";
        foreach ($todos as $todo) {
            echo "<li>ID: {$todo['item_id']}, Task: {$todo['task']}, Status: {$todo['status']}</li>";
        }
        echo "</ul>";
    } else {
        echo "No tasks found in the to-do list.";
    }
} catch (PDOException $e) {
    // Handle connection errors
    echo "Database connection failed: " . $e->getMessage();
}
?>
```
- **The functionality of the script**

This PHP script connects to a MySQL database, retrieves data from a "todo_list" table, and displays the tasks in an unordered list.

- **Functionality Breakdown:**

    1. Database Configuration: The script defines database connection parameters (host, database name, username, password, and table name).

    2. Database Connection: It establishes a connection to the database using PDO (PHP Data Objects) and sets the error mode to throw exceptions.
  
    3. Query Execution: The script executes a SELECT query to retrieve all tasks from the "todo_list" table.
  
    4. Data Retrieval: It fetches all query results as an associative array.
  
    5. Displaying Results: If tasks exist, it displays them in an unordered list with task ID, description, and status. Otherwise, it shows a "No tasks found" message.

    6. Error Handling: The script catches and displays any PDO exceptions that occur during database connection or query execution.


6. Visit the browser and you will see an image similar to the one below:

```sh
http://[Public-ip]/todo_list.php
```
![todo_list on browser](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LEMP-STACK/images/to%20do%20list%20on%20browser.png)

## Conclusion
In this project, we successfully deployed a LEMP stack on AWS, providing a robust and efficient environment for serving web applications. By implementing a test database and creating a dynamic PHP script, we demonstrated how to interact with the database, showcasing the full capabilities of the LEMP stack. This hands-on experience solidified our understanding of server configurations and database management in a cloud environment.
