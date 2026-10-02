pipeline {

    agent any

    tools {
        maven 'Maven-3.9.14'
    }

    stages {

        // ============================================
        // 1. CHECKOUT & APPLICATION DETECTION
        // ============================================

        stage('Checkout & Detect Application') {

            steps {

                echo 'Checking out source code from GitHub...'

                script {

                    /*
                     * Find files changed in the latest commit.
                     */

                    def changedFiles = bat(
                        script: '@git diff-tree --no-commit-id --name-only -r HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Files changed in latest commit:"
                    echo changedFiles


                    /*
                     * Check which application directory changed.
                     */

                    def pythonChanged = changedFiles.readLines().any {
                        it.startsWith('python-demo/')
                    }

                    def nodeChanged = changedFiles.readLines().any {
                        it.startsWith('node-demo/')
                    }

                    def javaChanged = changedFiles.readLines().any {
                        it.startsWith('java-demo/')
                    }


                    /*
                     * Count how many application types changed.
                     */

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
                     * If more than one application changed,
                     * stop instead of randomly selecting one.
                     */

                    if (detectedCount > 1) {

                        error '''
Multiple application types were changed in the same commit.

Please change only one application at a time:

Python OR Node.js OR Java.
'''
                    }


                    /*
                     * Python
                     */

                    if (pythonChanged) {

                        env.DETECTED_LANGUAGE = 'python'
                        env.APP_DIR = 'python-demo'
                        env.IMAGE_NAME = 'secure-cicd-app:latest'

                        echo 'Detected application language: Python'
                    }


                    /*
                     * Node.js
                     */

                    else if (nodeChanged) {

                        env.DETECTED_LANGUAGE = 'node'
                        env.APP_DIR = 'node-demo'
                        env.IMAGE_NAME = 'secure-cicd-node-app:latest'

                        echo 'Detected application language: Node.js'
                    }


                    /*
                     * Java
                     */

                    else if (javaChanged) {

                        env.DETECTED_LANGUAGE = 'java'
                        env.APP_DIR = 'java-demo'
                        env.IMAGE_NAME = 'secure-cicd-java-app:latest'

                        echo 'Detected application language: Java'
                    }


                    /*
                     * Only pipeline/support files changed.
                     */

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


        // ============================================
        // 2. INSTALL DEPENDENCIES
        // ============================================

        stage('Install Dependencies') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    /*
                     * Python
                     */

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Installing Python dependencies...'

                        bat 'cd python-demo && "C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest tests'
                    }


                    /*
                     * Node.js
                     */

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Installing Node.js dependencies...'

                        bat 'cd node-demo && npm install'
                    }


                    /*
                     * Java
                     */

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Preparing Java/Maven project...'

                        bat 'cd java-demo && mvn -B test'
                    }
                }
            }
        }


        // ============================================
        // 3. TEST
        // ============================================

        stage('Test') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    /*
                     * Python tests
                     */

                    if (env.DETECTED_LANGUAGE == 'python') {

                        echo 'Running Python tests...'

                        bat '"C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe" -m pytest python-demo/tests'
                    }


                    /*
                     * Node.js tests
                     */

                    else if (env.DETECTED_LANGUAGE == 'node') {

                        echo 'Running Node.js tests...'

                        bat 'cd node-demo && npm test'
                    }


                    /*
                     * Java tests
                     */

                    else if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Running Java application test...'

                        /*
                         * AppTest is currently a simple Java class,
                         * not a JUnit test.
                         *
                         * Maven compiles it first.
                         * We execute it explicitly here.
                         */

                        bat 'cd java-demo && java -cp "target\\classes;target\\test-classes" com.securecicd.AppTest'

                        echo 'Java test completed successfully.'
                    }
                }
            }
        }


        // ============================================
        // 4. BUILD APPLICATION
        // ============================================

        stage('Build Application') {

            when {
                expression {
                    env.DETECTED_LANGUAGE != 'none'
                }
            }

            steps {

                script {

                    /*
                     * Java requires Maven to create the JAR.
                     */

                    if (env.DETECTED_LANGUAGE == 'java') {

                        echo 'Building Java JAR with Maven...'

                        bat 'cd java-demo && mvn -B package -DskipTests'
                    }


                    /*
                     * Python and Node.js are built directly
                     * inside their Docker images.
                     */

                    else {

                        echo 'No separate application build command required.'
                    }
                }
            }
        }


        // ============================================
        // 5. DOCKER BUILD
        // ============================================

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


        // ============================================
        // 6. SECURITY GATE
        // ============================================

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


        // ============================================
        // 7. DOCKER PUSH
        // ============================================

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

                        /*
                         * Python
                         */

                        if (env.DETECTED_LANGUAGE == 'python') {

                            echo 'Tagging Python Docker image...'

                            bat 'docker tag secure-cicd-app:latest %DOCKER_USERNAME%/secure-cicd-app:latest'

                            echo 'Pushing Python Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-app:latest'
                        }


                        /*
                         * Node.js
                         */

                        else if (env.DETECTED_LANGUAGE == 'node') {

                            echo 'Tagging Node.js Docker image...'

                            bat 'docker tag secure-cicd-node-app:latest %DOCKER_USERNAME%/secure-cicd-node-app:latest'

                            echo 'Pushing Node.js Docker image...'

                            bat 'docker push %DOCKER_USERNAME%/secure-cicd-node-app:latest'
                        }


                        /*
                         * Java
                         */

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


    // ============================================
    // POST ACTIONS
    // ============================================

    post {

        always {

            echo 'Checking Trivy security reports...'

            /*
             * Reports may already exist from a previous build
             * because Jenkins reuses the workspace.
             */

            bat 'dir trivy-report.json trivy-summary.txt'

            archiveArtifacts artifacts:
                'trivy-report.json,trivy-summary.txt',
                allowEmptyArchive: true
        }
    }
}
