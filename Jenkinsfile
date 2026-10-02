pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    stages {

        stage('Checkout & Detect Application') {

            steps {

                echo 'Checking out source code from GitHub...'

                script {

                    def changedFiles = bat(
                        script: '@git diff-tree --no-commit-id --name-only -r HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Files changed in latest commit:"
                    echo changedFiles

                    def pythonChanged = changedFiles.readLines().any {
                        it.startsWith('python-demo/')
                    }

                    def nodeChanged = changedFiles.readLines().any {
                        it.startsWith('node-demo/')
                    }

                    def javaChanged = changedFiles.readLines().any {
                        it.startsWith('java-demo/')
                    }

                    def detectedCount = 0

                    if (pythonChanged) {
                        detectedCount++
                    }

                    if (nodeChanged) {
                        detectedCount++
                    }

                    if (javaChanged) {
                        detectedCount++
                    }

                    if (detectedCount > 1) {

                        error '''
Multiple application types were changed in the same commit.

Please change only one application at a time:

Python OR Node.js OR Java.
'''
                    }

                    if (pythonChanged) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.APP_DIR = 'python-demo'
                        env.IMAGE_NAME = 'secure-cicd-app:latest'

                        echo 'Detected application language: Python'
                    }

                    else if (nodeChanged) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.APP_DIR = 'node-demo'
                        env.IMAGE_NAME = 'secure-cicd-node-app:latest'

                        echo 'Detected application language: Node.js'
                    }

                    else if (javaChanged) {

                        env.DETECTED_LANGUAGE = 'java'
                        env.APP_DIR = 'java-demo'
                        env.IMAGE_NAME = 'secure-cicd-java-app:latest'

                        echo 'Detected application language: Java'
                    }

                    else {

                        env.DETECTED_LANGUAGE = 'none'
                        env.APP_DIR = ''
                        env.IMAGE_NAME = ''

                        echo '''
No application changes detected.

The latest commit only changed pipeline/support files.
Application stages will be skipped.
'''
                    }

                    echo "Application language: ${env.DETECTED_LANGUAGE}"
                    echo "Application directory: ${env.APP_DIR}"
                    echo "Docker image: ${env.IMAGE_NAME}"
                }
            }
        }


        stage('Install Dependencies') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Installing Python dependencies...'

                        bat 'cd python-demo && "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pip install -r requirements.txt'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Installing Node.js dependencies...'

                        bat 'cd node-demo && npm install'
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Preparing Java/Maven project...'

                        bat 'cd java-demo && mvn -B test'
                    }
                }
            }
        }


        stage('Test') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Running Python tests...'

                        bat 'cd python-demo && "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest tests'
                    }

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Running Node.js tests...'

                        bat 'cd node-demo && npm test'
                    }

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Running Java application test...'

                        bat 'cd java-demo && java -cp "target\\classes;target\\test-classes" com.securecicd.AppTest'

                        echo 'Java test completed successfully.'
                    }
                }
            }
        }


        stage('Build Application') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Building Java JAR with Maven...'

                        bat 'cd java-demo && mvn -B package -DskipTests'
                    }

                    else {

                        echo 'No separate application build command required.'
                    }
                }
            }
        }


        stage('Docker Build') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    echo "Building Docker image for ${env.DETECTED_LANGUAGE}..."

                    bat "docker build -t ${env.IMAGE_NAME} ${env.APP_DIR}"
                }
            }
        }


        stage('Security Gate') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

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


        stage('Docker Push') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

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

                        if (env.DETECTED_LANGUAGE == 'python') {

                            echo 'Tagging Python Docker image...'

                            bat 'docker tag secure-cicd-app:latest %DOCKER_USERNAME%/secure-cicd-app:latest'

                            echo 'Pushing Python Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-app:latest'
                        }

                        else if (env.DETECTED_LANGUAGE == 'node') {

                            echo 'Tagging Node.js Docker image...'

                            bat 'docker tag secure-cicd-node-app:latest %DOCKER_USERNAME%/secure-cicd-node-app:latest'

                            echo 'Pushing Node.js Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-node-app:latest'
                        }

                        else if (env.DETECTED_LANGUAGE == 'java') {

                            echo 'Tagging Java Docker image...'

                            bat 'docker tag secure-cicd-java-app:latest %DOCKER_USERNAME%/secure-cicd-java-app:latest'

                            echo 'Pushing Java Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-java-app:latest'
                        }
                    }
                }
            }
        }
    }


    post {

        always {

            echo 'Checking Trivy security reports...'

            bat 'dir trivy-report.json trivy-summary.txt'

            archiveArtifacts artifacts:
                'trivy-report.json,trivy-summary.txt',
                allowEmptyArchive: true
        }
    }
}
