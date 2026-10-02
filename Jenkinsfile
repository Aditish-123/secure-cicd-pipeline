pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    stages {

        // ============================================
        // 1. DETECT CHANGED APPLICATION
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
        // 2. VALIDATE APPLICATION SELECTION
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
        // 8. DOCKER PUSH
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
        // 9. TEST EC2 SSH CONNECTION
        // ============================================

        stage('Test EC2 SSH Connection') {

            steps {

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    echo 'Testing SSH connection to AWS EC2...'

                    bat '''
                        echo Fixing SSH private key permissions...

                        icacls "%SSH_KEY%" /inheritance:r

                        icacls "%SSH_KEY%" /remove "BUILTIN\\Users"

                        icacls "%SSH_KEY%" /remove "Everyone"

                        icacls "%SSH_KEY%" /grant:r "SYSTEM":R

                        echo Testing EC2 SSH connection...

                        ssh -o StrictHostKeyChecking=no -i "%SSH_KEY%" %SSH_USER%@ec2-51-20-7-125.eu-north-1.compute.amazonaws.com "docker --version"
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
            echo 'PIPELINE COMPLETED SUCCESSFULLY'
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
