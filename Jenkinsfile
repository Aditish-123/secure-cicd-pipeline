pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    stages {

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


        stage('Validate Application Selection') {
            steps {
                script {

                    if (
                        env.DETECTED_LANGUAGE != 'python' &&
                        env.DETECTED_LANGUAGE != 'node' &&
                        env.DETECTED_LANGUAGE != 'java' &&
                        env.DETECTED_LANGUAGE != 'none'
                    ) {
                        error("Unknown application detected.")
                    }
                }
            }
        }


        stage('Install Dependencies') {
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
                    else {

                        echo "No application selected. Dependency installation skipped."
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
                    else {

                        echo "No application selected. Testing skipped."
                    }
                }
            }
        }


        stage('Build Application') {
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
                    else {

                        echo "No application selected. Build skipped."
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
                    else {

                        echo "No application selected. Docker build skipped."
                    }
                }
            }
        }


        stage('Security Gate') {
            steps {
                script {

                    if (
                        env.DETECTED_LANGUAGE == 'python' ||
                        env.DETECTED_LANGUAGE == 'node' ||
                        env.DETECTED_LANGUAGE == 'java'
                    ) {

                        bat '''
                            powershell -ExecutionPolicy Bypass -File .\\security-gate.ps1
                        '''

                    }
                    else {

                        echo "No application selected. Security Gate skipped."
                    }
                }
            }
        }


        // ============================================
        // DOCKER PUSH
        // ============================================

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

                        echo "Docker Hub username loaded from Jenkins Credentials."

                        bat '''
                            docker logout
                            echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin
                        '''

                        if (env.DETECTED_LANGUAGE == 'python') {

                            bat '''
                                docker tag secure-cicd-app aditi1166/secure-cicd-app
                                docker push aditi1166/secure-cicd-app
                            '''

                        }
                        else if (env.DETECTED_LANGUAGE == 'node') {

                            bat '''
                                docker tag secure-cicd-node-app aditi1166/secure-cicd-node-app
                                docker push aditi1166/secure-cicd-node-app
                            '''

                        }
                        else if (env.DETECTED_LANGUAGE == 'java') {

                            bat '''
                                docker tag secure-cicd-java-app aditi1166/secure-cicd-java-app
                                docker push aditi1166/secure-cicd-java-app
                            '''

                        }
                        else {

                            echo "No application selected. Docker push skipped."
                        }
                    }
                }
            }
        }


        // ============================================
        // DEPLOY TO EC2
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

                        bat '''
                            icacls "%SSH_KEY%" /inheritance:r
                            icacls "%SSH_KEY%" /remove:g "BUILTIN\\Users"
                            icacls "%SSH_KEY%" /remove:g "Everyone"
                            icacls "%SSH_KEY%" /grant:r "SYSTEM":F
                            icacls "%SSH_KEY%" /setowner "SYSTEM"

                            ssh -o StrictHostKeyChecking=no -i "%SSH_KEY%" %SSH_USER%@ec2-51-20-7-125.eu-north-1.compute.amazonaws.com "echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin && docker pull aditi1166/secure-cicd-app && docker stop secure-cicd-app 2>nul || true && docker rm secure-cicd-app 2>nul || true && docker run -d --name secure-cicd-app -p 5000:5000 aditi1166/secure-cicd-app"
                        '''
                    }
                }
            }
        }


        // ============================================
        // HEALTH CHECK
        // ============================================

        stage('Health Check') {

            when {
                expression {
                    env.DETECTED_LANGUAGE == 'python'
                }
            }

            steps {

                bat '''
                    powershell -Command "$response = Invoke-WebRequest -Uri 'http://ec2-51-20-7-125.eu-north-1.compute.amazonaws.com:5000/health' -UseBasicParsing; Write-Host $response.Content; if ($response.StatusCode -ne 200) { exit 1 }"
                '''
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

            echo '''
============================================
PIPELINE SUCCESSFUL
============================================
'''
        }

        failure {

            echo '''
============================================
PIPELINE FAILED
CHECK THE CONSOLE OUTPUT
============================================
'''
        }
    }
}
