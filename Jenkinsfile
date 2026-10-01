pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Source code checked out from GitHub.'
            }
        }

        stage('Install Dependencies') {
            steps {
                bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pip install -r requirements.txt'
            }
        }

        stage('Test') {
            steps {
                bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest'
            }
        }

        stage('Docker Build') {
            steps {
                bat 'docker build -t secure-cicd-app:latest .'
            }
        }

        stage('Security Gate') {
            steps {
                bat 'powershell -ExecutionPolicy Bypass -File .\\security-gate.ps1'
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

                    bat 'docker tag secure-cicd-app:latest %DOCKER_USERNAME%/secure-cicd-app:latest'

                    bat 'docker push %DOCKER_USERNAME%/secure-cicd-app:latest'
                }
            }
        }
    }

    post {
        always {
            echo 'Archiving Trivy security reports...'
            bat 'dir trivy-report.json trivy-summary.txt'
            archiveArtifacts artifacts: 'trivy-report.json,trivy-summary.txt', allowEmptyArchive: false
        }
    }
}
