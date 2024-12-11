
# CI/CD PIPELINE FOR A PHP BASED APP WITH JENKINS, ANSIBLE, ARTIFACTORY, SONARQUBE

PHP is an interpreted language and apps that are based on it can be deployed directly unto a server without compiling. Deploying an app directly, however makes it difdicult to package the app for releases.

We will create infrastructure for seven different environment while nginx serves as a reverse proxy for each of the environment. A reverse proxy serves as an intermediary between internal servers. The environments we will be creating are:

- CI
- DEV
- SIT
- UAT
- PENTEST
- PREPROD
- PROD

## STEPS
# Step 0 Prerequisites
 Beginning with the CI environment consisting of `ci`, `sonarqube`, and `artifactory`. We have our previously installed jenkins-ansible server serving as the ci. We will install two additional t2.medium servers for artifactory and sonarqube respectively.

1. Set up Nginx as a reverse proxy for the CI environment

  - Create a new t2.micro ubuntu 24.04LTS instance named  `nginx-reverse-proxy` on AWS having an elastic IP to prevent a change in the public IP on rebooting the system . It will serve as a reverse proxy for the CI environment which is made up of `ci`, `sonarqube`, and `artifactory`
  - Register a domain name (mine is `laraadeboye.com`) and configure the following to point to the nginx-reverse proxy server IP:
     ```
    ci.infradev.laraadeboye.com -> [Nginx-public-IP]
    sonar.infradev.laraadeboye.com -> [Nginx-public-IP]
    artifactory.infradev.laraadeboye.com -> [Nginx-public-IP]
    ```
    ![Dns management](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/CI-WITH-ANSIBLE-SOME-DEVOPS-TOOLS/images/DNS%20management.png)

- Install nginx on the server and ensure it is running and accessible on the browser:

     ```sh
    sudo apt update -y
    sudo apt install nginx -y
    ```
     ![nginx visible on browser](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/CI-WITH-ANSIBLE-SOME-DEVOPS-TOOLS/images/nginx%20visible%20on%20browser.png)

   - Navigate to the conf.d directory and create three configuration files named `ci.infradev.conf`, `sonar.infradev.conf` and `artifactory.infadev.conf`

     ```sh
    cd /etc/nginx/conf.d
    sudo touch ci.infradev.conf sonar.infradev.conf artifactory.infadev.conf
     ```

    ![create conf.d files](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/docs/update-readme/CI-WITH-ANSIBLE-SOME-DEVOPS-TOOLS/images/create%20conf.d%20files.png)

  - Open each of the files and add the following configuration for the respective environment.

  **ci.infradev.conf**
    [ci.infradev.conf]
  **artifactory.infradev.conf**
    ```sh
    ```
    [artifactory.infradev.conf]
  **sonar.infradev.conf**
    ```sh
    ```
    [sonar.infradev.conf]

  - Configure ssl using certbox. We will use one ssl certificate to manage all 3 servers for simplicity.
   The configuration files becomes:(  note the additional ssl line added by certbox)

   [ci dev after ssl]
   [artifactory dev after ssl]
   [sonar dev after ssl]

   Signing in to the  jenkins server and logging in to the environment on web browser, we see that jenkins is running:

   [signin page jenkins with A record]
   [login to jenkins https]

2. Add Ansible roles `artifactory` and `sonarqube` to the ci environment.


Artifactory is where the outcome of your build will be stored while sonarqube is used for continuous inspection of the code quality.

Create a new branch for configuring the artifactory roles. I initialised the artifactory role with ansible galaxy.

  ```sh
  ansible-galaxy init jfrog_artifactory

  ```
  [init jfrog]
  
  Edit the defaults, tasks , templates as appropriate to configure ansible to run the jfrog artifactory role.

  I saved the playbook in the `static assignments` folder as `artifactory.yml`. Also, update the CI inventory file with the `[artifactory_servers]` private IP.
  
  [artifactory ci.yml 2]

  Hence, running the playbook against the CI environment within the `ansible-config-mgt` directory:

  
  ```
  ansible-playbook -i inventory/ci.yml static-assignments/artifactory.yml
  ```
  [jfrog artifactory service running]

  The configuration files are located in the `ansible-config-mgt` [repo](https://github.com/laraadeboye/ansible-config-mgt/tree/main/roles/jfrog-artifactory)

3. Connect to your Jenkins-ansible server via SSH-forwarding as done in previous tasks.

# Step 1 Configure Ansible for Jenkins Deployment

Previously, we launched ansible commands directly from the CLI, Now we will run it via Jenkins UI. 
- Install blue oceans plugin (Go to Dashboard > Manage Jenkins > Plugins)
[blue Ocean plugin]

- Click on Open Blue Ocean
[click on open blue ocean]

- Create a new pipeline named `ansible-config-mgt` same as the name as the repo we used for our ansible deployments previously. Cancel blue oceans attempt to create a Jenkinsfile. We will do it manually. 
[click on new pipeline]

Click on Adminsitration to revert to the original jenkin UI

[ansible-config-mgt pipeline]

- Create a new folder named deploy within the `ansible-config-mgt` directory on the CLI

[create test jenkins feature]

Within this folder, create a Jenkinsfile and add a build stage:

```jenkinsfile
pipeline {
    agent any
    stages {
        stage ('build') {
            steps {
                script {
                    sh 'echo Building the application'
                }
            }
        }
    }
}
```


[building the app]
[blue ocean build]

Navigate to the ansible-config-mgt pipeline and choose **Configure**. Scroll to the `Build Configuration` section and enter the Script Path of the Jenkinsfile as `deploy/Jenkinsfile`
[deploy jenkinsfile]

In the pipeline console, choose **Build Now**. The build will be triggered and we can view it by going through the console output. 

The github repo has several branches and using jenkins, we can scan the repo to trigger a build for each branch.

We can create a git branch named `feature/jenkinspipeline-stages`.
Add an new stage named `Test` to the existing build stage as shown:

```jenkinsfile
pipeline {
    agent any
    stages {
        stage ('build') {
            steps {
                script {
                    sh 'echo Building the application'
                }
            }
        }
         stage ('Test') {
            steps {
                script {
                    sh 'echo Testing the application'
                }
            }
        }
    }
}
```
For the new branch to be available in Jenkins, we will instruct Jenkins to scan the repository. Click on Administration in the blue ocean UI to revert back to the legacy Jenkins UI. Navigate to the `ansible-config-mgt` project and click `scan repository now`

[scan repository now]
[build ocean pipeline stages]

When the page is refreshed, the branches will build simultaneously. Create a pull request and merge the latest code to the main branch.

We will add more stages and build namely `Package`, `Deploy` and `Clean up`

```
pipeline {
    agent any
    stages {
        stage ('build') {
            steps {
                script {
                    sh 'echo Building the application'
                }
            }
        }
         stage ('Test') {
            steps {
                script {
                    sh 'echo Testing the application'
                }
            }
        }
        stage ('Package') {
            steps {
                script {
                    sh 'echo Packaging the application'
                }
            }
        }
        stage ('Deploy') {
            steps {
                script {
                    sh 'echo Deploying the application'
                }
            }
        }
        stage ('Clean up') {
            steps {
                script {
                    sh 'echo Cleaning up the application'
                }
            }
        }
    }
}
```
[blue ocean UI main stages]
[blue ocean UI pipeline stages]

*Troubleshooting*
- Ensure to edit the payload URL in github to reflect the new address of jenkins:
[payload url settings]

# Step 2 Run ansible playbook from Jenkins UI
As a prerequisite, ansible has been installed on our jenkins-ansible server from previous projects. 
- Install ansible plugin on Jenkins.

[Install ansible plugin]
- Wipe out the existing content of the Jenkinsfile to start a new configuration that we can use to run ansible.
- Configure Ansible executable Path. Run `which ansible` on the CLI, then navigate to **Manage jenkins** >> **Tools**

[ansible configuration]

**Parameterizing Jenkinsfile to deploy Ansible**
- Launch four new servers for the SIT-tooling webserver and SIT-Todo webserver, SIT-dbserver and SIT-nginx-proxy respectively
[SIT servers]

- As a prerequisite register the domain names of the servers in your domain name management system
[SIT domain name reg]
- Update the inventory/sit.yml file as shown: (Replace the IPs withe the appropriate private IP of your server)

- Update the Jenkinsfile to introduce parmeterization and introduce tagging as well.The final updated pipeline is as follows:

```
pipeline {
    agent any
    parameters {
        string(name: 'inventory', defaultValue: 'dev', description: 'This decides the environment to deploy')
        string(name: 'tags', defaultValue: '', description: 'Comma-separated tags for limiting Ansible execution (e.g., webserver,db)')
    }
    stages {
        stage('SCM checkout') {
            steps {
                git branch: 'main',
                    credentialsId: '[github credential-id]',
                    url: '[github repo URL]'
            }
        }
        stage('Execute Ansible') {
            steps {
                ansiblePlaybook(
                    credentialsId: 'private-key',
                    disableHostKeyChecking: true,
                    installation: 'ansible',
                    inventory: "inventory/${params.inventory}.yml",
                    playbook: 'static-assignments/common.yml',
                    vaultTmpPath: ''
                )
            }
        }
    }
}
```
[parameters jenkinsfile]

- Jenkinsfile can also be configured inline as shown:
[Configure inline pipeline script]

Now each time we click on **build with parameters** in the jenkins UI or the play button in the blue ocean UI, we will be prompted to fill in the parameters we specified.

If we fill the sit environment, the build will occur in that environment.
[choosing parameter]

[build success 1]

[build success 2]

If we fill the dev environment, the build will occur in that environment.

[build with parameters on JenkinUI]

# Step 3 CI/CD Pipeline for Todo application
We will deploy a todo website that has unit tests. We will deploy the application directly from artifactory rather than git. 

As a prerequisite, we have created an ansible role to configure our artifactory and the artifactory is running and accessible on the url `https://artifactory.infradev.laraadeboye.com`:

[jfrog artifactory running]

Follow the prompts to set the admin password:
[artifactory set admin password]





1. Fork the repository to your github account

  ```
  https://github.com/laraadeboye/php-todo-app.git
  ```

2. Install PHP, its dependencies and composer tool on your jenkin-ansible server. The composer tool  is a dependency manager for PHP, similar to npm for Node.js or pip for Python. We will create an ansible role named php to install these: (The dependencies for the app are found in the composer.json file in the app repo)
 Still within our feature/artifactory-role branch, we will create a new role for php

 - Initialise the role with ansible-galaxy:

 ```
 ansible-galaxy init php
 ```
 Remove unnecessary folders like `files`, `tests`, `meta`.  Modify the `default/main.yml` to list the packages and the `tasks/main.yml` to install the packages.

Deploy the role: Include the role in your playbook and run it. I included mine in the `playbooks/site.yml`

```yaml
# Play 6: Install PHP and Dependencies on jenkins-ansible server
- name: Install PHP, Dependencies and composer
  hosts: jenkins
  become: yes
  roles:
    - php
```

Run the playbook against the `inventory/ci.yml`

```sh
ansible-playbook -i inventory/ci.yml playbooks/site.yml
```
[php role install]

Verify php and composer installation on the jenkins-ansible server

[php version and composer]

 The code for the role can be found [here] () in my github repo

3. Install plugins in Jenkins UI:
- Plot plugin (which is used to display tests reports and code coverage information)
- Artifactory plugin (which is used to upload artifacts onto the artifactory server)

[Install Plot and artifactory plugin]

We will configure artifactory in the Jenkins UI

[jfrog artifactory URL]

When configuring jfrog within the jenkins UI, take note to enter the URL of the artifactory instance (preferably the dns name) and the deployer user name and password.

[Configure jfrog artifactory in jenkins UI]

To create a deployer user in JFrog Artifactory:
- Log in to your Artifactory instance as an admin user.
- Go to Security > Group: Creating a new `group` named deployer with admin privileges.
- Click New User.
- Fill in the required details, such as username, email, and password.
- Assign the user to the deployer group. This aligns with best security practice rather than directly using the admin user. 

[Create user artofactory url]
[update user with deploy group]



Test the connection to the artifactory via the set user
[Test connection]

Create a new local repository named `todo-artifact-local`

[Create a new repository]


**Phase 2 Integrate Artifatory repository with Jenkins**
1. We will create a dummy Jenkinsfile in the php-todo-app repository.
I did this on the github UI. Create a new feature branch name `feature/integrate-jenkins-artifactory` to make new changes. You should not make changes directly on the main branch. Create a new file named `Jenkinsfile` at the project root. Include dummy Jenkinsfile content.

[create Jenkinsfile with dummy content]

2. Using blue ocean, we will create a multibranch jenkins pipeline connected to the php-todo-app repository.

[create multibranch pipeline todo app]
[Php todo app pipeline created]

Ensure to edit the configuration of the pipeline, by adding the github credentials you have previously set up so that jenkins can be successfully authentiacted to perform the build.

[Build success jenkinsfile dummy]
[build success jenkins dummy]

3. Create a database named `homestead` and user named `homestead` on the database server. We have the role named `mysql`(from geerlinguy community mysql role) in our `ansible-config-mgt` directory. 

This role uses Ansible's built-in `mysql_db` and `mysql_user` modules to manage MySQL databases and users, respectively. Hence, we do not need a local mysql client installation. 😉

But I will install a mysql client on the jenkins-ansible server in order to test access to the db server manually from a remote location:
Install the mysqlclient with the following commands:

```sh
# Update apt repo
sudo apt update -y

# Install Mysqlclient
sudo apt install mysql-client

# Verify the installation
mysql --version
```

We will create the database on the db server listed in our dev environment in the inventory/dev.yml file. 


We will update the `env_vars/dev.yml` file to include the todo app database named `homestead`.:

```yaml
# MySQL configuration for the development environment
# Ideally a stronger password should be set
mysql_root_password: "Passw0rd123#"
mysql_root_username: "root"

# Databases and users to be used for the dev environment
# Databases.
mysql_databases:
  - name: "homestead"
    collation: "utf8_general_ci"
    encoding: "utf8"
  - name: "tooling"
    encoding: "utf8"
    collation: "utf8_general_ci"

# Users.
mysql_users:
  - name: "homestead"
    host: "%"
    password: "Passw0rd321#"
    priv: "homestead.*:ALL"
  - name: "webaccess"
    host: "%"
    password: "Passw0rd321#"
    priv: "tooling.*:ALL"

```
[env_vars.dev2.yml]

Here is the play addressing our database
```
# Play 3: Set up MySQL on database servers
- name: Set up MySQL
  hosts: db
  become: yes
  vars_files:
    - ../env-vars/dev.yml  # Change this to ../env-vars/prod.yml for production, etc.
  roles:
    - mysql  # Ensure this role is installed and named correctly

```
Here is the `inventory/dev.yml` defined here:
[cat dev.yml]


Run the ansible-playbook to create the database and users:

```sh
cd ansible-config-mgt
ansible-playbook -i inventory/dev.yml playbooks/site.yml
```
[ansible play homestead database]

Navigate to the db server and verify the creation of the databases and users.
```sh
sudo mysql -u root -p #(enter password 'Passw0rd123#' when prompted)

# Verify databases
SHOW DATABASES;

#Verify users
SELECT User, Host FROM mysql.user;

#Verify privileges
SHOW GRANTS FOR 'username'@'hostname'; #(Replace 'username' and 'hostname' with the actual username and hostname you want to check.)
```

[verify databases mysql]
[verify privileges mysql]

4. The .env.sample file should be located in the project root but I can not find it:
[no .env.sample]

I created the file and entered dummy content for the database connectivity details. The environment variables for the database can be found in the config/database.php file.

```
DB_HOST=172.31.35.70
DB_DATABASE=db-name
DB_USERNAME=db-username
DB_PASSWORD=Sample-password
DB_CONNECTION=mysql 
DB_PORT=3306
```
[new .env.sample]



Save the actual details as environment variables under the Global properties in systems configuration in the Jenkins UI
Navigate to Manage jenkins >> System >> Global properties >> Environment variables

DB_HOST=172.31.38.76
DB_DATABASE=homestead
DB_USERNAME=homestead
DB_PASSWORD=Passw0rd123#
DB_CONNECTION=mysql 
DB_PORT=3306

[set global environment variables]

5. We will update the dummy jenkinsfile with proper configurations for the pipeline:

```
pipeline {
    agent any
    stages {
        stage('Initial Cleanup') {
            steps {
                dir("${WORKSPACE}") {
                    deleteDir()
                }
            }
        }
        stage('Checkout SCM') {
            steps {
                git branch: 'main', url: 'https://github.com/laraadeboye/php-todo-app.git'
            }
        }
        stage('Prepare Dependencies') {
            steps {
                script {
                    // Move .env.sample to .env and set environment variables
                    sh '''
                        mv .env.sample .env
                        echo "DB_HOST=${DB_HOST}" >> .env
                        echo "DB_PORT=${DB_PORT}" >> .env
                        echo "DB_DATABASE=${DB_DATABASE}" >> .env
                        echo "DB_USERNAME=${DB_USERNAME}" >> .env
                        echo "DB_PASSWORD=${DB_PASSWORD}" >> .env
                    '''
                    
                    // Create bootstrap cache directory with appropriate permissions
                    sh '''
                        mkdir -p bootstrap/cache
                        chown -R jenkins:jenkins bootstrap/cache
                        chmod -R 775 bootstrap/cache
                    '''
                    
                    // Install Composer dependencies with error handling
                    sh '''
                        set -e
                        composer install --no-scripts
                    '''
                    
                    // Run Laravel artisan commands
                    sh '''
                        php artisan key:generate
                        php artisan clear-compiled
                        php artisan migrate --force
                        php artisan db:seed --force
                    '''
                }
            }
        }
    }
}
```


Each step of the pipeline do the following:
- Initial cleanup: Deletes the entire workspace directory to ensure a clean start for the pipeline.

- Checkout SCM: Checks out the code from the specified Git repository (https://github.com/laraadeboye/php-todo-app.git) and branch (main).

- Prepare Dependencies: Performs the following steps to prepare the dependencies for the application:
 - Renames the .env.sample file to .env.
 - Note that I included commands under the dependencies to populate the `.env` file with the right details stored in the jenkins job environment variable.
 - Generates a new application key using Laravel's Artisan command (php artisan key:generate).
 - Installs the dependencies using Composer (composer install).
 - Runs the database migrations using Laravel's Artisan command (php artisan migrate). 
 - Seeds the database with initial data using Laravel's Artisan command (php artisan db:seed). This sets up the required database objects.


*Troubleshooting*
After a troubleshooting a couple of build failures due to several reasons (Note that the Jenkinsfile above has been updated to capture all my changes): 
- **Incompatible php version**: I resolved this by downgrading from the latest version of PHP to a lower version PHP 7.4. Check the my [ansible-config-mgt repo](https://github.com/laraadeboye/ansible-config-mgt/tree/main/roles/php)

- **Missing folder `bootstrap/cache`**:

``` 
[ErrorException]                                                                                                                                            
  file_put_contents(/var/lib/jenkins/workspace/ure_integrate-jenkins-articatory/bootstrap/cache/services.php): failed to open stream: No such file or directory  
```
The bootstrap/cache directory is used to store framework-generated files for performance optimization. 
I solved this error by updating the Jenkinsfile to create the folder with the right permissions

- **Artisan optimize error and invalid characters**
```
[ErrorException]                                                             
  Invalid characters passed for attempted conversion, these have been ignored                                                                           

Script php artisan optimize handling the post-install-cmd event returned with error code 1
```
I solved this my ensuring proper error handling in my Jenkinsfile. I also enclosed by database password in quotes.

- **Pdo exception (inability to connect to database)**: 
```
# Error statement
 [PDOException]                               
  SQLSTATE[HY000] [2002] Connection timed out 
```
I solved this by editting the Security group of the DB server to  allow inbound access to the DB server on port 3306 from Jenkins private IP.

- **wrong db password**: 
```
# Error statement
[PDOException]                                                                                                   
  SQLSTATE[HY000] [1045] Access denied for user 'homestead'@'ip-172-31-28-125.ec2.internal' (using password: YES)  
```
I discovered that I set the wrong password for the database by using mysqlclient to test remote access to the DB server
[Jenkins laravel build success]



We will verify the content of the database to ensure that the database tables are created. Log in to the database and view the tables. (I logged in from the jenkins server using mysqlclient)

[Verify database tables]

After updating the Jenkinsfile, create a pull request and merge the changes in the `feature/integrate-jenkins-artifactory` to the `main ` branch.

The php-todo-app job should begin building. 



6. Add unit test stage:

```
stage ('Execute Unit Tests') {
            steps {
                sh './vendor/bin/phpunit'                
            }
        } 
```
(check why unit tests are failing)
The .env.sample file contain the environment variable defined in the project:

To ensure the unit test runs:
1. Install phpunit compatible version, e.g version 9 on the server.

```sh
# Installation steps
# The recommended way to install it is via composer. Composer must be pre-installed
composer require --dev phpunit/phpunit:~4.0

# Add Composer's Global bin Directory to PATH
echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> ~/.bashrc

# Reload the shell
source ~/.bashrc
```
2. Store the necessary environment variable in Jenkins environment variable and update the pipeline to include them in the newly created .env file.It is appropriate to configure the pipeline to use one app key, so we will store the last one created from our pipeline run in jenkins environment variable.


Update the .env.sample with the following dummy details

```
APP_ENV=local
APP_DEBUG=true
LOG_LEVEL=debug
APP_KEY=SomeRandomString
APP_URL=http://localhost

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync
```
An alternative way, (which is best) is to store the APP_KEY as a credential in jenkins that can be referenced in the pipeline.


*Troubleshooting*

**error 1**:

```sh
Warning:	The Xdebug extension is not loaded
		No code coverage will be generated.
```
Solution: Xdebug is required for code coverage and must be installed
Install it with the following command: (I updated my ansible php role to install it with other packages at this point)

```sh
# Install xdebug
sudo apt-get install php7.4-xdebug
```

**error 2**:

```sh
Code coverage needs to be enabled in php.ini by setting 'xdebug.mode' to 'coverage'
```
Solution: The error indicates that PHPUnit is trying to generate code coverage reports, but xdebug.mode is not configured for coverage in your PHP environment.

```sh
# Ensure xdebug is installed on the server
php -m | grep xdebug

# Install xdebug if not present
sudo apt-get install php7.4-xdebug #php version specific

# Edit your php.ini file to enable code coverage
echo "xdebug.mode=coverage" >> /etc/php/7.4/cli/php.ini
```

After reviewing the pipeline for errors, correcting them by updating the jenkinsfile, the unit test also ran successfully:

[unit test successful]

[unit test successful 2]

The jenkinsfile can be found in the [repo](https://github.com/laraadeboye/php-todo-app/blob/feature/integrate-jenkins-articatory/Jenkinsfile)


Create a pull request and merge it to the main branch.



*Hint*
It is important to clone the repository and run the app locally in order to discover any dependencies that may be needed for the app to run. The dependencies of the project are located in the `composer.json` file

```

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```


**Phase 3** : Code Quality Analysis:
After the successful run of the unit test we can move on to the next phase - code quality analysis. The most commonly used code quality analysis tool for php apps is phploc. PHPLOC (PHP Lines Of Code) is a tool for measuring the size and complexity of PHP projects. The output of the data will be saved in the `/build/logs/phploc.csv` file.

1. We will add the code analysis stage :

```
stage ('Code Analysis') {
            steps {
                sh 'phploc app/ --log-csv build/logs/phploc.csv'                
            }
        } 
```


[Console out put of code analysis using phploc]

[content of the phploc.csv]


2. We will plot the data obtained by using the `plot` jenkins plugin . The plot plugin provides graphing capabilities in jenkins. Plot can be used to track different types of metrics such as build logs, software performance, code quality metrics. You can use several types of graphs including line graphs, bar charts, area charts.

We will define the next stage that measures some quality metrics for our job:

```
stage ('Plot Code Coverage report') {
            steps {
                // Plot phploc metrics
                plot csvFileName: 'phploc.csv', 
                         group: 'Code Metrics', 
                         title: 'PHP Lines of Code', 
                         exclusionValues: Lines of Code (LOC), Logical Lines of Code (LLOC),
                         style: 'line',
                         csvSeries: [
                             [
                                 file: 'build/logs/phploc.csv', 
                                 inclusionFlag: 'OFF', 
                                 url: ''
                             ]
                         ]
                    
                    // Plot code coverage
                    plot csvFileName: 'coverage.csv', 
                         group: 'Code Coverage', 
                         title: 'Test Coverage', 
                         style: 'bar',
                         csvSeries: [
                             [
                                 file: 'build/logs/clover.xml', 
                                 inclusionFlag: 'OFF', 
                                 url: ''
                             ]
                         ]
                }
            }                
            
```


This Jenkins pipeline stage plots two types of reports:
1. Code Metrics Report: This report uses the phploc tool to display metrics about the PHP codebase, such as:
  - Lines of Code (LOC)
  - Logical Lines of Code (LLOC)

2. Code Coverage Report: This report uses the clover.xml file to display the test coverage of the codebase.


- Next locate the plot icon on the jenkins UI to view the trends
[locate the plot icon]
[plot group]
[code metrics.lines of code]
[plot with more builds]

*Troubleshooting*
- Ensure the plot plugin is installed
- When you first include this step and run the build, the first build may not show the build trend.

Updating the code coverage report, we can further modify it to display a more granular and detailed report as seen in the [jenkinsfile](https://github.com/laraadeboye/php-todo-app/blob/feature/integrate-jenkins-artifactory/Jenkinsfile) in my github repo.


For a summarized code report check my self-side study [here](https://github.com/laraadeboye/Steghub-Devops-Cloud-Engineer/blob/main/CI-WITH-ANSIBLE-SOME-DEVOPS-TOOLS/self-side-study/phploc%20with%20plot%20plugin)


[Plot with more builds (2)]

On main branch
[Plot on main branch]


- Next we will include stages to Package the code into and Artifact and upload to artifactory.

```
stage('Package Artifact') {
            steps {
                sh 'zip -qr php-todo.zip ${WORKSPACE}/*'                
            }
        } 
stage('Upload Artifact to Artifactory') {
            steps {
                script {
                    def server = artifactory.server 'artifactory-server'
                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "php-todo.zip",
                                "target": "<name-of-artifact-repo>/php-todo",
                                "props": "type=zip;status=ready"
                            }
                        ]
                    }
                    """
            

                }
                               
            }
        }
```
Replace the <name-of-artifact-repo> with the name of the artifactory repo you created on j-frog artifactory for the app.

[upload to artifactory server success]

[php-todo in artifactory repo]

*Troubleshooting*
Error (as seen in my console output jenkins):
```
at java.base/java.lang.Thread.run(Thread.java:840)
Caused by: java.io.IOException: JFrog service failed. Received 413: <html>
<head><title>413 Request Entity Too Large</title></head>
<body>
<center><h1>413 Request Entity Too Large</h1></center>
<hr><center>nginx/1.24.0 (Ubuntu)</center>
</body>
</html>
```
- This indicates that the zipped artifact is too large for the server to upload. I solved this by including a  `client_max_body_size 100M;` directive in my nginx configuration file.


- Next, we need to deploy the application to the `dev` environment by launching ansible pipeline. We will include another stage to accomplish this.


```
stage('Deploy to Dev environment') {
            steps {
                build job: 'ansible-config-mgt/main', parameters: [
                    [
                        $class: 'StringParameterValue', name: 'env', value: 'dev'
                    ]
                ], propagate:false, wait:true
                                
            }
        } 
```

This stage triggers another job (using the `build job`)  named `ansible-config-mgt/main`. It passes a parameter named `env` with the value `dev` to the triggered job. The `propagate: false` option means that if the triggered job fails, it won't fail the current pipeline.
The `wait: true` option means that the pipeline will wait for the triggered job to complete before proceeding.

Ensure that the following are done to configure the Dev todo-app webserver for deployment:

- Create an rhel ec2 instance for the development todo webserver named `DEV-todo-webapp`. 
- Included it's private IP in the dev environment inventory file.
  [update dev.yml with todo ip2]
- Configure nginx-reverse proxy to route traffic to the server with SSL using certbox and create an A record in your domain management system named `todo.dev.laraadeboye.com`. Ensure to create it with your specific domain name. 
- Prepare the webserver to serve our todo app. Use ansible tasks to automate it. I create a playbook named `php-todo-app.yml` in the static-assignments folder and imported it into our `playbook/site.yml`
- Edit your ansible-config-mgt pipeline to point to the correct playbook for your dev deployment
[edit the ansible-config pipeline to point to]
- Also ensure the correct parameters are specified. I specified my inventory parameter as `dev.yml` and the tags as `todo`
[specify correct parameters]

[deploy to dev succesful]

*Troubleshooting*
- Ensure your ansible tasks correctly deploys the artifact to the correct environment without errors.
- Ensure your jenkins nodes has the correct number of executors to support the build. Navigate to manage jenkins > nodes > configure (Increase number of executors to 2)

Increasing the number of executors allow multiple jobs to be run simultaneously, thereby reducing execution time and also helps to adequately leverage the server resources. Your number of executors should not exceed the number of cpus you have

Merge the changes to the main barnch and ensure the pipeline still runs successfully.

[deploy to dev main successful]

## Step 4 Implement Quality Gate with sonarqube

Software quality is the extents to which a software component meets specified requirements based on user needs and expectations while software quality gates are predefined acceptance criteria that a software development project must meet in order to proceed from one stage of its lifecycle to the next.

To ensure that the deployed code has the quality that meets corporate and customer requirements, we need to implement quality gate with sonarqube- an opensource software that is used for continuous inspection of code quality.

We will automate the installation of sonarqube on our previously configured sonarqube instance in the ci environment: `sonar.infradev.laraadeboye.com` with ansible.

Later, using ansible we will create a role that installs sonarqube with postgresql as the backend database.

Now, it will be done manually,

First create the sonarqube EC2 instance preferably with `t2.medium`. Allow inboud traffic on sonarqube default port `9000`

We will install sonarqube 9.9 version which is currently the latest version (Dec 2024). It has a prerequisite for java

Make some linux kernel configuration changes to ensure optimal performance of the tool by increasing `vm.max_map_count`, `file descriptor` and `ulimit`

- Tune the linux kernel:
We will make the following changes which does not persist beyond the current session terminal:
```sh
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
```


Make it permanent by editting the `/etc/security/limits.conf
```sh
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
```
[set security limits]

- Install prerequisites:

**Install JAVA and unzip**

```sh
# Update apt packages
sudo apt-get update
sudo apt-get upgrade

# Install wget and unzip packages
sudo apt-get install wget unzip -y

# Install OpenJDK and Java Runtime Environment (JRE) 11
sudo apt-get install openjdk-17-jdk -y
sudo apt-get install openjdk-17-jre -y

# Set default JDK
sudo update-alternatives --config java

# Verify java version
java -version
```
[java installed and set]


**Install and Setup postgresql 10 for Sonarqube**

```sh
# Add Postgresql repo to the repo list
 sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'

# Download Postgresql software
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

# Install the Postgresql databases server:
sudo apt-get -y install postgresql postgresql-contrib

# Start Postgresql server
sudo systemctl start postgresql

# Enable Postgresql to start automatically on reboot
sudo systemctl enable postgresql

# Check Postgresql status
sudo systemctl status postgresql
```
[check postgresql status]


** Configure Postgresql**
```sh
# Change password for default postgres user. Pass in your intended password (Passw0rd123#)
sudo passwd postgres

# switch to postgres user
su - postgres

# Create new user
createuser sonar

# switch to posgreql shell
psql

# set a password for the newly created postgresql user 

ALTER USER sonar WITH ENCRYPTED password 'sonar';

# Create a new database for PostgreSQL database by running:
CREATE DATABASE sonarqube OWNER sonar;

# Grant all privileges to sonar user on sonarqube Database.
grant all privileges on DATABASE sonarqube to sonar;

#Exit from the psql shell:
\q

# Switch to root user:
exit
```
[Configure postgresql]

**Install Sonarqube on Ubuntu 24.04.LTS**

You can find the opensource distributions [here](https://binaries.sonarsource.com/?prefix=Distribution/sonarqube/)


```sh
# Navigate to the /tmp directory and download the installation files
cd /tmp && sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.8.100196.zip

# unzip the archive to the /opt directory
sudo unzip sonarqube-9.9.8.100196.zip -d /opt

# Rename extracted setup to /opt/sonarqube directory
sudo mv /opt/sonarqube-9.9.8.100196 /opt/sonarqube
```

**Configure Sonarqube**
Sonarqube cannot be run as root user. Hence, we will create a group and user to run sonarqube

```sh
# Create a group sonar
sudo groupadd sonar

# Now add a user with control over the /opt/sonarqube directory
sudo useradd -c "user to run SonarQube" -d /opt/sonarqube -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube -R

# Open SonarQube configuration file using your favourite text editor (e.g., nano or vim)
sudo vim /opt/sonarqube/conf/sonar.properties

# Find the following: (Make sure to uncomment them and add the username and password of the postgresql database )
#sonar.jdbc.username=
#sonar.jdbc.password=
#sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

# Edit the sonar script file and set it a
sudo vi /opt/sonarqube/bin/linux-x86-64/sonar.sh

#Paste the following under the APP_NAME
RUN_AS_USER=sonar

```


** Start Sonarqube**

```sh
# Switch to sonar user
sudo su sonar

# Move to the script directory
cd /opt/sonarqube/bin/linux-x86-64/

# Run the script to start sonarqube
./sonar.sh start


# Run the script to check sonarqube status
./sonar.sh status

# To check SonarQube logs, navigate to /opt/sonarqube/logs/sonar.log directory
tail /opt/sonarqube/logs/sonar.log
```
[sonar running]

[sonarqube is running on browser]

** Configure sonarqube as a systemd service**
```sh
# Stop the currently running SonarQube service
cd /opt/sonarqube/bin/linux-x86-64/
./sonar.sh stop

# exit the session
exit

# Create a systemd service file for SonarQube to run as System Startup.
sudo vi /etc/systemd/system/sonar.service

# Add the following configuration:
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target

# Save the file and exit
:wq

# Control the service with systemctl
sudo systemctl start sonar
sudo systemctl enable sonar
sudo systemctl status sonar

```
[sonarqube systemd running]


** Additional configurations**

```sh
# Visit sonarqube config file and uncomment the line of sonar.web.port=9000
sudo vi /opt/sonarqube/conf/sonar.properties
```

**Access sonarquube on the public IP of your server**

```sh
http://[Public-IP]:9000
```

Having configured our sonar server previously with nginx reverse proxy and SSL, I can access it via the URL

```
https://sonar.infradev.laraadeboye.com
```
[sonarqube on proxied url]

**Access Sonarqube**
Login to Sonarqube with the default username and password (admin, admin)

You will be propmted to create a new password. I am still using `Passw0rd123#` for our development environment

[sonar ui after login]

## Step 5 Configure Sonarqube and Jenkins for Quality Gate

- Generate authentication token in Sonarqube.

```
User > My Account > Security > Generate Tokens
```
[sonar token]

- Install `SonarQube  Scanner `plugin in Jenkins UI

```
Dashboard > manage jenkins > Available Plugins (Search for SonarQube  Scanner )
```
[sonarqube scanner]

[Add the generated token]

[choose the sonar token]
- Configure sonarqube in jenkins UI

```
Manage jenkins > Configure System > Sonarqube servers
```
[sonarqube server configuration]

- In Sonarqube UI, Configure Quality Gate Jenkins Webhook. The URL should point to the jenkins server `http://{JENKINSIP:8080}/sonarqube-webhook/`.
I pointed it to my jenkins url `https://ci.infradev.laraadeboye.com/sonarqube-webhook/`

```
Administration > Configuration > Webhooks > Create

```

[Quality gate jenkins webhook]

- Update the Jenkins Pipeline to include Sonarqube scanning and Quality Gate:

```
stage('SonarQube Quality Gate') {
        environment {
            scannerHome = tool 'SonarQubeScanner'
        }
        steps {
            withSonarQubeEnv('sonarqube') {
                sh "${scannerHome}/bin/sonar-scanner"
            }

        }
    }

```
This stage defines the pipeline stage named "SonarQube Quality Gate".
`stage('SonarQube Quality Gate')` It also defines the environment block `environment { ... }` which sets environment variables for the stage.
`scannerHome = tool 'SonarQubeScanner'` sets the scannerHome environment variable to the home directory of the SonarQube Scanner tool, which is configured in the Jenkins global tool configuration.

The steps `steps { ... }` block defines the steps to be executed within the stage.
- `withSonarQubeEnv('sonarqube') { ... }`: This step sets up the SonarQube environment variables, using the sonarqube server configuration, which is defined in the Jenkins global configuration.

- `sh "${scannerHome}/bin/sonar-scanner"`: This executes the SonarQube Scanner command-line tool, which analyzes the code and sends the results to the SonarQube server.



After running this build this step fails, because we have not configured the tool sonarQube scanner and `sonar-scanner.properties` in the jenkins server

[sonarqube scanner not found]

- Configure `SonarQubeScanner` tool:
```
Manage jenkins > Tools > Add SonarQube scanner 
```
[sonar tool config]
Choose install automatically, maintaining the most resent version


[sonar scanner properties error]

- Configure `sonar-scanner.properties` :
The tool directory in the jenkins home, will not be visible unless a tool has been installed and a pipeline has been run to use it.

Jenkins installs scanner tool on the Linux server. Navigate to the tools directory on the server to configure the `properties` file which is required by SonarQube to function during the pipeline execution

```
cd /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/SonarQubeScanner/conf
```
[tool location on jenkins server]

[sonar-scanner location]

[in the conf dir]
Open the `sonar.properties` file:

```sh
sudo vi sonar-scanner.properties
```
To add details to the sonar.properties file specific to the project, the appropriate settings can be found in the sonarqube console. Navigate to Administration > Configuration > Language (Choose the specific language)
[Php settings for sonarproperties1]
[Php settings for sonarproperties2]

Add the following configuration which is related to the `php-todo` project

```
sonar.host.url=http://<SonarQube-Server-IP-address>:9000
sonar.projectKey=php-todo
#----- Default source code encoding
sonar.sourceEncoding=UTF-8
sonar.php.exclusions=**/vendor/**
sonar.php.coverage.reportPaths=build/logs/clover.xml
sonar.php.tests.reportPath=build/logs/junit.xml
```
[sonar properties config]

[sonar build sucess]

Scroll down the build report, you will find the link to the scan analysis.
[scroll and find analysis report]

[sonar report]

[sonarqube ui project report]

Note that code snippets for the jenkinsfile can be obtained using the pipeline syntax generator on the jenkins UI. More details about using sonarqube can be found [here](https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/scanners/jenkins-extension-sonarqube/).


Since the build was successful on the feature branch, we will create a pull request and merge the code to main. After running the build on the main branch, we see that it passed.
[build passed on main 1]
[build passed on main 2]


## Step 6 Conditional Deployment to higher environments

Assuming a gitflow strategy requires only the develop branch to deploy code to the sit environment, the Jenkinsfile can be updated as follows:

- We will include a `when` condition to run quality gate whenever the running branch is `develop`, `hotfix`, `release` or `main`

```
when { branch pattern: "^develop*|^hotfix*|^release*|^main*", comparator: "REGEXP"}
```
- Then we add a timeout step to wait for sonarQube to complete the analysis and finish the pipeline only when the code quality is acceptable.

```
timeout(time: 1, unit: 'MINUTES') {
        waitForQualityGate abortPipeline: true
    }
```

- Here is the stage to address this changes:

```
stage('SonarQube Quality Gate') {
      when { branch pattern: "^develop*|^hotfix*|^release*|^main*", comparator: "REGEXP"}
        environment {
            scannerHome = tool 'SonarQubeScanner'
        }
        steps {
            withSonarQubeEnv('sonarqube') {
                sh "${scannerHome}/bin/sonar-scanner -Dproject.settings=sonar-project.properties"
            }
            timeout(time: 1, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
            }
        }
    }
```

To test this, we will create  the branches, `develop`, `hotfix`, `release `

We will notice that the code cannot be deployed to the SIT environment based on the quality. In the real world scenerio, DevOPs team will send the code back to the developers to further work on it.



## Step 7 Introduction of Jenkins Agents/ Slaves
The existing Jenkins server is a `t3.medium` server. it will serve as the Jenkins master. The agent servers need to be of the same specifications

- Create two `t3.medium` ubuntu servers on AWS to serve as jenkins agents. Security group settings on each server should allow inbound traffic from the Jenkins master on port `22`. I created a security group named `jenkins_agent_sg` which allows inbound traffic on port `22` from the jenkins master private IP. To connect with instance connect, I also configured it to allow inbound traffic from the instance connect IP range.

[jenkins agents running]

[security group settings jenkins slave]

- Configure SSH access.
On Jenkins master, you can either generate ssh key by following the steps:

```sh
ssh-keygen -t rsa -b 4096
```

Copy the public key to each agents

```
ssh-copy-id jenkins@<agent-server-ip>
```

I used the same ssh key I have been using `stapleskey.pem` to simplify key management. To ensure authentication to the new agent servers, I will securely copy my private key to my jenkins master server.


```sh
# Securely copy the private key to Jenkins master
scp /path/to/your/downloaded/key.pem ubuntu@jenkins-master-ip:/tmp

```
SSH into the agent servers and move the key to the jenkins .ssh/ directory:

```sh
# Move the key to the Jenkins directory
sudo mv /tmp/stapleskey.pem /var/lib/jenkins/.ssh/stapleskey
```

- Ensure the permissions are appropriate

```sh
# Set appropriate permissions for the .ssh directory
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh

# Set appropriate permissions for the private key
sudo chmod 400 /var/lib/jenkins/.ssh/stapleskey
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh/stapleskey
```


- Verify that the private key is on the Jenkins master

```
siudo ls -l /var/lib/jenkins/.ssh/stapleskey

```
- Verify that the public key is in the `~/.ssh/authorized_keys` file on each agent

```
cat ~/.ssh/authorized_keys

```

- Test SSH from the Jenkins master to each agent (Replace `stapleskey` with the specific name of your private key):

```sh
ssh -i /var/lib/jenkins/.ssh/stapleskey ubuntu@<agent-private-ip>

```

- You should also add the agents keys to to the `known_hosts` file of the jenkins master:

```sh
sudo -u jenkins ssh-keyscan -H <agent-private-ip> >> /var/lib/jenkins/.ssh/known_hosts

```

Test the connectivity of the jenkins-master to the agent server using the jenkins user:

```
sudo -u jenkins ssh -i /var/lib/jenkins/.ssh/stapleskey ubuntu@<agent-ip>

```
**Create jenkins user  and group on agents**
On each agent, create a jenkins user with consistent configuration:
```sh
# Create jenkins user
# -m: Create home directory
# -s /bin/bash: Set bash as the login shell
sudo useradd -m -s /bin/bash jenkins

# Create jenkins group
sudo groupadd jenkins

# Add jenkins user to jenkins group
sudo usermod -aG jenkins jenkins
```

*Troubleshooting*
if you get the error below on your local system when transferring the key, simply add your private key to the ssh-agent using `ssh-add <path-to-private-key>`

```
Permission denied (publickey).
scp: Connection closed
```


Now that SSH is set up.
- SSH into each of the two agent servers and Install java and ansible 
The version we are using on the master is Java 17

Install Java
```
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

Install ansible

```
# Update apt repository
sudo apt update -y

# Install dependencies
sudo apt install -y software-properties-common

# Update repositories
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install ansible
sudo apt install -y ansible

# Verify installation
ansible --version

```

[java and ansible version]

**Agent nodes configuration**

In Jenkins Web Interface:
- Navigate to "Manage Jenkins" > "Nodes"
- Click "New Node"
- Set a unique name for each agent
- Choose "Permanent Agent"

Configure:

- Remote root directory (e.g., /home/jenkins/jenkins-agent). Create this directory in each jenkins agent server. 
(`mkdir -p /home/jenkins/jenkins-agent`)

  ```sh
    # Create the jenkins-agent directory
    sudo mkdir -p /home/jenkins/jenkins-agent

    # Set appropriate permissions
    sudo chmod 755 /home/jenkins/jenkins-agent

    #Set ownership
    sudo chown -R jenkins:jenkins /home/jenkins/jenkins-agent

    # Verify the existence of the directory
    ls -ld /home/jenkins/jenkins-agent

  ```

  [create remote agent home]
- Launch method: "Launch agents via SSH"
- Host: IP of the agent server (Private IP of the agent server)
-Credentials: Add SSH credentials from the key generated. Ensure the username of the credential is set to the username of the server (`ubuntu`). Also the private key is the `stapleskey`.Copy and paste it to the provided space


[configure nodes 0]
[configure nodes]
[Click on the node configure]

Click on "Launch agent"

**jenkins master node configuration**
Navigate to manage jenkins > Nodes > Builtin node

Set the number of executors on controller node to `0` to ensure that the jenkins uses the nodes for execution of jobs

[Master node configuration]

[Agent_1 Connected]
[Nodes available]

We will run the job to enable us verify that any of the nodes will be used for the build
