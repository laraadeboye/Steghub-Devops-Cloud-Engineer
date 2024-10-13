
# Deployment of tooling website with Continuous Integration (using Jenkins)

We will be enhancing our DevOps Pipeline by implementing Continuous Integration with Jenkins.

Following up on our [three tier architecture](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/DEVOPS-TOOLING-SOLUTION/devops-tooling-solution.md), we have added an apache load balancer to evenly distribute web traffic between our three webservers for improved performance and scalability [here](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/LOADBALANCING-WITH-APACHE/loadbalancing-with-apache.md).

Next up, we want to begin automating our architecture  with continuous integration using Jenkins. Continuous Integration is an important concept in DevOps as it allows for automated build and tests of code changes commited to a central repository by developers.

Introducing Jenkins will provide significant benefits for our set up. Jenkins enables automated build and test processes that trigger whenever changes are pushed to the repository, ensuring quick detection of issues while facilitating consistent deployments to reduce human error. 

By automating the entire pipeline from code commit to production deployment, Jenkins significantly shortens release cycles and time-to-market. It also improves code quality by integrating automated code quality checks and unit tests into the pipeline. 

Furthermore, Jenkins enhances collaboration among team members by providing visibility into the build and deploy process, and it offers scalability, allowing you to easily expand the CI/CD pipeline as the project grows.

## Prerequisites
- Ubuntu 24.04 LTS
- Basic AWS knowledge

## Steps
## Step 0 Launch an Ubuntu EC2 instance.

- Create a separate security group for Jenkins. This approach offers better security isolation and more flexible management, aligning with best practices for cloud infrastructure security.
Allow inbound internet access on jenkins default port `8080` for the jenkins instance on AWS named `jenkins-server-sg`. I also allowed SSH access on port 22 to access the server for configuration.

[jenkins-server-sg]

- Launch a `t3.medium` sized ubuntu instance 24.04 LTS on AWS named `jenkins-server` with the security group `jenkins-server-sg` that we created. Depending on the specific workload, a larger instance may be needed in production settings. The recommended instance sizes for test and production environments can be found in my [write-up](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/DEPLOYMENT-AUTOMATION-INTRODUCING-JENKINS/self-side-study/jenkins-notes.md) on the subject.

[jenkins-server running]

- Login to the instance via SSH or instance connect and update the ubuntu apt repository:

```sh
sudo apt update -y && sudo apt upgrade -y
```

## Step 1 Install and Configure Jenkins 

Based on the [official documentation](https://www.jenkins.io/doc/book/installing/linux/) for installing Jenkins , it requires JDK to run. So we must install it first:

```sh
sudo apt update
sudo apt install fontconfig openjdk-17-jre
java -version
openjdk version "17.0.8" 2023-07-18
OpenJDK Runtime Environment (build 17.0.8+7-Debian-1deb12u1)
OpenJDK 64-Bit Server VM (build 17.0.8+7-Debian-1deb12u1, mixed mode, sharing)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
source ~/.bashrc 
```
This installs OpenJDK version 17.

- Next, we will install Jenkins:

```sh
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
```

- Verify that Jenkins is running:

```sh
sudo systemctl status jenkins
```
[jenkins verified]

- We will access the jenkins server via its public IP and port as shown:

```sh
http://[jenkins-server-public-ip]:8080
```
My jenkins public IP is `52.23.197.77`

Hence:
```sh
http://52.23.197.77:8080
```
[jenkins on web]

- We are prompted for the Administrator password which is found in `/var/lib/jenkins/secrets`

Run:
```sh
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
The password looks like the string of numbers below:
![Initial Admin Password]

When you enter the password, you will be taken to the following page:
![suggested plugins page]

Install the suggested plugins, then create an admin user with a secure password. We will use `Passw0rd123#` for our test environment.
![Initial Admin user]

&nbsp;
Accept the root URL then click **Save $ Finish**

[jenkins is ready]



## Step 2 Configure Jenkins to retrieve source codes from Github using Web hooks.

We will configure a jenkins job that will be triggered by Github webhooks. The webhook will execute a build task to retrieve codes from Github and store it locally on Jenkins server. 

A webhook serves as a mechanism for real-time communication between services. It is essentially an HTTP callback that triggers an action on one application when a specific event occurs in another application. 

For instance, when a developer pushes code to a GitHub repository, a webhook can notify Jenkins to automatically start a build process. 

- We will enable webhooks in our Github repository. 
  - Navigate to the **settings** tab of located under the github repo name, `tooling` (which can be forked [here](https://github.com/laraadeboye/tooling))
  - Select **webhooks** in the left sidebar, and Click on **Add a webhook**
  - In the Payload URL field, enter the URL where you want Github to send the webhook requests. For Jenkins, it typically looks like `http://<jenkins_server_ip>:8080/github-webhook/`, replacing <jenkins_server_ip> with the IP address or domain of the jenkins server
  - Select the Content type as **application/json** to receive the payloads in JSON format.
  - Choose the Events based on your needs. **Just the push events** is okay for our use case.
  - Activate the webhook by checking the 'Active' checkbox
  - Click on **Add webhook** to save the settings

  [webhook config ]

- Go the Jenkins console. Click on **New Item**. Create a freestyle project named `toolingjob_github`
[create freestyle project]

- Connect your github repository by providing its URL. Also provide the credentials (user/password)

- Save the configuration and run the build. Click **Build Now**
[build job]
Notice the build will only be successful after you have properly done the configurations
This build only runs when we trigger it manually. Not sufficient for our use case.

- We will configure our job to trigger from the github webhook we created. Click **Configure**
Add the following configurations:
  - Configure **Build Triggers**: `Github hook trigger for GITScm poling`
  - Configure **Post-build actions** :`Archive the artifact`
  The files that are produced after a build are called artifacts

- We will test our configuration by making a little change to the Readme file in the `tooling` repository.
A new build is launched automatically by webhook and the artifacts are archived and saved on the Jenkins server.

[status build failed]

We see that the build failed and checking the console output, we can locate the cause of the error is due to configuration settings

[error.specify star]

When we correct the configuration settings as shown:


We will make another change to the Readme file, the build is succesful as shown:

[build succesful star solved]

The artifacts are stored by default on Jenkins server locally:
```sh
ls /var/lib/jenkins/jobs/toolingjob_github/builds/<build_number>/archive/
```
For the most recent build with number 5,
```sh
ls /var/lib/jenkins/jobs/toolingjob_github/builds/5/archive/
```
[artifacts saved in builds directory]

## Step 3 Configure Jenkins to copy files to NFS server via SSH

We have our artifacts saved locally on Jenkins server, we will copy them to the NFS server to `/mnt/apps` directory.

- SSH into your NFS server and run `df -h` to verify that the directory exist:


[df -h mnt apps nfs]

- First install the **Publish Over SSH** plugins (Navigate to Dashboard >> manage Jenkins>> Plugins >> Available Plugins)
![publish over ssh]
Once the plugin installation is successful, Restart Jenkins.Then, login again with your admin user and password.

![Restart plugin succesful]
- Configure the job to copy the artifact over to the NFS server
  - Select **Manage Jenkins** and choose **System**
  - Scroll to the **Publish over SSH** configuration section and configure it to connect to the NFS server:**Click on SSH Servers**
  - You need to provide a private key, arbitrary name `NFS-server`, Hostname(private IP of the NFS server), user-name (`ec2-user`),Remote directory (`/mnt/apps`). This is the folder that our webservers use as a mount point to retrieve files from the NFS server.
  - Save the configuration. Open the jenkins job configuration page and add another **Post-build Action**: `send build artifacts over SSH`.Configure it to send all files produces by the build into our previously defined directory `/mnt/apps`
We will use `**` to represent all source files.
  [configure ssh to NFS]

  [choose send build a]

  [configure send build a]

  [send build artifact over SSH]

 - Ensure to configure security group settings on the NFS server: Enable inbound SSH access from the jenkins server IP to the NFS server
jenkins server IP:`52.23.197.77/32`

  - Save the configuration. Make a little change in the Readme in the tooling repository.

- The webhook will trigger a new job in the console output of the job and we will see:
[build 6 success]

The console output verifies the successful update to the Readme
[sucessful build final]



- Verify that the /mnt/apps have been updated. Connect to the NFS server and check the README.md with the `cat` command

```sh
cat /mnt/apps/README.md
```
## Conclusion
We have configured a basic job triggered by a webhook using Jenkins CI. This is just the foundation for advanced CI task which we will carry out on our Jenkins server.






