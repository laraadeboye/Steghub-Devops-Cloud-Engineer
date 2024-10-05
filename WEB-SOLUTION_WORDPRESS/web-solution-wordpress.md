
# Storage Infrastructure on Linux server | Basic web solution with wordpress on Redhat Linux

## Project Overview
We will be preparing a storage infrastructure on two linux servers and implementing a basic web solution with WordPress.

We will implement the project in two parts:
1. Configure a storage subsystem for Web and Database servers based on linux OS. Here, I will solidify my practical experience with disks, partitions and volumes in linux.

2. Install Wordpress and connect it to a remote MySQL database server. This will solidify my experience of deploying web and DB tiers of a web solution.


Basically we will implement a 3-tier architecture.

**Three-tier Architecture**
This is a client-server software architecture pattern that comprises of three distinct layers, namely:

- Presentation: User interface e.g client server or laptop browser
- Application: Logic layer e.g webserver
- Data tier: Data storage and data access layer e.g database server such as FTP server or NFS server.


## Project objectives:

- Set up a robust storage subsystem on two Linux servers

- Implement Three-Tier Architecture

- Install and Configure WordPress

-  Conduct thorough testing of the storage infrastructure and WordPress installation to identify any performance bottlenecks or issues.

## Prerequisites

- linux OS on AWS 

- Basic knowledge of AWS

## Steps
## Step 1 Prepare a web server

- Launch an EC2 instance- REDHAT OS named `project-web`

![image: project-web running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/project-web%20running.png)

Ensure that the security group allows internet access on port `80` and `443` from anywhere on the internet.

Note the availability zone and SSH into the instance (or use instance connect)

The availability zone of my instance is `us-east-1c`

## Step 2 Create storage infrastructure for the web server

- Create 3 block volumes (elastic block storage - EBS)in the same availability zone as the web server, 10gb each.

Select the `project-web`

On the side navigation bar, click on volumes and enter the appropriate details based on your specifications. Name the volumes: `project-web-volume1`, `project-web-volume2` and `project-web-volume3` respectively.

![image volumes created](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/Volume%20created%20(2).png)

- Attach each of the block volumes to the AWS instance, `project-web`

![image volumes attached](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/volumes%20attached.png)

Alternatively, (easiest way), Create the volumes by editing the **configure storage** section while launching the instance. The volumes will be automatically attached and created in the same availability zone of the instance:

![configure storage](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/configure%20storage.png)

&nbsp;

![volumes configure storage](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/Volumes%20configure%20storage.png)

It is important to attach the volumes to the instance early on so that the application can have access to it. Also it prevents the complexity of having to disrupt operations if the system is already in production.

- Verify on the terminal that the volume has been attached. Run the following command:

```sh
lsblk
```
Take note of the attached volumes as seen in the image.
![image lsblk](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk.png)

 The image shows that the root filesystem (/) is on xvda1, which  is 8GB in size.

We have three additional 10GB disks: `xvdb`, `xvdc`, and `xvdd`.


- Inspect the dev directory for the newly created block volumes:

```sh
ls /dev/
```

![image inspect dev](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/inspect%20dev.png)

To view all the mounts and free space on the server, run :

```sh
df -h
```
![image df -h not mounted](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/inspect%20dev.png)

The three additional block devices (`xvdb`, `xvdc`, `xvdd`) have not been mounted yet. 

They don't appear in the `df -h` output because they haven't been formatted with a filesystem or mounted.


Partitioning and formatting of disks should be done before mounting.

- We will create  a single partition on each of the 3 block volumes we created.


Creating a partition on the block volume allows the operating system to logically separate and organize the storage. It gives you control over how much space is used by different parts of the server.

Gdisk stands for GPT fdisk.
We will use the `gdisk` utility to create one partition each on the 3 disks:

First verify that the block volumes have been attached using `lsblk` as we have done.

Install gdisk (if not installed) 

```sh
sudo yum install gdisk -y
```

Run gdisk on the first volume `/dev/xvdb`

```sh
sudo gdisk /dev/xvdb
```
You will enter an interactive session to create a partition:

- Command `n`: Create a new partition.

- Accept the default values for partition number, first sector, and last sector (this will use the entire disk).

- For the partition type, choose the default (Linux filesystem, code 8300).

- Command `w`: Write the partition table to the disk and exit.

- Confirm by typing `y` when prompted.

![gdisk xvdb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/gdisk%20xvdb.png)

Verify the new partition by running `lsblk` again.

![lsblk xvdb](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk%20xvdb.png)

The output should show a partition (e.g., `/dev/xvdb1`).

We will partition the remaining two volumes using the gdisk utility:

**`/dev/xvdc`**
![gdisk xvdc](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/gdisk%20xvdc.png)
![lsblk xvdc](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk%20xvdc.png)

&nbsp;

**`/dev/xvdc`**
![gdisk xvdd](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/gdisk%20xvdd.png)
![lsblk xvdd](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk%20xvdd.png)

- Next, we will use `lvm2` package to check for available partitions. Lvm stands for Logical Volume management. It allows for more flexible disk management (beyond `lsblk` and `fdisk -l` utilities), such as resizing volumes on the fly, creating snapshots, and spanning filesystems across multiple disks.

Install `lvm2` with the following command:

```sh
sudo yum install lvm2
```
![install lvm2](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/install%20lvm2.png)

We can run the following command to check for available disk partitions:

```sh
sudo lvmdiskscan
```

![image lvmdiskscan](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lvmdiskscan.png)

Note that there are zero lvm physical volumes

- We will use `pvcreate` to turn the partitions into LVM physical volumes:

```sh
sudo pvcreate /dev/xvdb1
sudo pvcreate /dev/xvdc1
sudo pvcreate /dev/xvdd1
```

![expected output PV](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/expected%20output%20pv.png)

Verify that the physical volume have been created:

```sh
sudo pvs
```

![image: sudo pvs](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/sudo%20pvs.png)

We will use `vgcreate` to group the volumes into a volume group named `webdata-vg`

```sh
sudo vgcreate webdata-vg /dev/xvdb1 /dev/xvdc1 /dev/xvdd1
```


Verify that the volume group has been created by running:

```sh
sudo vgs
```

![sudo vgs](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/sudo%20vgs.png)

We will use `lvcreate` to create logical volumes from the volume group. We will create 2 logical volumes:

- apps-lv : which will store the data for the website. We will use half of the VG size. (about 14G)

- logs-lv : which will store data for the logs. We will use the remaining half


```sh
sudo lvcreate -n apps-lv -L 14G webdata-vg

sudo lvcreate -n logs-lv -L 14G webdata-vg 
```

Verify that the LV has been created:

```sh
sudo lvs
```

![image sudo lvs](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/sudo%20lvs.png)

- We will verify the entire configurations by running:

```sh
# views the complete set up including PVs, VG and LV
sudo vgdisplay -v 

sudo lsblk
```

![sudo vgdisplay01](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/sudo%20vgdisplay01.png)
![sudo vgdisplay02](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/sudo%20vgdisplay02.png)
![sudo vgdisplay03](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/sudo%20vgdisplay03.png)


&nbsp;
[lsblk vgdisplay](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk%20vgdisplay.png)

The apps (14GB) and logs (14GB) logical volumes are larger than the individual disk sizes (10GB each), demonstrating that LVM is being used to combine storage from multiple disks.This configuration is optimized for a web application, with separate volumes for application data and logs, and potential redundancy across physical disks. 


- We will format the logical volumes with a filesystem `ext4`:

```sh
sudo mkfs -t ext4 /dev/webdata-vg/apps-lv

sudo mkfs -t ext4 /dev/webdata-vg/logs-lv
```

![format lvs](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/format%20lvs.png)

- Create the `/var/www/html` directory to store the website files:

```sh
sudo mkdir -p /var/www/html
```

- Mount the `/var/www/html` on the `apps-lv`

```sh
sudo mount /dev/webdata-vg/apps-lv /var/www/html/
```

- Before mounting the file system for the logs, we must backup all the files in the log directory `/var/log` into `/home/recovery/logs` with `rsync`. The `rsync` command-line tool is the most preferred backup tool in Linux systems. It allows you to make incremental backups including the entire directory tree, both locally and on a remote server.

First, create the `/home/recovery/logs` to store the backup of the log data:

```sh
sudo mkdir -p /home/recovery/logs 
```
This is necessary because when mounting, all the existing data on `/var/log` will be deleted

![content of var log](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/content%20of%20var%20log.png)

```sh 
sudo rsync -av /var/log/ /home/recovery/logs
```

[rsync -av](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/rsync%20-av.png)

The '-a' and '-v' flags in the command stands for archive mode and verbose respectively.

then, mount `/var/log` on `logs-lv`

```sh
sudo mount /dev/webdata-vg/logs-lv /var/log
```

We can now restore the backed-up logs into the /var/log directory with `rsync`

```sh
sudo rsync -av /home/recovery/logs /var/log
```

- We will make the mounts persistent by editing the `/etc/fstab`:


Obtain the UUID of the device. Run:

```sh
sudo blkid
```
Note the UUID for the next Step

Open the `/etc/fstab`

```
sudo vi /etc/fstab
```

Update it in the following format:

```sh
# mounts for wordpress webserver
UUID=<value> /var/www/html ext4 defaults 0 0

UUID=<value> /var/log ext4 defaults 0 0
```

e.g
```sh
# mounts for wordpress webserver
UUID=4bb84a45-74a5-4b5e-b289-9d17c9103275 /var/www/html ext4 defaults 0 0

UUID=0088a2b7-03d8-4429-8b12-c7632f3d6dcd /var/log ext4 defaults 0 0
```
[edit fstab webserver](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/edit%20fstab%20webserver.png)

- Test the configurations and reload the daemon:

```sh
sudo mount -a #  linux command that mounts all filesystems specified in the /etc/fstab file.

sudo systemctl daemon-reload
```

- Verify your setup by running `df -h` 

![df -h fstab](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/df%20-h%20fstab.png)

## Step 3 Prepare the Database Server.

- Launch an EC2 instance- Amazon Linux 2 named `project-db`. Follow the steps as for the first server.
![project-db running](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/project-db%20running.png)

Note that the security group does allows inbound access on port 3306 on `project-web` private IP (gor security reasons)

It also allows inbound access on port 22 from instance connect public IP range.`18.206.107.24/29` and my local system for configuring the DB server.

## Step 4 Prepare the storage infrastructure for the Database server.

We repeat the same steps as for the webserver. But the logical volume should be named `db-lv` and mounted unto the `/db `directory not `/var/www/html`



- **Attached volumes for db server on console**

![Attached volumes db-server](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/attached%20volumes%20dbserver.png)

![lsblk-db volumes](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk-db%20volumes.png)

- **Partitioned db volumes using gdisk utility**
![partitioned db volumes](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/partitioned%20db%20volumes.png)

- **Lvm2 utility**
![lvmdiskscan.pvcreate.vgcreate](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lvmdiskscan.pvcreate.vgcreate.png)


We use `lvcreate` to create logical volumes from the volume group `webdata-vg`. We will create 2 logical volumes:

- db-lv : which will store the data for the database. We will use half of the VG size. (about 14G)

- logs-lv : which will store data for the logs. We will use the remaining half

![lsblk db-lv](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/lsblk%20db-lv.png)

- **Format logical volumes:**

![format lvs db](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/format%20lvs%20db.png)

- Create the directory for db files

```sh
mkdir db/
```

- Mount db/ folder on the logical volume:

```sh
sudo mount /dev/webdata-vg/db-lv /db
```

- Just like we did previously,  we must backup all the files in the log directory `/var/log` into `/home/recovery/logs` with `rsync` before we mount.

Create the `/home/recovery/logs` to store the backup of the log data:

```sh
sudo mkdir -p /home/recovery/logs 
```
This is necessary because when mounting, all the existing data on `/var/log` will be deleted

```sh 
sudo rsync -av /var/log/ /home/recovery/logs
```

- Mount log files
```sh
sudo mount /dev/webdata-vg/logs-lv /var/log
```

Restore the logfiles back with `rsync`:

```sh
sudo rsync -av /home/recovery/logs /var/log/
```
- Ensure to persist the mount in the `/etc/fstab` file
![df -h fstab db](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/df%20-h%20fstab%20db.png)

## Step 5 Install Wordpress on the Web server EC2.

Wordpress is based on LAMP framework.

- Update the yum repository:

```sh
sudo yum update -y
```

- Install wget , apache, and all necessary dependencies:

```sh
sudo yum -y install wget httpd  # Apache is typically called httpd in redhat and centos based systems
```

- start apache
```sh
sudo systemctl enable httpd 
sudo systemctl start httpd
```

- Install php and all its dependencies:

```sh
# Install epel (Extra packages for Enterprise Linux)

sudo yum install epel-release -y

# Install Remi repository

sudo yum install https://rpms.remirepo.net/enterprise/remi-release-7.rpm

# Reset the default PHP module and enable PHP 7.4:

sudo yum module reset php -y
sudo yum module enable php:remi-7.4 -y

# Install php and necessary modules
# For amazon linux, you can skip the previous steps

sudo yum install php php-mysqlnd php-fpm php-json php-gd php-xml php-mbstring php-zip php-curl php-intl -y

```
You may need to modify the PHP configuration (in `/etc/php.ini`) to match the requirements of your WordPress site especially in production setups.


Restart Apache:

```sh
sudo systemctl restart httpd

```

- Download wordpress and copy wordpress to `/var/www/html`

```sh

# Install wordpress
sudo wget https://wordpress.org/latest.tar.gz

sudo tar -xzvf latest.tar.gz

sudo rm -rf latest.tar.gz

# Change to the wordpress directory
cd wordpress

cp wp-config-sample.php wp-config.php

sudo cp -R * /var/www/html # Essentially copies wordpress folder to the apache document root.We can use a mv command but cp enables us to go back if there are mistakes.


```

- Configure SELinux Policies. (Important for Redhat linux and centos machines)

These commands are necessary when running WordPress on a system with SELinux  (Security-Enhanced Linux) enabled, which is common on many Linux distributions, particularly CentOS and RHEL. Configuring them ensures that wordpress can run properly.

```sh
sudo chown -R apache:apache /var/www/html/wordpress
sudo chcon -t httpd_sys_rw_content_t /var/www/html/wordpress -R
sudo setsebool -P http_can_network_connect=1

```

Otherwise, Using `semanage fcontext` and `restorecon` is generally preferred for making permanent changes to file contexts in SELinux. It ensures that your desired contexts survive system updates, policy changes, and manual relabels. The commands are as follows:

```sh
sudo chown -R apache:apache /var/www/html/wordpress

sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/wordpress(/.*)?"

sudo restorecon -R /var/www/html/wordpress

sudo setsebool -P http_can_network_connect=1

```

## Step 6 Install MysQL on the DB server EC2 and configure remote access.

```sh

# Update repo
sudo yum update

# Download the RPM file
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 

# Install RPM file
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y

# You need the public key of mysql to install the software.
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

# Install mysql server. To install the client use: sudo dnf install mysql-community-client -y
sudo dnf install mysql-community-server -y

# Enable mysql daemon
sudo systemctl enable mysqld

# Start mysql daemon
sudo systemctl start mysqld

# Start mysql daemon
sudo systemctl status mysqld
```
![Mysql running db](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/msql%20running%20db.png)

Ensure to follow the steps to secure mysql. Create root user, then run the secure_mysql_installation.

Configure remote access by editing the mysql configuration file with is found at `/etc/my.cnf` in Mysql installed on Amazon linux 2023

![my.cnf file](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/my.cnf%20file.png)

**Troubleshooting**
Here, I encountered a bit of challenge logging in to mysql. It seemed the password for root was alrady set and I didn't know it! I was able to resolve it by doing a little research. I found out that new versions of MySQL 8.0+ come with a default security configuration that prevents access. A temporary password has been created for the root user which can be found with the following command:

```sh
sudo grep 'temporary password' /var/log/mysqld.log
```
![Troubleshooting mysql login](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/Troubleshooting%20mysql%20login.png)

We can now log in with the output DB_PASSWORD...

```sh
sudo mysql -p
```
then change the password with the 'ALTER USER' command: 

```sh
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Passw0rd123#';
```

## Step 7 Configure the DB to work with WordPress

```sh

CREATE DATABASE wordpress;

CREATE USER 'admin'@'[web-server private IP address]' IDENTIFIED BY 'Passw0rd321#';

GRANT ALL PRIVILEGES on wordpress.* TO 'admin'@'[web-server private IP address];

FLUSH PRIVILEGES;

SHOW DATABASES;

exit
```

![admin user wordpress db](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/admin%20user%20wordpress%20db.png)

## Step 8 Configure wordpress to connect to remote database

- Ensure Open inbound rules on port `3306` on the db-server EC2 from the webserver IP only, for security purposes.


- Install mysql client on `project-web` and test your ability to connect to the db server:

```sh
# Update repo
sudo yum update

# Download the RPM file
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 

# Install RPM file
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y

# You need the public key of mysql to install the software.
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

# To install the mysql-client use:
sudo dnf install mysql-community-client -y

```
- Connect to remote db server, entering the password you configured.

```sh
sudo mysql -u admin -h [DB-Server- PRivate-IP address] -p
```

Execute some database commands to verify remote access:

```
SHOW DATABASES;
```
![login to db from web](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/login%20to%20db%20from%20web.png)

- Ensure that proper file permissions are set: Apache needs the correct permissions to read and write WordPress files.These commands should set Apache as the owner of the WordPress files, set directories to 755 permissions, and files to 644 permissions.

```sh
sudo chown -R apache:apache /var/www/html/wordpress
sudo find /var/www/html/wordpress -type d -exec chmod 755 {} \;
sudo find /var/www/html/wordpress -type f -exec chmod 644 {} \;
```


- Configure wp-config.php: Edit the `wp-config.php` file to include your remote database details. ( This can also be configured on the UI)

```sh
sudo vi /var/www/html/wordpress/wp-config.php
```

Update the following lines with your remote database information:

```sh
define('DB_NAME', 'your_database_name');
define('DB_USER', 'your_database_user');
define('DB_PASSWORD', 'your_database_password');
define('DB_HOST', 'your_database_server_private_ip');
```

![image edit wp config](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/edit%20wpconfig.png)

- Ensure Apache is configured to serve WordPress. Create a new Apache configuration file:

```sh
sudo vi /etc/httpd/conf.d/wordpress.conf # the conf.d folder is used in Redhat distributions unlike ubuntu which uses sites-available
```
Enter the following:

```sh
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/wordpress
    ServerName your_domain_or_ip

    <Directory /var/www/html/wordpress>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/http/error.log
    CustomLog /var/log/http/access.log combined
</VirtualHost>
```
&nbsp;
Remember to replace `your_domain_or_ip` with your domain. In this case, I used `wordpress`(the document folder) since I did not create a domain for this project.


Visiting our instance public-Ip, we see the following image
![wordpressinstall on uI](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/wordpressinstall%20on%20uI.png)
Follow the prompts to install wordpress and login


![Welcome to Wordpress](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/WEB-SOLUTION_WORDPRESS/images/welcome%20towordpress.png)


# Conclusion
We successfully implemented a robust storage subsystem on two Linux RHEL servers, demonstrated  a Three-Tier Architecture with wordpress utilizing client-server architecture.


