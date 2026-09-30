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
                bat 'python3 -m pip install -r requirements.txt'
            }
        }

        stage('Test') {
            steps {
                bat 'python3 -m pytest'
            }
        }

    }
}
