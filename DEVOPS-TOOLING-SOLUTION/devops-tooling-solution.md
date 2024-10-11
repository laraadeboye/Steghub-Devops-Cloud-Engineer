
# TOOLING WEBSITE SOLUTION
## 3-tier Web Application with A Database server And An NFS server as a shared file storage

[Achitecture Diagram]
This project involves the development of a 3-tier web application that integrates a database server and a Network File System (NFS) server for shared file storage. 

It can be applied by businesses and developers seeking a robust, scalable solution. The architecture separates the application into three distinct layers: 
- the presentation layer (user interface), 
- the application layer (business logic), 
- and the data layer (database management).

The NFS server serves as centralized storage, allowing multiple users to access and manage files seamlessly, while the database server handles data storage and retrieval efficiently.

This setup not only enhances performance but also ensures better data management and security. It can be used by organizations to improve collaboration among teams, streamline workflows, and adapt to changing data needs effectively.

This project provides a solid foundation for deploying modern web applications that require reliable data access and efficient file sharing in dynamic environments.


## Infrastructure components 
- Webservers: Red Hat Enterprise Linux 9
- Database server: Ubuntu 24.04 + MySQL
- Storage Server: Red Hat Enterprise Linux 9 + NFS server
- Language: PHP
- Code Repository: [Github](https://github.com/laraadeboye/tooling)

## Steps

## Step 1 Prepare the NFS server.

1. Create RHEL EC2 instance:

We will create an EC2 instance named `NFS-server` with RHEL Linux 9 Operating System via AWS console to serve the NFS server. Connect to the instance via SSH or use instance connect on the AWS console. You can install instance connect on the RHEL EC2 instance by following the instructions in the [documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html) as the machine does not come preinstalled with it.

[NFS-server running]

**Security group setting for the NFS server**
To allow NFS server to communicate effectively with the client, allowing for seamless file sharing and management accross our network, we will allow inbound access on ports:
- PortMapper (111): Essential for client-server communication `TCP/UDP 111`
- NFSd (2049): Main communication channel for all NFS operations. If this port is not open, clients cannot access shared files.`TCP/UDP 2049`
- MountD (20048): It is necessary for mounting file systems. Clients may be unable to mount NFS shares properly if it is blocked  `TCP/UDP 20048`

- Additional Ports(9023 -9026): Depending on the version of NFS used, you can open this port range to enhance the performance and reliability of the NFS service. `TCP/UDP 9023-9026`

To check the ports used by NFS (applicable after NFS installation), run:

```sh
rpcinfo -p | grep nfs
```
Note that these ports should only be open to the VPC CIDR or specific subnet CIDRs for better security.

2. Create storage infrastructure for the NFS server using Logical Volume Management (LVM)

- First create 3 volumes for the NFS server via the AWS management console and attach it to the EC2 instance.

[volumes created]

[3 volumes attached]

- Verify the attached volumes on the terminal. Run:

```sh
lsblk
```
[lsblk attached volumes]

- Create one partition each for the volumes:

Check if `gdisk` is installed. Install  if uninstalled:

```sh
sudo yum install gdisk -y
```
Create the partitions:
```sh
sudo gdisk /dev/xvdf
sudo gdisk /dev/xvdg
sudo gdisk /dev/xvdh
```
[lsblk gdisk 3volumes]

- Create logical volumes using `lvm2`.

Install `lvm2`:

```sh
sudo yum install lvm2 -y
```

Run `sudo lvmdiskscan` to verify the presence of available disk partitions.

[Verify Available disk partitions]

Use `pvcreate` to turn the partitions to physical volumes

```sh
sudo pvcreate /dev/xvdf1 /dev/xvdg1 /dev/xvdh1
```
Verify by running `sudo pvs`.

[pvcreate sudo pvs]

Use `vgcreate` to group the volumes into a volume group named `nfs-vg`

```sh
sudo vgcreate nfs-vg /dev/xvdf1 /dev/xvdg1 /dev/xvdh1
```
Verify by running `sudo vgs`

[vgcreate sudo vgs]

Use `lvcreate` to create three  logical volumes from the volume group: `lv-opt`, `lv-apps`, `lv-logs` each with 9G

```sh
sudo lvcreate -n lv-opt -L 9.5G nfs-vg

sudo lvcreate -n lv-apps -L 9.5G nfs-vg

sudo lvcreate -n lv-logs -L 9.5G nfs-vg
```

It's generally a good idea to leave some free space in your volume group. This allows for future expansion and ensures there's room for LVM metadata. The exact amount space needed for metadata varies, but it's usually small (around 1-2 MB per physical volume).

Verify with `sudo lvs`

[lvcreate sudo lvs]

Verify the entire configuration by running:

```sh
sudo vgdisplay -v
```
[vgdisplay 1]
[vgdisplay 2]
[vgdisplay 3]
You can also run `sudo lsblk`

[lsblk vg]


- Format the filesystem:

After creating the logical volumes, we will format the file system as `xfs` . 
`xfs` is preferred over `ext4` for large file transfers.

```sh
sudo mkfs -t xfs /dev/nfs-vg/lv-opt # or sudo mkfs.xfs /dev/nfs-vg/lv-opt

sudo mkfs -t xfs /dev/nfs-vg/lv-apps

sudo mkfs -t xfs /dev/nfs-vg/lv-logs
```
[format files]

- Create mount points. 

Create the `mnt directory` having the following folders `mnt/apps` `mnt/opt` `mnt/logs` 

```sh
sudo mkdir -p /mnt/apps /mnt/opt /mnt/logs
```
Because `/mnt` is a system directory, creating or modifying directories or files within it usually requires administrative privileges, hence the use of `sudo`

Mount the `lv-apps` on the `/mnt/apps`. This will make the contents of the logical volume accessible under the `/mnt/apps`.

```sh
sudo mount /dev/nfs-vg/lv-apps /mnt/apps
```

Mount the `lv-opt` on the `/mnt/opt`. This will make the contents of the opt logical volume accessible under the `/mnt/opt`.

```sh
sudo mount /dev/nfs-vg/lv-opt /mnt/opt
```


Mount the `lv-logs` on the `/mnt/logs`. This will make the contents of the logs logical volume accessible under the `/mnt/logs`.

```sh
sudo mount /dev/nfs-vg/lv-logs /mnt/logs
```

- Install the NFS server, configure it to start on reboot:

```sh
sudo yum -y update
sudo yum install nfs-utils -y
sudo systemctl start nfs-server
sudo systemctl enable nfs-server
sudo systemctl status nfs-server
```

Check NFS installation by viewing the NFS statistics :
```sh
sudo nfsstat -s
```

[nfs-server installed status]


- We will create the three web servers in the same subnet within the default VPC for our test case for simplicity. The default VPC in AWS typically has a CIDR block of `172.31.0.0/16` and creates a default subnet in each Availability Zone in the region. Each subnet is usually a `/20` network within this range. Setting up the webservers in different subnet also allows for security. The `subnet cidr` is found by clicking on the networking tab in the details section of the EC2 instance.

We will also set the appropriate permissions to allow the webservers to read, write and execute on NFS:

```sh
# ownership
sudo chown -R nobody: /mnt/apps
sudo chown -R nobody: /mnt/opt
sudo chown -R nobody: /mnt/logs

sudo chmod -R 777 /mnt/apps
sudo chmod -R 777 /mnt/opt
sudo chmod -R 777 /mnt/logs
```

The `nobody` user is a standard account used on many Unix-like systems that has very limited privileges. This is common in scenarios where you want to allow services (like NFS) to access files without granting them full user privileges.  In production, you should ideally use a dedicated user/group for your application for better security (e.g., `webuser:webgroup`)

```sh
sudo chown -R webuser:webgroup /mnt/apps
```
Also note that the permissions (`777`) are very open. It is suitable for our testing case. In a production environment, you might want to use more restrictive permissions based on your specific needs.

e.g for directories, `750` (Read, write, execute for owner; read and execute for group; no permissions for others)
for files, `640` (Read and write for owner; read for group; no permissions for others)


Restart the nfs service to apply the changes:

```sh
sudo systemctl restart nfs-server
```

- Obtain the subnet cidr of the instances from the console, and configure access to NFS for clients within the subnets. We will edit `etc/exports` file in the NFS server.

[subnet cidr]

```sh
sudo vi /etc/exports
```
The format of the entry is as shown:

```
/mnt/apps [subnet-CIDR](rw,sync,no_all_squash,no_root_squash)
/mnt/opt [subnet-CIDR](rw,sync,no_all_squash,no_root_squash)
/mnt/logs [subnet-CIDR](rw,sync,no_all_squash,no_root_squash)
```
Explanations on the export options are found in the [nfs-study readme.md](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/DEVOPS-TOOLING-SOLUTION/self-side-study/nfs-study.md) within this repo.
So we will enter the following content:

```sh
/mnt/apps 172.31.32.0/20(rw,sync,no_all_squash,no_root_squash)
/mnt/opt 172.31.32.0/20(rw,sync,no_all_squash,no_root_squash)
/mnt/logs 172.31.32.0/20(rw,sync,no_all_squash,no_root_squash)
```

*Hint*

Typically, if we were to use three different subnets, we will first create additional subnets with different subnet cidrs within the VPC. If the created subnet cidrs are:`172.31.0.0/20`, `172.31.16.0/20`, and `172.31.32.0/20` respectively, the command will look like below:

```sh
/mnt/nfs/lv-opt    172.31.0.0/20(rw,sync,no_root_squash) 172.31.16.0/20(rw,sync,no_root_squash) 172.31.32.0/20(rw,sync,no_root_squash)
/mnt/nfs/lv-apps   172.31.0.0/20(rw,sync,no_root_squash) 172.31.16.0/20(rw,sync,no_root_squash) 172.31.32.0/20(rw,sync,no_root_squash)
/mnt/nfs/lv-logs   172.31.0.0/20(rw,sync,no_root_squash) 172.31.16.0/20(rw,sync,no_root_squash) 172.31.32.0/20(rw,sync,no_root_squash)
```


Exit the editor and run the command below to apply the changes:

```sh
sudo exportfs -arv
```
[exportfs]

- Configure the security group setting for the NFS server. 

Check which port is used by NFS and add allow the new inbound rule in the security group settings from the three subnet CIDR blocks:

```sh
rpcinfo -p | grep nfs
```
[2049]

security group rule: Type: NFS, Protocol: TCP, Port Range: 2049, Source: `172.31.32.0/20`

[security group rule nfs]

*Hint*
Example rules for 3 subnets:

Type: NFS, Protocol: TCP, Port Range: 2049, Source: 172.31.0.0/20
Type: NFS, Protocol: TCP, Port Range: 2049, Source: 172.31.16.0/20
Type: NFS, Protocol: TCP, Port Range: 2049, Source: 172.31.32.0/20
Repeat for ports 111 and 20048


- Make the NFS Mounts Persistent accross System Reboot:

To ensure that your NFS mounts persist across system reboots, you need to add entries to the `/etc/fstab` file. This file contains information about disk drives and partitions, and it's used by the system to mount filesystems automatically at boot time.

Open the `/etc/fstab` file with a text editor:

```sh
sudo vi /etc/fstab
```

Add the following lines at the end of the file:

```sh
/dev/nfs-vg/lv-apps /mnt/apps xfs defaults 0 0
/dev/nfs-vg/lv-opt  /mnt/opt  xfs defaults 0 0
/dev/nfs-vg/lv-logs /mnt/logs xfs defaults 0 0
```

Save and close the file.

To verify that the entries are correct and will mount properly, run:

```sh
sudo mount -a
```
If this command completes without any errors, your fstab entries are correct.



## Step 2 Configure the Database Server.

Launch an ubuntu EC2 instance named `DB-server`, that will serve as the Database server. 

Configure the security group to allow inbound access on the default port for mysql `3306` from the subnet cidr of the webserver which in my use case is `172.31.32.0/20`

[db server security group rule]

Connect to it via SSH or instance connect. 
[DB server running]




- Install MySQL server:

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


[Image mySQL running]
Follow the steps to secure mysql. Create root user, then run the secure_mysql_installation.

- Login to the mysql console:

```sh
sudo mysql
```

- Create the root user with a new password:

```sh
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Passw0rd123#';
```
Ideally, in a production environment use a stronger password.

Exit the mysql console:

```sh
exit
```

- Secure mysql by following the prompts:

```sh
sudo mysql_secure_installation
```
[mysql secure install]

- Configure remote access. Edit the `mysqld.cnf` file, replacing the **bind-address** port on localhost `127.0.0.1` with `0.0.0.0`

```sh
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf
```

[image mysqld.cnf]

Restart mysql to apply changes:

```sh
sudo systemctl restart mysql
sudo systemctl status mysql
```

- Login to mysql with the root user. 

```sh
sudo mysql -u root -p
```
- Create a database and name it `tooling` with a database user named `webaccess` granted access only from the webservers subnet cidr `172.31.32.0/20`

```sql
CREATE DATABASE tooling;
CREATE USER 'webaccess'@'172.31.32.0/20' IDENTIFIED BY 'Passw0rd321#';

GRANT ALL PRIVILEGES on tooling.* TO 'webaccess'@'172.31.32.0/20';

FLUSH PRIVILEGES;

SHOW DATABASES;

USE tooling;

SELECT host, user from mysql.user;

exit

```

[mysql oper on db]

*Hint*
In a production environment with different subnets, we can use wild cards. For example:


```sql
-- Create the user with wildcard for the host
CREATE USER 'webaccess'@'172.31.%' IDENTIFIED BY 'Passw0rd321#';

-- Grant privileges to the user for the specific database
GRANT ALL PRIVILEGES ON tooling.* TO 'webaccess'@'172.31.%';

-- Optional: Flush privileges to apply changes immediately
FLUSH PRIVILEGES;

```

## Step 3 Configure the Web Servers.

Our goal is to ensure that the web servers serve the same content from the shared storage solutions i.e the NFS server and MySQL database server. The Database server can allow multiple reads and writes by multiple clients. We will use the NFS server to store shared files that the three web servers will use. 

The previously created logical volume for the web application on `lv-apps` will be mounted on the apache web files diectory on `/var/www`

This makes the web servers stateless, thereby preserving the integrity of the data in the database and on the NFS

Next, we will:
- Configure NFS client on all three web servers
- Deploy a tooling application to web servers into a shared NFS folders
- Configure the three web servers to work with a single MySQL database.


We will use RHEL Operating system 9 for our webservers.

Launch 3 RHEL webservers on AWS named `webserver-01`, `webserver-02`, `webserver-03`. Configure the security groups to allow inbound access on ports `80` (HTTP) and `22`(SSH); 

[3 webservers running]

[Take security group pics]

The following commands should be applied on all three servers.

- Install the NFS client :

```sh
sudo yum install nfs-utils nfs4-acl-tools -y
```

`nfs-utils` allows you to set up and manage NFS shares and clients.


`nfs4-acl-tools` package provides tools specifically for managing NFSv4 Access Control Lists (ACLs). NFSv4 supports advanced file permission settings (ACLs), and this tool allows you to manipulate and configure these permissions.

- Mount `/var/www` targeting the NFS server's export for apps
This means we will connect the local directory `/var/www` on our web server to the shared directory (or "export") for apps `/mnt/apps` on an NFS server. 

```sh
# create the mount point on the web server
sudo mkdir /var/www

# mount the directory to the target directory on the web server
sudo mount -t nfs -o rw,nosuid [NFS-Server-Private-IP-Address]:/mnt/apps /var/www
```

Replace [NFS-Server-Private-IP-Address] with your private NFS server address which in my case is : `172.31.39.177`

```sh
sudo mount -t nfs -o rw,nosuid 172.31.39.177:/mnt/apps /var/www
```
**explanation of the flags**
`-t nfs`: Specifies the file system type as NFS.
`-o rw,nosuid`:
`-o` specifies the mount options which follows thereafter.
`rw` mounts the directory with read-write permissions.
`nosuid` prevents the execution of any set-user-identifier or set-group-identifier files on this mount, adding an extra layer of security.

*Troubleshooting hint*
if the mount command is not successfull, It may mean your security groups are not properly configured, your nfs configuration file may need to be checked. Review them.

You can install the nmap tool to check connection to the port with the following command:

```sh
sudo yum install nmap-ncat -y
```
Then run: `nc -zv [private IP of nfs server] 2049` to review connection settings


- Verify that the NFS was mounted successfully by running `df -h`.

[df -h webserver 1]
[df -h webserver 2]
[df -h webserver 3]

- Ensure that the changes persist on the web servers after reboot by editing the `/etc/fstab` and adding the following content:

```sh
[NFS-Server-Private -IP]:/mnt/apps /var/www nfs defaults 0 0
```

```sh
172.31.39.177:/mnt/apps /var/www nfs defaults 0 0
```
- Next we will install the Remi repository (which is an open source repo that provides the latest full-featured versions of some software to fedora and enterprise linux machines), Apache and PHP.

```sh
sudo yum install httpd -y
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install dnf-utils https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf module reset php
sudo dnf module enable php:remi-8.1
sudo dnf install php php-opcache php-gd php-curl php-mysqlnd -y
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo setsebool -P httpd_execmem 1
sudo systemctl start httpd
sudo systemctl enable httpd
```
- Verify the installation of apache and php

- Verify that the Apache files and directories are available on the web servers in `/var/www` and also on the NFS server in `mnt/apps`. We will try creating a new file from one server and check if the file is accessible on another server.

Run the following command on `webserver1`. Check for the presence of the file in `webserver2` and `webserver3` respectively.
```sh
sudo touch /var/www/html/test.txt
```
Notice that the file is also present in the `/mnt/apps/html` folder in the NFS server

- We need to mount the Apache log folder to the NFS server. Typically, Apache logs are stored in `/var/log/httpd` Before we mount, it is important to backup the log files to prevent the loss of log files.

Create the folder for the backup files and use the `rsync` utility to copy the content into it as follows:

```
sudo mkdir -p /var/backups/httpd_logs
sudo rsync -av /var/log/httpd/ /var/backups/httpd_logs/
```

Then mount the NFS share:

```sh
sudo mount -t nfs -o rw,nosuid [NFS-Server-Private-IP-Address]:/mnt/logs /var/log/httpd
```
```sh
sudo mount -t nfs -o rw,nosuid 172.31.39.177:/mnt/logs /var/log/httpd
```

Also make sure the mount point persist after reboot by editing the `/etc/fstab`.

And add this line to `/etc/fstab`:

```sh
[NFS-Server-Private-IP]:/mnt/logs /var/log/httpd nfs defaults 0 0
```

```sh
172.31.39.177:/mnt/logs /var/log/httpd nfs defaults 0 0
```

Restore the backed-up log files to the mounted directory using `rsync`:
```sh
sudo rsync -av /var/backups/httpd_logs/ /var/log/httpd/
```

**Tooling Website Deployment**
- Clone the tooling repository and move the contents of the html folder to /var/www/html:

```sh
git clone https://github.com/laraadeboye/tooling.git
sudo cp -R tooling/html/. /var/www/html/
```

[git installed server 1]

The git clone and copy command was run on only `webserver1` . The content of the `/var/www/html` is found in the remaining two servers as shown in the images below:

*Hint*:
You may need to install git : `sudo yum install git -y`
`tooling/html/.` copies all contents, including hidden files.
`tooling/html/*` copies all visible contents but excludes hidden files.

The tooling website code is deployed to the webservers. The html folder from the repo is deployed to `/var/www/html`

- Set appropriate permissions:
```sh
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html
```
[change ownership to apache]
This change of ownership will also be reflected in the remaining two servers.

- Set selinux policies: Important for website access 

```sh
# Change ownership
sudo chown -R apache:apache /var/www/html/

# Add SELinux context
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"

# Restore SELinux contexts
sudo restorecon -R /var/www/html/

# Allow network connections:
sudo setsebool -P httpd_can_network_connect on

# Allow access to NFS mounts
sudo setsebool -P httpd_use_nfs on

# Allow access to allocated memory
sudo setsebool -P httpd_execmem on

```

- We will update the `/var/www/html/functions.php` file with the correct database connection details. You can use `sed` to replace placeholders:

```sh
$db = mysqli_connect('172.31.38.76', 'webaccess', 'Passw0rd321#', 'tooling');
```
[update db details]

- We will install mysql client on the webservers. Run the following commands to install mysql client on the servers. (You may need to install `wget` utility first: `sudo yum install wget -y`)

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


- Apply the `tooling-db.sql` script to the database by using the following command:

```sql
mysql -h [database-private-ip] -u [db-username] -p [db-password] < tooling-db.sql
```
```sql
mysql -h 172.31.38.76 -u webaccess -p tooling < tooling-db.sql
```
Enter the password for the webaccess user when prompted.

[apply tooling script]

If the command runs without errors, it is successful.


- In the MySQL server we create a new admin user with username `myuser` and password `password`. 

```sh
INSERT INTO `users` (`username`, `password`, `email`, `user_type`, `status`) 
VALUES ('myuser', '5f4dcc3b5aa765d61d8327deb882cf99', 'user@mail.com', 'admin', '1');

```

[acessing database from webserver 1]




- When we open the website in our web browser at `http://[web-server-Public-IP]/index.php` , we should be able to login with the `myuser` user

```sh
http://98.81.207.96/index.php
```
[Tooling website deployed]

[login with password]

*Hint*
If you get a 403 forbidden error as shown below:

[403 forbidden]

Check:
1. `/var/www/html` folder and file permissions

2. Disable selinux policies: 

```sh
sudo vi /etc/selinux/config
```

Find the line that reads `SELINUX=enforcing` and change it to:

```
SELINUX=permissive
```

## Conclusion

We deployed a tooling solution in a three-tier architecture consisting of a shared database and a shared NFS server.





