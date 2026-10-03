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


                    if (changedFiles.contains('python-demo/')) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.DOCKER_IMAGE = 'secure-cicd-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-app'
                        env.APP_PORT = '5000'
                        env.CONTAINER_PORT = '5000'

                    }

                    else if (changedFiles.contains('node-demo/')) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.DOCKER_IMAGE = 'secure-cicd-node-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-node-app'
                        env.APP_PORT = '3000'
                        env.CONTAINER_PORT = '3000'

                    }

                    else if (changedFiles.contains('java-demo/')) {

                        env.DETECTED_LANGUAGE = 'java'
                        env.DOCKER_IMAGE = 'secure-cicd-java-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-java-app'
                        env.APP_PORT = '8081'
                        env.CONTAINER_PORT = '8080'

                    }

                    else if (changedFiles.contains('Jenkinsfile')) {

                        echo "Only Jenkinsfile changed."
                        echo "Using Python application for pipeline validation."

                        env.DETECTED_LANGUAGE = 'python'
                        env.DOCKER_IMAGE = 'secure-cicd-app'
                        env.DOCKER_REPO = 'aditi1166/secure-cicd-app'
                        env.APP_PORT = '5000'
                        env.CONTAINER_PORT = '5000'

                    }

                    else {

                        env.DETECTED_LANGUAGE = 'none'

                        echo "No application folder changed."
                    }


                    echo "Detected application: ${env.DETECTED_LANGUAGE}"
                }
            }
        }


        stage('Validate') {

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'none') {

                        echo "No application selected."

                        currentBuild.result = 'NOT_BUILT'

                        error("No application changes detected.")
                    }

                    echo "Application validation successful."
                }
            }
        }


        stage('Install Dependencies') {

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo
                            python -m pip install -r requirements.txt
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo
                            echo Node.js application does not require external dependencies.
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

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
                            pytest
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo
                            npm test
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo

                            mvn test

                            if errorlevel 1 exit /b %errorlevel%

                            echo Running Java application validation...

                            mvn package -DskipTests

                            if errorlevel 1 exit /b %errorlevel%

                            echo Java application validation completed.
                        '''
                    }
                }
            }
        }


        stage('Build Application') {

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo "Python application build preparation complete."
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo "Node.js application build preparation complete."
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo
                            mvn package -DskipTests
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
                            docker build -t secure-cicd-app:latest python-demo
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            docker build -t secure-cicd-node-app:latest node-demo
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            docker build -t secure-cicd-java-app:latest java-demo
                        '''
                    }
                }
            }
        }


        stage('Security Gate') {

            steps {

                powershell '''

                    Write-Host "============================================"
                    Write-Host "Starting Security Gate"
                    Write-Host "============================================"

                    & "$env:WORKSPACE\\security-gate.ps1"

                    if ($LASTEXITCODE -ne 0) {

                        Write-Host "Security Gate BLOCKED the pipeline."

                        exit $LASTEXITCODE
                    }

                    Write-Host "Security Gate passed."

                '''
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
                            if exist "%WORKSPACE%\\.docker-test" rmdir /s /q "%WORKSPACE%\\.docker-test"

                            mkdir "%WORKSPACE%\\.docker-test"

                            powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$env:DOCKER_PASSWORD | docker --config '%WORKSPACE%\\.docker-test' login --username $env:DOCKER_USERNAME --password-stdin"

                            if errorlevel 1 exit /b %errorlevel%

                            echo Docker Hub authentication successful.
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

                        bat """
                            docker tag ${env.DOCKER_IMAGE}:latest ${env.DOCKER_REPO}:latest

                            docker push ${env.DOCKER_REPO}:latest
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

                        bat '''
                            echo ============================================
                            echo Checking AWS SSM Connection
                            echo ============================================

                            aws ssm describe-instance-information ^
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

                        powershell '''

                            Write-Host "============================================"
                            Write-Host "Starting EC2 Deployment through AWS SSM"
                            Write-Host "============================================"


                            $commands = @()


                            if ($env:DETECTED_LANGUAGE -eq "python") {

                                $commands = @(
                                    "docker pull aditi1166/secure-cicd-app:latest",
                                    "docker rm -f secure-cicd-app 2>/dev/null || true",
                                    "docker run -d --name secure-cicd-app -p 5000:5000 aditi1166/secure-cicd-app:latest"
                                )
                            }


                            elseif ($env:DETECTED_LANGUAGE -eq "node") {

                                $commands = @(
                                    "docker pull aditi1166/secure-cicd-node-app:latest",
                                    "docker rm -f secure-cicd-node-app 2>/dev/null || true",
                                    "docker run -d --name secure-cicd-node-app -p 3000:3000 aditi1166/secure-cicd-node-app:latest"
                                )
                            }


                            elseif ($env:DETECTED_LANGUAGE -eq "java") {

                                $commands = @(
                                    "docker pull aditi1166/secure-cicd-java-app:latest",
                                    "docker rm -f secure-cicd-java-app 2>/dev/null || true",
                                    "docker run -d --name secure-cicd-java-app -p 8081:8080 aditi1166/secure-cicd-java-app:latest"
                                )
                            }


                            else {

                                Write-Host "No valid application detected."

                                exit 1
                            }


                            Write-Host ""
                            Write-Host "Commands that will run on EC2:"
                            Write-Host ""


                            $commands | ForEach-Object {
                                Write-Host $_
                            }


                            $parameterObject = @{
                                commands = $commands
                            }


                            $parameterJson = $parameterObject | ConvertTo-Json -Compress


                            Write-Host ""
                            Write-Host "Sending command to EC2 through SSM..."


                            $result = aws ssm send-command `
                                --instance-ids $env:EC2_INSTANCE_ID `
                                --document-name "AWS-RunShellScript" `
                                --parameters $parameterJson `
                                --region $env:AWS_DEFAULT_REGION `
                                --output json


                            if ($LASTEXITCODE -ne 0) {

                                Write-Host "Failed to send SSM command."

                                exit $LASTEXITCODE
                            }


                            $commandData = $result | ConvertFrom-Json

                            $commandId = $commandData.Command.CommandId


                            Write-Host ""
                            Write-Host "SSM Command ID: $commandId"
                            Write-Host "Waiting for EC2 command to complete..."


                            $status = "Pending"
                            $invocationData = $null


                            for ($i = 1; $i -le 30; $i++) {

                                Start-Sleep -Seconds 5


                                $invocation = aws ssm get-command-invocation `
                                    --command-id $commandId `
                                    --instance-id $env:EC2_INSTANCE_ID `
                                    --region $env:AWS_DEFAULT_REGION `
                                    --output json


                                if ($LASTEXITCODE -ne 0) {

                                    Write-Host "Unable to read SSM command status."

                                    exit $LASTEXITCODE
                                }


                                $invocationData = $invocation | ConvertFrom-Json

                                $status = $invocationData.Status


                                Write-Host "SSM Status: $status"


                                if (
                                    $status -eq "Success" -or
                                    $status -eq "Failed" -or
                                    $status -eq "TimedOut" -or
                                    $status -eq "Cancelled"
                                ) {

                                    break
                                }
                            }


                            Write-Host ""
                            Write-Host "============================================"
                            Write-Host "EC2 COMMAND OUTPUT"
                            Write-Host "============================================"


                            if ($invocationData.StandardOutputContent) {

                                Write-Host $invocationData.StandardOutputContent
                            }


                            if ($invocationData.StandardErrorContent) {

                                Write-Host $invocationData.StandardErrorContent
                            }


                            Write-Host "============================================"


                            if ($status -ne "Success") {

                                Write-Host "EC2 deployment failed through SSM."

                                exit 1
                            }


                            Write-Host "EC2 deployment completed successfully through SSM."

                        '''
                    }
                }
            }
        }


        stage('Health Check') {

            steps {

                script {

                    sleep(
                        time: 10,
                        unit: 'SECONDS'
                    )


                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            powershell -NoProfile -NonInteractive -Command "$r = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:5000/health' -UseBasicParsing; Write-Host 'HTTP Status:' $r.StatusCode; Write-Host 'Response:' $r.Content; if ($r.StatusCode -ne 200) { exit 1 }"
                        '''
                    }


                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            powershell -NoProfile -NonInteractive -Command "$r = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:3000/health' -UseBasicParsing; Write-Host 'HTTP Status:' $r.StatusCode; Write-Host 'Response:' $r.Content; if ($r.StatusCode -ne 200) { exit 1 }"
                        '''
                    }


                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            powershell -NoProfile -NonInteractive -Command "$r = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:8081/health' -UseBasicParsing; Write-Host 'HTTP Status:' $r.StatusCode; Write-Host 'Response:' $r.Content; if ($r.StatusCode -ne 200) { exit 1 }"
                        '''
                    }
                }
            }
        }
    }


    post {

        success {

            echo "============================================"
            echo "CI/CD PIPELINE SUCCESSFUL"
            echo "============================================"
            echo "Application: ${env.DETECTED_LANGUAGE}"
            echo "Docker Image: ${env.DOCKER_REPO}:latest"
            echo "Deployment Method: AWS Systems Manager (SSM)"
            echo "Deployment completed successfully."
            echo "Health check passed."
            echo "============================================"
        }


        failure {

            echo "============================================"
            echo "CI/CD PIPELINE FAILED"
            echo "============================================"
            echo "Application: ${env.DETECTED_LANGUAGE}"
            echo "Please check the failed stage in Jenkins."
            echo "============================================"
        }
    }
}
