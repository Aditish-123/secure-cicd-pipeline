pipeline {
    agent any

    stages {

        stage('Checkout & Detect Application') {
            steps {
                echo 'Checking out source code from GitHub...'

                script {

                    /*
                     * Jenkins checks which application directory
                     * was changed in the latest Git commit.
                     *
                     * This prevents Node.js from always being selected
                     * just because node-demo appears first.
                     */

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

                    /*
                     * If multiple application types changed in the
                     * same commit, do not randomly choose one.
                     */

                    if (detectedCount > 1) {
                        error '''
Multiple application types were changed in the same commit.

Please change only one application at a time:
Python OR Node.js OR Java.
'''
                    }

                    /*
                     * Detect Python
                     */

                    if (pythonChanged) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.APP_DIR = 'python-demo'
                        env.IMAGE_NAME = 'secure-cicd-app:latest'

                        echo 'Detected application language: Python'
                    }

                    /*
                     * Detect Node.js
                     */

                    else if (nodeChanged) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.APP_DIR = 'node-demo'
                        env.IMAGE_NAME = 'secure-cicd-node-app:latest'

                        echo 'Detected application language: Node.js'
                    }

                    /*
                     * Detect Java
                     */

                    else if (javaChanged) {

                        env.DETECTED_LANGUAGE = 'java'
                        env.APP_DIR = 'java-demo'
                        env.IMAGE_NAME = 'secure-cicd-java-app:latest'

                        echo 'Detected application language: Java'
                    }

                    /*
                     * If no application folder changed,
                     * do not randomly select Node/Python/Java.
                     */

                    else {

                        error '''
No application changes were detected in the latest commit.

Please make a change inside:
- python-demo/
- node-demo/
- java-demo/

Then commit the change.
'''
                    }

                    echo "Application directory: ${env.APP_DIR}"
                    echo "Docker image: ${env.IMAGE_NAME}"
                }
            }
        }


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


                    else if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Preparing Java/Maven project...'

                        bat 'cd java-demo && mvn -B test'
                    }
                }
            }
        }


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


                    else if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Running Java application test...'

                        /*
                         * AppTest is currently a simple Java test class.
                         * Maven compiles it, then we execute it explicitly.
                         */

                        bat 'cd java-demo && java -cp "target\\classes;target\\test-classes" com.securecicd.AppTest'

                        echo 'Java test completed successfully.'
                    }
                }
            }
        }


        stage('Build Application') {
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
            steps {

                script {

                    echo "Building Docker image for ${env.DETECTED_LANGUAGE}..."

                    bat "docker build -t ${env.IMAGE_NAME} ${env.APP_DIR}"
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

                    echo 'Running Trivy security scan...'

                    bat 'powershell -ExecutionPolicy Bypass -File .\\security-gate.ps1'
                }
            }
        }


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

            echo 'Archiving Trivy security reports...'

            bat 'dir trivy-report.json trivy-summary.txt'

            archiveArtifacts artifacts:
                'trivy-report.json,trivy-summary.txt',
                allowEmptyArchive: false
        }
    }
}
