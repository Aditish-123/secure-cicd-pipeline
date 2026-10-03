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
    }

    stages {

        stage('Detect Application') {
            steps {
                script {

                    def changedFiles = ''

                    try {
                        changedFiles = bat(
                            script: '''
                                @echo off
                                git diff --name-only HEAD~1 HEAD
                            ''',
                            returnStdout: true
                        ).trim()
                    } catch (Exception e) {
                        echo 'Could not determine changed files from previous commit.'
                    }

                    echo 'Changed files:'
                    echo changedFiles

                    /*
                     * Primary detection:
                     * Detect application from files changed
                     * in the latest commit.
                     */

                    if (changedFiles.contains('python-demo/')) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.DOCKER_IMAGE = 'secure-cicd-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-app'
                        env.APP_PORT = '5000'
                        env.CONTAINER_PORT = '5000'

                    } else if (changedFiles.contains('node-demo/')) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.DOCKER_IMAGE = 'secure-cicd-node-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-node-app'
                        env.APP_PORT = '3000'
                        env.CONTAINER_PORT = '3000'

                    } else if (changedFiles.contains('java-demo/')) {

                        env.DETECTED_LANGUAGE = 'java'
                        env.DOCKER_IMAGE = 'secure-cicd-java-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-java-app'
                        env.APP_PORT = '8081'
                        env.CONTAINER_PORT = '8080'

                    } else if (changedFiles.contains('Jenkinsfile')) {

                        echo 'Only Jenkinsfile changed.'
                        echo 'Using Python application for pipeline validation.'

                        env.DETECTED_LANGUAGE = 'python'
                        env.DOCKER_IMAGE = 'secure-cicd-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-app'
                        env.APP_PORT = '5000'
                        env.CONTAINER_PORT = '5000'

                    } else {

                        /*
                         * Fallback detection:
                         * If changed-file detection is empty,
                         * detect the application from repository structure.
                         */

                        def nodeExists = fileExists('node-demo/package.json')
                        def pythonExists = fileExists('python-demo/requirements.txt')
                        def javaExists = fileExists('java-demo/pom.xml')

                        if (nodeExists) {

                            echo 'Changed-file detection was empty.'
                            echo 'Node.js application detected from repository structure.'

                            env.DETECTED_LANGUAGE = 'node'
                            env.DOCKER_IMAGE = 'secure-cicd-node-app'
                            env.DOCKER_REPO = 'aditi1166/secure-cicd-node-app'
                            env.APP_PORT = '3000'
                            env.CONTAINER_PORT = '3000'

                        } else if (pythonExists) {

                            echo 'Changed-file detection was empty.'
                            echo 'Python application detected from repository structure.'

                            env.DETECTED_LANGUAGE = 'python'
                            env.DOCKER_IMAGE = 'secure-cicd-app'
                            env.DOCKER_REPO = 'aditi1166/secure-cicd-app'
                            env.APP_PORT = '5000'
                            env.CONTAINER_PORT = '5000'

                        } else if (javaExists) {

                            echo 'Changed-file detection was empty.'
                            echo 'Java application detected from repository structure.'

                            env.DETECTED_LANGUAGE = 'java'
                            env.DOCKER_IMAGE = 'secure-cicd-java-app'
                            env.DOCKER_REPO = 'aditi1166/secure-cicd-java-app'
                            env.APP_PORT = '8081'
                            env.CONTAINER_PORT = '8080'

                        } else {

                            env.DETECTED_LANGUAGE = 'none'
                            echo 'No supported application detected.'
                        }
                    }

                    echo "Detected application: ${env.DETECTED_LANGUAGE}"
                }
            }
        }

        stage('Validate') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'none') {
                        error('No application changes or supported application detected.')
                    }

                    echo 'Application validation successful.'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo
                            "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pip install -r requirements.txt
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo
                            npm install
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo
                            mvn clean compile
                        '''
                    }
                }
            }
        }

        stage('Test') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo
                            "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo
                            npm test
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo
                            mvn test
                        '''
                    }
                }
            }
        }

        stage('Build Application') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Python application does not require a separate compilation step.'

                    } else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Node.js application build completed.'

                    } else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo
                            mvn clean package -DskipTests
                        '''
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo
                            docker build -t %DOCKER_USER%/secure-cicd-app:latest .
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo
                            docker build -t %DOCKER_USER%/secure-cicd-node-app:latest .
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo
                            docker build -t %DOCKER_USER%/secure-cicd-java-app:latest .
                        '''
                    }
                }
            }
        }

        stage('Security Gate') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            powershell -ExecutionPolicy Bypass -File security-gate.ps1 aditi1166/secure-cicd-app:latest
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            powershell -ExecutionPolicy Bypass -File security-gate.ps1 aditi1166/secure-cicd-node-app:latest
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            powershell -ExecutionPolicy Bypass -File security-gate.ps1 aditi1166/secure-cicd-java-app:latest
                        '''
                    }
                }
            }
        }

        stage('Docker Hub Login Test') {
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

                            echo "%DOCKER_PASSWORD%" | docker login -u "%DOCKER_USERNAME%" --password-stdin

                            if errorlevel 1 exit /b %errorlevel%

                            echo Docker Hub login successful.
                        '''
                    }
                }
            }
        }

        stage('Docker Push') {
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
                            echo "%DOCKER_PASSWORD%" | docker login -u "%DOCKER_USERNAME%" --password-stdin

                            if errorlevel 1 exit /b %errorlevel%

                            if "%DETECTED_LANGUAGE%"=="python" docker push aditi1166/secure-cicd-app:latest

                            if "%DETECTED_LANGUAGE%"=="node" docker push aditi1166/secure-cicd-node-app:latest

                            if "%DETECTED_LANGUAGE%"=="java" docker push aditi1166/secure-cicd-java-app:latest

                            if errorlevel 1 exit /b %errorlevel%

                            echo Docker image pushed successfully.
                        '''
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

                        bat '''
                            echo ============================================
                            echo Checking AWS SSM Connection
                            echo ============================================

                            "%AWS_CLI%" ssm describe-instance-information ^
                                --filters "Key=InstanceIds,Values=%EC2_INSTANCE_ID%" ^
                                --region %AWS_DEFAULT_REGION%

                            if errorlevel 1 exit /b %errorlevel%

                            echo AWS SSM connection successful.
                        '''
                    }
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws-ssm-credentials']
                    ]) {

                        def imageRepo = env.DOCKER_REPO
                        def containerName = env.DOCKER_IMAGE
                        def hostPort = env.APP_PORT
                        def containerPort = env.CONTAINER_PORT

                        def commands = "docker pull ${imageRepo}:latest; docker rm -f ${containerName} 2>/dev/null || true; docker run -d --name ${containerName} -p ${hostPort}:${containerPort} ${imageRepo}:latest"

                        def escapedCommands = commands
                            .replace('\\', '\\\\')
                            .replace('"', '\\"')

                        /*
                         * AWS-RunShellScript expects commands
                         * inside the Parameters object.
                         */
                        writeFile(
                            file: 'ssm-commands.json',
                            text: '{"Parameters":{"commands":["' + escapedCommands + '"]}}'
                        )

                        echo 'SSM deployment command prepared.'
                        echo "Deploying image: ${imageRepo}:latest"
                        echo "Container: ${containerName}"
                        echo "Host port: ${hostPort}"
                        echo "Container port: ${containerPort}"

                        bat """
                            "%AWS_CLI%" ssm send-command ^
                                --instance-ids ${env.EC2_INSTANCE_ID} ^
                                --document-name AWS-RunShellScript ^
                                --cli-input-json file://ssm-commands.json ^
                                --region ${env.AWS_DEFAULT_REGION} ^
                                --output text ^
                                --query Command.CommandId > deploy-command-id.txt

                            if errorlevel 1 exit /b %errorlevel%
                        """

                        def deployId = readFile(
                            'deploy-command-id.txt'
                        ).trim()

                        echo "Deployment command ID: ${deployId}"

                        def deployStatus = 'Pending'

                        for (int i = 0; i < 30; i++) {

                            bat """
                                "%AWS_CLI%" ssm get-command-invocation ^
                                    --command-id ${deployId} ^
                                    --instance-id ${env.EC2_INSTANCE_ID} ^
                                    --region ${env.AWS_DEFAULT_REGION} ^
                                    --query Status ^
                                    --output text > deploy-status.txt
                            """

                            deployStatus = readFile(
                                'deploy-status.txt'
                            ).trim()

                            echo "Deployment status: ${deployStatus}"

                            if (
                                deployStatus == 'Success' ||
                                deployStatus == 'Failed' ||
                                deployStatus == 'Cancelled' ||
                                deployStatus == 'TimedOut'
                            ) {
                                break
                            }

                            sleep time: 5, unit: 'SECONDS'
                        }

                        bat """
                            echo ============================================
                            echo EC2 Deployment Output
                            echo ============================================

                            "%AWS_CLI%" ssm get-command-invocation ^
                                --command-id ${deployId} ^
                                --instance-id ${env.EC2_INSTANCE_ID} ^
                                --region ${env.AWS_DEFAULT_REGION} ^
                                --query StandardOutputContent ^
                                --output text

                            echo ============================================
                            echo EC2 Deployment Errors
                            echo ============================================

                            "%AWS_CLI%" ssm get-command-invocation ^
                                --command-id ${deployId} ^
                                --instance-id ${env.EC2_INSTANCE_ID} ^
                                --region ${env.AWS_DEFAULT_REGION} ^
                                --query StandardErrorContent ^
                                --output text
                        """

                        if (deployStatus != 'Success') {

                            error(
                                "EC2 deployment failed. SSM status: ${deployStatus}"
                            )
                        }

                        echo 'EC2 deployment completed successfully.'
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://%EC2_HOST%:5000/health' -UseBasicParsing; Write-Host $r.Content; if($r.StatusCode -ne 200){exit 1} } catch { Write-Host $_; exit 1 }"
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://%EC2_HOST%:3000/health' -UseBasicParsing; Write-Host $r.Content; if($r.StatusCode -ne 200){exit 1} } catch { Write-Host $_; exit 1 }"
                        '''

                    } else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://%EC2_HOST%:8081/health' -UseBasicParsing; Write-Host $r.Content; if($r.StatusCode -ne 200){exit 1} } catch { Write-Host $_; exit 1 }"
                        '''
                    }

                    echo 'Health check completed successfully.'
                }
            }
        }
    }

    post {

        success {

            echo '''
============================================
CI/CD PIPELINE SUCCESSFUL
============================================
Application deployed successfully.
Security gate passed.
Docker image pushed.
EC2 deployment completed.
Health check passed.
============================================
'''
        }

        failure {

            echo """
============================================
CI/CD PIPELINE FAILED
============================================
Application: ${DETECTED_LANGUAGE}
Please check the failed stage in Jenkins.
============================================
"""
        }
    }
}
