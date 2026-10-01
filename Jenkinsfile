pipeline {
    agent any

    stages {

        // ==========================================
        // CHECKOUT + LANGUAGE DETECTION
        // ==========================================

        stage('Checkout') {
            steps {

                echo 'Source code checked out from GitHub.'

                script {

                    // First check Node.js
                    if (fileExists('node-demo/package.json')) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.APP_DIR = 'node-demo'
                        env.IMAGE_NAME = 'secure-cicd-node-app:latest'

                        echo 'Detected language: Node.js'
                    }

                    // If Node.js is not found, check Python
                    else if (fileExists('python-demo/requirements.txt')) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.APP_DIR = 'python-demo'
                        env.IMAGE_NAME = 'secure-cicd-app:latest'

                        echo 'Detected language: Python'
                    }

                    else {
                        error 'Unable to detect supported project language.'
                    }
                }
            }
        }


        // ==========================================
        // INSTALL DEPENDENCIES
        // ==========================================

        stage('Install Dependencies') {
            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Installing Python dependencies...'

                        bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pip install -r python-demo/requirements.txt'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Installing Node.js dependencies...'

                        bat 'cd node-demo && npm install'
                    }
                }
            }
        }


        // ==========================================
        // TEST
        // ==========================================

        stage('Test') {
            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Running Python tests...'

                        bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest python-demo/tests'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Running Node.js tests...'

                        bat 'cd node-demo && npm test'
                    }
                }
            }
        }


        // ==========================================
        // DOCKER BUILD
        // ==========================================

        stage('Docker Build') {
            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Building Python Docker image...'

                        bat 'docker build -t secure-cicd-app:latest python-demo'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Building Node.js Docker image...'

                        bat 'docker build -t secure-cicd-node-app:latest node-demo'
                    }
                }
            }
        }


        // ==========================================
        // SECURITY SCAN + SECURITY GATE
        // ==========================================

        stage('Security Gate') {
            steps {

                script {

                    def previousBuild = currentBuild.previousBuild

                    if (previousBuild != null) {

                        env.PREVIOUS_BUILD_NUMBER =
                            previousBuild.number.toString()
                    }

                    else {

                        env.PREVIOUS_BUILD_NUMBER = "NONE"
                    }

                    echo 'Running Trivy security scan...'

                    bat 'powershell -ExecutionPolicy Bypass -File .\\security-gate.ps1'
                }
            }
        }


        // ==========================================
        // DOCKER HUB PUSH
        // ==========================================

        stage('Docker Push') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    echo 'Logging into Docker Hub...'

                    bat 'docker login -u %DOCKER_USERNAME% -p %DOCKER_PASSWORD%'

                    script {

                        // Python image
                        if (env.DETECTED_LANGUAGE == 'python') {

                            echo 'Tagging Python Docker image...'

                            bat 'docker tag secure-cicd-app:latest %DOCKER_USERNAME%/secure-cicd-app:latest'

                            echo 'Pushing Python Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-app:latest'
                        }

                        // Node.js image
                        else if (env.DETECTED_LANGUAGE == 'node') {

                            echo 'Tagging Node.js Docker image...'

                            bat 'docker tag secure-cicd-node-app:latest %DOCKER_USERNAME%/secure-cicd-node-app:latest'

                            echo 'Pushing Node.js Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-node-app:latest'
                        }
                    }
                }
            }
        }
    }


    // ==========================================
    // POST ACTIONS
    // ==========================================

    post {

        always {

            echo 'Archiving Trivy security reports...'

            bat 'dir trivy-report.json trivy-summary.txt'

            archiveArtifacts artifacts:
                'trivy-report.json,trivy-summary.txt',
                allowEmptyArchive: false
        }
    }
}
