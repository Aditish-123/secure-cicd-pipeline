pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    stages {

        // ============================================
        // 1. DETECT APPLICATION
        // ============================================

        stage('Detect Application') {

            steps {

                script {

                    def changedFiles = bat(
                        script: 'git diff-tree --no-commit-id --name-only -r HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Changed files:"
                    echo changedFiles

                    if (changedFiles.contains('python-demo/')) {
                        env.DETECTED_LANGUAGE = 'python'
                    }
                    else if (changedFiles.contains('node-demo/')) {
                        env.DETECTED_LANGUAGE = 'node'
                    }
                    else if (changedFiles.contains('java-demo/')) {
                        env.DETECTED_LANGUAGE = 'java'
                    }
                    else {
                        env.DETECTED_LANGUAGE = 'none'
                    }

                    echo "Detected application: ${env.DETECTED_LANGUAGE}"
                }
            }
        }


        // ============================================
        // 2. VALIDATE APPLICATION
        // ============================================

        stage('Validate Application Selection') {

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'none') {

                        echo "No application code changed."
                        echo "Application build stages will be skipped."
                    }
                }
            }
        }


        // ============================================
        // 3. INSTALL DEPENDENCIES
        // ============================================

        stage('Install Dependencies') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo

                            C:\\Users\\DELL\\AppData\\Local\\Programs\\Python\\Python314\\python.exe -m pip install -r requirements.txt
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

                            mvn clean install -DskipTests
                        '''
                    }
                }
            }
        }


        // ============================================
        // 4. TEST APPLICATION
        // ============================================

        stage('Test') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo

                            C:\\Users\\DELL\\AppData\\Local\\Programs\\Python\\Python314\\python.exe -m pytest tests
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

                            java -cp "target\\classes;target\\test-classes" com.securecicd.AppTest
                        '''
                    }
                }
            }
        }


        // ============================================
        // 5. BUILD APPLICATION
        // ============================================

        stage('Build Application') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo "Python application does not require separate build."
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo "Node.js application does not require separate build."
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


        // ============================================
        // 6. DOCKER BUILD
        // ============================================

        stage('Docker Build') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '''
                            cd python-demo

                            docker build -t secure-cicd-app:latest .
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat '''
                            cd node-demo

                            docker build -t secure-cicd-node-app:latest .
                        '''
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        bat '''
                            cd java-demo

                            docker build -t secure-cicd-java-app:latest .
                        '''
                    }
                }
            }
        }


        // ============================================
        // 7. SECURITY GATE
        // ============================================

        stage('Security Gate') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                bat '''
                    powershell -ExecutionPolicy Bypass -File .\\security-gate.ps1
                '''
            }
        }


        // ============================================
        // 8. DOCKER HUB PUSH
        // ============================================

        stage('Docker Push') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

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
                            echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin
                        '''

                        if (env.DETECTED_LANGUAGE == 'python') {

                            bat '''
                                docker tag secure-cicd-app:latest aditi1166/secure-cicd-app:latest

                                docker push aditi1166/secure-cicd-app:latest
                            '''
                        }

                        else if (env.DETECTED_LANGUAGE == 'node') {

                            bat '''
                                docker tag secure-cicd-node-app:latest aditi1166/secure-cicd-node-app:latest

                                docker push aditi1166/secure-cicd-node-app:latest
                            '''
                        }

                        else if (env.DETECTED_LANGUAGE == 'java') {

                            bat '''
                                docker tag secure-cicd-java-app:latest aditi1166/secure-cicd-java-app:latest

                                docker push aditi1166/secure-cicd-java-app:latest
                            '''
                        }
                    }
                }
            }
        }


        // ============================================
        // 9. DEPLOY TO AWS EC2
        // ============================================

        stage('Deploy to EC2') {

            when {
                expression {
                    env.DETECTED_LANGUAGE == 'python'
                }
            }

            steps {

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials',
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )
                    ]) {

                        echo 'Deploying Python application to AWS EC2...'

                        bat '''
                            echo ============================================
                            echo FIXING SSH KEY PERMISSIONS
                            echo ============================================

                            icacls "%SSH_KEY%" /inheritance:r

                            icacls "%SSH_KEY%" /remove:g "BUILTIN\\Users"

                            icacls "%SSH_KEY%" /remove:g "Everyone"

                            icacls "%SSH_KEY%" /grant:r "SYSTEM":F

                            icacls "%SSH_KEY%" /setowner "SYSTEM"

                            echo ============================================
                            echo DEPLOYING TO EC2
                            echo ============================================

                            ssh -o StrictHostKeyChecking=no -i "%SSH_KEY%" %SSH_USER%@ec2-51-20-7-125.eu-north-1.compute.amazonaws.com "echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin && docker pull aditi1166/secure-cicd-app:latest && docker stop secure-cicd-app 2>nul || true && docker rm secure-cicd-app 2>nul || true && docker run -d --name secure-cicd-app -p 5000:5000 aditi1166/secure-cicd-app:latest"
                        '''
                    }
                }
            }
        }


        // ============================================
        // 10. HEALTH CHECK
        // ============================================

        stage('Health Check') {

            when {
                expression {
                    env.DETECTED_LANGUAGE == 'python'
                }
            }

            steps {

                script {

                    echo 'Waiting for application to start...'

                    sleep(time: 10, unit: 'SECONDS')

                    bat '''
                        powershell -Command "$response = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:5000/health' -UseBasicParsing; Write-Host $response.Content; if ($response.StatusCode -ne 200) { exit 1 }"
                    '''
                }
            }
        }
    }


    // ============================================
    // POST ACTIONS
    // ============================================

    post {

        always {

            archiveArtifacts(
                artifacts: 'trivy-report.json,trivy-summary.txt',
                allowEmptyArchive: true
            )
        }

        success {

            echo '============================================'
            echo 'CI/CD PIPELINE COMPLETED SUCCESSFULLY'
            echo '============================================'
        }

        failure {

            echo '============================================'
            echo 'PIPELINE FAILED'
            echo 'CHECK THE CONSOLE OUTPUT'
            echo '============================================'
        }
    }
}
