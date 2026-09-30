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

    }

    post {
        always {
            echo 'Archiving Trivy security report...'
            bat 'dir trivy-report.json'
            archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: false
        }
    }
}
