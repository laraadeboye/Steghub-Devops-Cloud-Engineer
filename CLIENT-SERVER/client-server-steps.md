
# CLIENT-SERVER ACHITECTURE WITH MYSQL

## Overview:
In a client-server architecture, the client requests data or services, and the server responds with the requested information. For a MySQL-based architecture, the client would communicate with a MySQL server, where the database operations such as queries, inserts, updates, and deletions occur.

**Architecture Components:**
- Client:
Could be a web app (browser), desktop app, mobile app, or backend API.
Sends requests (e.g., HTTP or direct DB queries) to the server for data.

- Server:
Contains the business logic (usually a backend server, such as Node.js, FastAPI, or a PHP server).
Interacts with the MySQL database to retrieve or modify data.
Sends the response back to the client.

- MySQL Database:
Stores the data.
Responds to queries from the server to fetch or update data.


To demostrate the client server architecture, we will follow the following steps:

## Steps

## Step 1 Create and configure two Linux-based virtual servers 

- We will launch two ubuntu instances on AWS named `mysql-server` and `mysql-client`

[image 2-ubuntu-instances]

Note the public-IP of the `mysql-client` server

In this case, mine is `

[image  mysql-client-public-ip]

- Open security groups ports on `3306`, the default mySQL port on `mysql-server` from the specific IP of the `mysql-client`

[image 3306 and 22 open on mysql-server from mysql-client]

The only ports open on our `mysql-server` are `3306` for database access `22` for server configurations.

- We will open SSH, HTTP, and HTTPs access on the `mysql-client` server so that we can access it from our local system and from anywhere. Also, to simulate real time client.

[image mysql-client-SG]

A and B are specific IP ranges for EC2-instance-connect and my local IP range respectively.

SSH into both servers. I will be using the EC2 instance connect. You can also access the server from your local system via SSH.
[image ssh into mysql-client with instance connect]

[image ssh into mysql-server with instance connect]


## Step 2 Install MySQL-server and Configure mysql-server to allow connections form remote hosts.


- Install MYSQL server software on `mysql-server`

```sh
# Update apt repo
sudo apt update -y

# install mysql-server
sudo apt install mysql-server -y

# Verify and enable mysql
sudo systemctl status mysql

sudo systemctl enable mysql

sudo systemctl restart mysql

# login to the mysql console
sudo mysql

```
[image mysql-server installed on mysql-server]

Set the root user password:
```
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Passw0rd123#';
```
We are using the above password for demonstration purpose. In production, a more secure password should be set.

Exit the mysql shell:
```sh
exit
```
- Secure mysql installation, following the prompts:

```sh
sudo mysql_secure_installation
```

- Configure remote access.
Edit the `mysqld.cnf` file, replacing the **bind-address** port on localhost `127.0.0.1` with `0.0.0.0` .

Look for the line that starts with **bind-address**. This defines which IP addresses MySQL will listen to. By default, it's set to `127.0.0.1` (localhost), which means only local connections are allowed.

Change this line to `0.0.0.0 ` to allow MySQL to listen on all network interfaces, or you can specify a specific IP address for better security.


```
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf
```
[Configure remote access everywhere]

Save and exit the file.


## Step 3 Install MySQL-client on mysql-client server.
The MySQL client is a command-line tool that allows you to connect to and interact with MySQL databases, whereas the MySQL server is the actual database engine that stores and manages data.

- Navigate to the `mysql-client` server.

- Install mysql-client:

```sh
# Update apt repository
sudo apt update -y

# Install mysql-client
sudo apt install mysql-client -y
```

## Step 4 Connect to `mysql-server` via `mysql-client` Linux server.


From the `mysql-client` Linux server, connect remotely to `mysql-server` database engine without `SSH`. To do this we will need to use the `mysql` utility.

First create a remote user named `remote_user` on `mysql-server`:

- Login to MySQL database on the `mysql-server` with the root user. 

```sh
sudo mysql -u root -p
```

[Login to mysql-server with root]

- Create a new user named `remote-user` and grant all privileges to the user:

```sql
CREATE USER 'remote_user'@'%' IDENTIFIED BY 'Passw0rd321#';
```

```sql
GRANT ALL PRIVILEGES ON *.* TO 'remote_user'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
```
Exit the mysql console.
```
exit
```

[image create remote user]


'%' allows you to connect from any IP. It can be replaced with a specific IP for improved security.

Restart mysql.

```sh
sudo systemctl restart mysql
```

Remember we have opened our security group inbound rule on `3306`. It should be done at this point, if not done already.

We must also open the ubuntu UFW (uncomplicated Firewall) on port `3306`:
First verify that ufw is set to inactive. If it is, skip this step.

```sh
sudo ufw allow 3306/tcp
```

Verify the firewall rule:

```sh
sudo ufw status
```

Finally, connect remotely using the mysql client from the `mysql-client` server:

```sh
mysql -h [mysql-server-ip] -u [username] -p
```

for instance, `3.82.5.9` is the mysql-server public -IP

```sh
mysql -h 3.82.5.9 -u remote_user -p 

# You will be prompted to enter the password for remote user which in our case is `Passw0rd321#`
```
[image successful login to mysql server from client]

- Run some database commands from `mysql-client` server to verify remote access:

```sql
/*show databases*/

SHOW databases;

```
[image; show databases]
```sql

/* Create database, create table */

CREATE DATABASE demo_db;

USE demo_db;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100),
  age INT
);

INSERT INTO users (name, email, age) VALUES
('Alice', 'alice@example.com', 25),
('Bob', 'bob@example.com', 30),
('Charlie', 'charlie@example.com', 35);

```

Show tables:

```
SHOW TABLES;

```

[show tables]

Note that we are performing this actions from the mysql-client server.



## Conclusion

We have successfully demonstrated a client-server  architecture.    



