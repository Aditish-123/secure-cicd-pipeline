pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Source code checked out from GitHub.'

                script {

                    if (fileExists('python-demo/requirements.txt')) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.APP_DIR = 'python-demo'
                        env.IMAGE_NAME = 'secure-cicd-app:latest'

                        echo 'Detected language: Python'
                    }

                    else if (fileExists('node-demo/package.json')) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.APP_DIR = 'node-demo'
                        env.IMAGE_NAME = 'secure-cicd-node-app:latest'

                        echo 'Detected language: Node.js'
                    }

                    else {
                        error 'Unable to detect supported project language.'
                    }
                }
            }
        }


        stage('Install Dependencies') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pip install -r python-demo/requirements.txt'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat 'cd node-demo && npm install'
                    }
                }
            }
        }


        stage('Test') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest python-demo/tests'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat 'cd node-demo && npm test'
                    }
                }
            }
        }


        stage('Docker Build') {
            steps {
                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        bat 'docker build -t secure-cicd-app:latest python-demo'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        bat 'docker build -t secure-cicd-node-app:latest node-demo'
                    }
                }
            }
        }


        stage('Security Gate') {
            steps {
                script {

                    def previousBuild = currentBuild.previousBuild

                    if (previousBuild != null) {
                        env.PREVIOUS_BUILD_NUMBER = previousBuild.number.toString()
                    }

                    else {
                        env.PREVIOUS_BUILD_NUMBER = "NONE"
                    }

                    bat 'powershell -ExecutionPolicy Bypass -File .\\security-gate.ps1'
                }
            }
        }


        stage('Docker Push') {
            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {

                    bat 'docker login -u %DOCKER_USERNAME% -p %DOCKER_PASSWORD%'

                    script {

                        if (env.DETECTED_LANGUAGE == 'python') {

                            bat 'docker tag secure-cicd-app:latest %DOCKER_USERNAME%/secure-cicd-app:latest'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-app:latest'
                        }

                        else if (env.DETECTED_LANGUAGE == 'node') {

                            bat 'docker tag secure-cicd-node-app:latest %DOCKER_USERNAME%/secure-cicd-node-app:latest'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-node-app:latest'
                        }
                    }
                }
            }
        }
    }


    post {
        always {

            echo 'Archiving Trivy security reports...'

            bat 'dir trivy-report.json trivy-summary.txt'

            archiveArtifacts artifacts: 'trivy-report.json,trivy-summary.txt',
                             allowEmptyArchive: false
        }
    }
}
