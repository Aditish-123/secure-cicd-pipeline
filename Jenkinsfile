pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    environment {
        DOCKER_USER = 'aditi1166'

        EC2_HOST = 'ec2-51-20-7-125.eu-north-1.compute.amazonaws.com'
        EC2_USER = 'ec2-user'
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

                        echo "No application selected. Pipeline will stop."

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

                            java -cp target/java-demo-1.0.0.jar com.securecicd.App
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
                    & "$env:WORKSPACE\\security-gate.ps1"

                    if ($LASTEXITCODE -ne 0) {
                        exit $LASTEXITCODE
                    }
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


        stage('Deploy to EC2') {
            steps {
                script {

                    sshagent(credentials: ['ec2-ssh-key']) {

                        if (env.DETECTED_LANGUAGE == 'python') {

                            bat '''
                                ssh -o StrictHostKeyChecking=no ec2-user@ec2-51-20-7-125.eu-north-1.compute.amazonaws.com "docker pull aditi1166/secure-cicd-app:latest && docker rm -f secure-cicd-app 2>/dev/null || true && docker run -d --name secure-cicd-app -p 5000:5000 aditi1166/secure-cicd-app:latest"
                            '''

                        }
                        else if (env.DETECTED_LANGUAGE == 'node') {

                            bat '''
                                ssh -o StrictHostKeyChecking=no ec2-user@ec2-51-20-7-125.eu-north-1.compute.amazonaws.com "docker pull aditi1166/secure-cicd-node-app:latest && docker rm -f secure-cicd-node-app 2>/dev/null || true && docker run -d --name secure-cicd-node-app -p 3000:3000 aditi1166/secure-cicd-node-app:latest"
                            '''

                        }
                        else if (env.DETECTED_LANGUAGE == 'java') {

                            bat '''
                                ssh -o StrictHostKeyChecking=no ec2-user@ec2-51-20-7-125.eu-north-1.compute.amazonaws.com "docker pull aditi1166/secure-cicd-java-app:latest && docker rm -f secure-cicd-java-app 2>/dev/null || true && docker run -d --name secure-cicd-java-app -p 8081:8080 aditi1166/secure-cicd-java-app:latest"
                            '''
                        }
                    }
                }
            }
        }


        stage('Health Check') {
            steps {
                script {

                    sleep(time: 10, unit: 'SECONDS')

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:5000/health' -UseBasicParsing; if ($r.StatusCode -ne 200) { exit 1 }; Write-Host $r.Content } catch { exit 1 }"
                        '''

                    }
                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:3000/health' -UseBasicParsing; if ($r.StatusCode -ne 200) { exit 1 }; Write-Host $r.Content } catch { exit 1 }"
                        '''

                    }
                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:8081/health' -UseBasicParsing; if ($r.StatusCode -ne 200) { exit 1 }; Write-Host $r.Content } catch { exit 1 }"
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
            echo "Deployment completed successfully."
        }

        failure {
            echo "============================================"
            echo "CI/CD PIPELINE FAILED"
            echo "============================================"
            echo "Application: ${env.DETECTED_LANGUAGE}"
        }
    }
}
