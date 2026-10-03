```groovy
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

                        error('No application changes detected.')

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

                            "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pip install -r requirements.txt
                        '''

                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo

                            npm install
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

                            "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest
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
                        '''
                    }
                }
            }
        }


        stage('Build Application') {

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo "Python application does not require a separate compilation step."

                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo "Node.js application build completed."

                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo

                            mvn clean package -DskipTests

                            if errorlevel 1 exit /b %errorlevel%
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
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo

                            docker build -t %DOCKER_USER%/secure-cicd-node-app:latest .
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

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
                            powershell -ExecutionPolicy Bypass -File security-gate.ps1 %DOCKER_USER%/secure-cicd-app:latest
                        '''

                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            powershell -Exec
```
