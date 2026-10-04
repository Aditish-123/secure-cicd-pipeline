pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    environment {
        DOCKER_USER = 'aditi1166'

        AWS_DEFAULT_REGION = 'eu-north-1'
        EC2_INSTANCE_ID = 'i-0f484796d1bab5c3f'
        EC2_HOST = 'ec2-51-20-7-125.eu-north-1.compute.amazonaws.com'

        PYTHON_EXE = 'C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe'
        AWS_CLI = 'C:/Program Files/Amazon/AWSCLIV2/aws.exe'

        PYTHON_IMAGE = 'aditi1166/secure-cicd-app:latest'
        NODE_IMAGE = 'aditi1166/secure-cicd-node-app:latest'
        JAVA_IMAGE = 'aditi1166/secure-cicd-java-app:latest'
    }

    stages {

        stage('Detect Application') {
            steps {
                script {
                    def changedFiles = bat(
                        script: '''
                        @echo off
                        git diff --name-only HEAD~1 HEAD
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Changed files:"
                    echo changedFiles

                    if (changedFiles.contains('node-demo/')) {
                        env.APP_TYPE = 'node'
                        echo "Node.js application detected."

                    } else if (changedFiles.contains('java-demo/')) {
                        env.APP_TYPE = 'java'
                        echo "Java application detected."

                    } else if (changedFiles.contains('python-demo/')) {
                        env.APP_TYPE = 'python'
                        echo "Python application detected."

                    } else if (changedFiles == 'Jenkinsfile') {
                        env.APP_TYPE = 'python'
                        echo "Only Jenkinsfile changed."
                        echo "Using Python application for pipeline validation."

                    } else {
                        if (fileExists('node-demo/package.json')) {
                            env.APP_TYPE = 'node'
                        } else if (fileExists('python-demo/requirements.txt')) {
                            env.APP_TYPE = 'python'
                        } else if (fileExists('java-demo/pom.xml')) {
                            env.APP_TYPE = 'java'
                        } else {
                            error "Unable to detect supported application."
                        }
                    }

                    echo "Detected application: ${env.APP_TYPE}"
                }
            }
        }

        stage('Validate') {
            steps {
                script {
                    if (env.APP_TYPE == 'python') {

                        if (!fileExists('python-demo/requirements.txt')) {
                            error "Python requirements.txt not found."
                        }

                    } else if (env.APP_TYPE == 'node') {

                        if (!fileExists('node-demo/package.json')) {
                            error "Node.js package.json not found."
                        }

                    } else if (env.APP_TYPE == 'java') {

                        if (!fileExists('java-demo/pom.xml')) {
                            error "Java pom.xml not found."
                        }

                    } else {
                        error "Unsupported application type."
                    }

                    echo "Application validation successful."
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {

                        bat """
                        cd python-demo
                        "${PYTHON_EXE}" -m pip install -r requirements.txt
                        """

                    } else if (env.APP_TYPE == 'node') {

                        bat """
                        cd node-demo
                        npm install
                        """

                    } else if (env.APP_TYPE == 'java') {

                        bat """
                        cd java-demo
                        mvn clean compile
                        """
                    }
                }
            }
        }

        stage('Test') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {

                        bat """
                        cd python-demo
                        "${PYTHON_EXE}" -m pytest
                        """

                    } else if (env.APP_TYPE == 'node') {

                        bat """
                        cd node-demo
                        npm test
                        """

                    } else if (env.APP_TYPE == 'java') {

                        bat """
                        cd java-demo
                        mvn test
                        """
                    }
                }
            }
        }

        stage('Build Application') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {

                        echo "Python application does not require a separate compilation step."

                    } else if (env.APP_TYPE == 'node') {

                        echo "Node.js application does not require a separate compilation step."

                    } else if (env.APP_TYPE == 'java') {

                        bat """
                        cd java-demo
                        mvn clean package -DskipTests
                        """
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {

                        bat """
                        cd python-demo
                        docker build -t ${PYTHON_IMAGE} .
                        """

                    } else if (env.APP_TYPE == 'node') {

                        bat """
                        cd node-demo
                        docker build -t ${NODE_IMAGE} .
                        """

                    } else if (env.APP_TYPE == 'java') {

                        bat """
                        cd java-demo
                        docker build -t ${JAVA_IMAGE} .
                        """
                    }
                }
            }
        }

        stage('Security Gate') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {

                        bat """
                        powershell -ExecutionPolicy Bypass -File security-gate.ps1 ${PYTHON_IMAGE}
                        """

                    } else if (env.APP_TYPE == 'node') {

                        bat """
                        powershell -ExecutionPolicy Bypass -File security-gate.ps1 ${NODE_IMAGE}
                        """

                    } else if (env.APP_TYPE == 'java') {

                        bat """
                        powershell -ExecutionPolicy Bypass -File security-gate.ps1 ${JAVA_IMAGE}
                        """
                    }
                }
            }
        }

        /*
         * Docker Hub Login
         *
         * Using the same working login approach that was previously
         * successful in this project.
         */
        stage('Docker Hub Login') {
            steps {
                script {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials',
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )
                    ]) {

                        bat '''
                        echo Logging in to Docker Hub...

                        docker login -u "%DOCKER_USERNAME%" -p "%DOCKER_PASSWORD%"

                        if %ERRORLEVEL% NEQ 0 (
                            echo Docker Hub authentication failed.
                            exit /b 1
                        )

                        echo Docker Hub login successful.
                        '''
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {

                        bat """
                        docker push ${PYTHON_IMAGE}
                        """

                    } else if (env.APP_TYPE == 'node') {

                        bat """
                        docker push ${NODE_IMAGE}
                        """

                    } else if (env.APP_TYPE == 'java') {

                        bat """
                        docker push ${JAVA_IMAGE}
                        """
                    }
                }
            }
        }

        stage('SSM Connection Test') {
            steps {
                script {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-ssm-credentials',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                    ]) {

                        bat """
                        "${AWS_CLI}" sts get-caller-identity
                        """

                        bat """
                        "${AWS_CLI}" ssm describe-instance-information ^
                            --region ${AWS_DEFAULT_REGION}
                        """
                    }
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {

                    def imageName = ''

                    if (env.APP_TYPE == 'python') {

                        imageName = env.PYTHON_IMAGE

                    } else if (env.APP_TYPE == 'node') {

                        imageName = env.NODE_IMAGE

                    } else if (env.APP_TYPE == 'java') {

                        imageName = env.JAVA_IMAGE
                    }

                    def containerName = "${env.APP_TYPE}-secure-cicd-app"

                    def hostPort = ''
                    def containerPort = ''

                    if (env.APP_TYPE == 'python') {

                        hostPort = '5000'
                        containerPort = '5000'

                    } else if (env.APP_TYPE == 'node') {

                        hostPort = '3000'
                        containerPort = '3000'

                    } else if (env.APP_TYPE == 'java') {

                        hostPort = '8081'
                        containerPort = '8080'
                    }

                    def commands = """
docker pull ${imageName}
docker stop ${containerName} || true
docker rm ${containerName} || true
docker run -d --name ${containerName} -p ${hostPort}:${containerPort} ${imageName}
"""

                    def escapedCommands = commands
                        .trim()
                        .replace('\\', '\\\\')
                        .replace('"', '\\"')
                        .replace('\r\n', '\\n')
                        .replace('\n', '\\n')

                    writeFile(
                        file: 'ssm-commands.json',
                        text: '{"Parameters":{"commands":["' + escapedCommands + '"]}}'
                    )

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-ssm-credentials',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                    ]) {

                        bat """
                        "${AWS_CLI}" ssm send-command ^
                            --instance-ids ${EC2_INSTANCE_ID} ^
                            --document-name "AWS-RunShellScript" ^
                            --parameters file://ssm-commands.json ^
                            --region ${AWS_DEFAULT_REGION}
                        """
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {

                    def healthUrl = ''

                    if (env.APP_TYPE == 'python') {

                        healthUrl = "http://${EC2_HOST}:5000/health"

                    } else if (env.APP_TYPE == 'node') {

                        healthUrl = "http://${EC2_HOST}:3000/health"

                    } else if (env.APP_TYPE == 'java') {

                        healthUrl = "http://${EC2_HOST}:8081/health"
                    }

                    echo "Checking application health..."
                    echo "Health URL: ${healthUrl}"

                    bat """
                    powershell -Command ^
                    "\\$response = Invoke-WebRequest -Uri '${healthUrl}' -UseBasicParsing; ^
                    Write-Host 'HTTP Status:' \\$response.StatusCode; ^
                    Write-Host 'Response:' \\$response.Content; ^
                    if (\\$response.StatusCode -ne 200) { exit 1 }"
                    """
                }
            }
        }
    }

    post {

        success {
            echo """
============================================
CI/CD PIPELINE SUCCESSFUL
============================================
Application: ${env.APP_TYPE}

Pipeline completed:
GitHub
   ↓
Application Detection
   ↓
Dependencies
   ↓
Tests
   ↓
Application Build
   ↓
Docker Build
   ↓
Trivy Security Gate
   ↓
Docker Hub
   ↓
AWS SSM
   ↓
EC2 Deployment
   ↓
Health Check
============================================
"""
        }

        failure {
            echo """
============================================
CI/CD PIPELINE FAILED
============================================
Application: ${env.APP_TYPE}
Please check the failed stage in Jenkins.
============================================
"""
        }

        always {
            echo "Pipeline execution completed."
        }
    }
}
