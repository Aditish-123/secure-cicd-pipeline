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
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws-ssm-credentials']
                    ]) {

                        echo "Testing AWS credentials..."

                        bat """
                        "${AWS_CLI}" sts get-caller-identity
                        """

                        echo "Testing AWS Systems Manager access..."

                        bat """
                        "${AWS_CLI}" ssm describe-instance-information ^
                            --region ${AWS_DEFAULT_REGION}
                        """

                        echo "AWS SSM connection successful."
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


                    echo "============================================"
                    echo "Preparing EC2 Deployment"
                    echo "============================================"
                    echo "Application: ${env.APP_TYPE}"
                    echo "Docker image: ${imageName}"
                    echo "Container: ${containerName}"
                    echo "Port mapping: ${hostPort}:${containerPort}"
                    echo "============================================"


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


                    /*
                     * AWS SSM expects:
                     *
                     * {
                     *   "commands": [
                     *      "command1\\ncommand2"
                     *   ]
                     * }
                     *
                     * Do NOT add another "Parameters" wrapper.
                     */

                    writeFile(
                        file: 'ssm-commands.json',
                        text: '{"commands":["' + escapedCommands + '"]}'
                    )


                    echo "SSM command parameters prepared."


                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws-ssm-credentials']
                    ]) {


                        echo "Sending deployment command to EC2 through AWS SSM..."


                        /*
                         * Send command and capture CommandId.
                         */

                        def commandId = bat(
                            script: """
                            "${AWS_CLI}" ssm send-command ^
                                --instance-ids ${EC2_INSTANCE_ID} ^
                                --document-name "AWS-RunShellScript" ^
                                --parameters file://ssm-commands.json ^
                                --region ${AWS_DEFAULT_REGION} ^
                                --query "Command.CommandId" ^
                                --output text
                            """,
                            returnStdout: true
                        ).trim()


                        /*
                         * Jenkins bat output may contain multiple lines.
                         * Take the final non-empty line as CommandId.
                         */

                        def commandLines = commandId
                            .split('\r?\n')
                            .findAll { it.trim() }

                        commandId = commandLines[-1].trim()


                        if (!commandId || commandId == 'None') {

                            error "AWS SSM did not return a valid CommandId."
                        }


                        env.SSM_COMMAND_ID = commandId


                        echo "SSM Command ID: ${commandId}"
                        echo "Waiting for EC2 deployment to complete..."


                        def finalStatus = 'Pending'


                        /*
                         * Poll SSM every 5 seconds.
                         * Maximum 30 attempts = 150 seconds.
                         */

                        for (int attempt = 1; attempt <= 30; attempt++) {

                            sleep(
                                time: 5,
                                unit: 'SECONDS'
                            )


                            def statusOutput = bat(
                                script: """
                                "${AWS_CLI}" ssm get-command-invocation ^
                                    --command-id ${commandId} ^
                                    --instance-id ${EC2_INSTANCE_ID} ^
                                    --region ${AWS_DEFAULT_REGION} ^
                                    --query "Status" ^
                                    --output text
                                """,
                                returnStdout: true
                            ).trim()


                            def statusLines = statusOutput
                                .split('\r?\n')
                                .findAll { it.trim() }


                            if (statusLines) {
                                finalStatus = statusLines[-1].trim()
                            }


                            echo "SSM deployment status: ${finalStatus}"


                            if (finalStatus == 'Success') {

                                echo "============================================"
                                echo "EC2 DEPLOYMENT SUCCESSFUL"
                                echo "============================================"

                                break
                            }


                            if (
                                finalStatus == 'Failed' ||
                                finalStatus == 'Cancelled' ||
                                finalStatus == 'TimedOut' ||
                                finalStatus == 'Cancelling'
                            ) {


                                echo "EC2 deployment failed."


                                def errorOutput = bat(
                                    script: """
                                    "${AWS_CLI}" ssm get-command-invocation ^
                                        --command-id ${commandId} ^
                                        --instance-id ${EC2_INSTANCE_ID} ^
                                        --region ${AWS_DEFAULT_REGION} ^
                                        --query "StandardErrorContent" ^
                                        --output text
                                    """,
                                    returnStdout: true
                                ).trim()


                                echo "============================================"
                                echo "EC2 DEPLOYMENT ERROR"
                                echo "============================================"
                                echo errorOutput
                                echo "============================================"


                                error(
                                    "EC2 deployment failed. SSM status: ${finalStatus}"
                                )
                            }
                        }


                        if (finalStatus != 'Success') {

                            error(
                                "EC2 deployment timed out. Final SSM status: ${finalStatus}"
                            )
                        }
                    }
                }
            }
        }


        stage('Health Check') {
            steps {
                script {

                    def healthUrl = ''


                    if (env.APP_TYPE == 'python') {

                        healthUrl =
                            "http://${EC2_HOST}:5000/health"

                    } else if (env.APP_TYPE == 'node') {

                        healthUrl =
                            "http://${EC2_HOST}:3000/health"

                    } else if (env.APP_TYPE == 'java') {

                        healthUrl =
                            "http://${EC2_HOST}:8081/health"
                    }


                    echo "============================================"
                    echo "APPLICATION HEALTH CHECK"
                    echo "============================================"
                    echo "Health URL: ${healthUrl}"


                    /*
                     * IMPORTANT:
                     * Use single-quoted Groovy string for the PowerShell
                     * command so Jenkins does not try to interpret
                     * PowerShell variables such as $response.
                     */

                    def healthResult = bat(
                        script: """
                        powershell -NoProfile -Command ^
                        "try { ^
                            \\\$response = Invoke-WebRequest -Uri '${healthUrl}' -UseBasicParsing -TimeoutSec 15; ^
                            Write-Host 'HTTP Status:' \\\$response.StatusCode; ^
                            Write-Host 'Response:' \\\$response.Content; ^
                            if (\\\$response.StatusCode -ne 200) { exit 1 } ^
                        } catch { ^
                            Write-Host 'Health check failed:' \\\$_.Exception.Message; ^
                            exit 1 ^
                        }"
                        """,
                        returnStatus: true
                    )


                    if (healthResult != 0) {

                        error(
                            "Application health check failed."
                        )
                    }


                    echo "============================================"
                    echo "APPLICATION IS HEALTHY"
                    echo "HTTP 200 received from application."
                    echo "============================================"
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
Validation
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
   ↓
APPLICATION LIVE

============================================
"""

        }


        failure {

            echo """
============================================
CI/CD PIPELINE FAILED
============================================

Application: ${env.APP_TYPE}

Failed stage should be visible above
in the Jenkins console output.

============================================
"""
        }


        always {

            echo "Pipeline execution completed."
        }
    }
}
