pipeline {

    agent any

    environment {
        DOCKER_USER = 'aditi1166'

        AWS_DEFAULT_REGION = 'eu-north-1'
        EC2_INSTANCE_ID = 'i-0f484796d1bab5c3f'
        EC2_HOST = 'ec2-51-20-7-125.eu-north-1.compute.amazonaws.com'

        PYTHON_EXE = 'C:/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe'
        AWS_CLI = 'C:/Program Files/Amazon/AWSCLIV2/aws.exe'

        PYTHON_IMAGE = 'aditi1166/secure-cicd-app:latest'
        NODE_IMAGE = 'aditi1166/secure-cicd-node-app:latest'
        JAVA_IMAGE = 'aditi1166/secure-cicd-java-app:latest'
    }

    stages {

        stage('Detect Application') {
            steps {
                script {

                    def changedFiles = bat(
                        script: 'git diff --name-only HEAD~1 HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Changed files:"
                    echo changedFiles

                    if (changedFiles.contains('node-demo/')) {
                        env.APP_TYPE = 'node'
                    }
                    else if (changedFiles.contains('java-demo/')) {
                        env.APP_TYPE = 'java'
                    }
                    else if (changedFiles.contains('python-demo/')) {
                        env.APP_TYPE = 'python'
                    }
                    else {
                        env.APP_TYPE = 'python'
                        echo "No application folder detected. Using Python."
                    }

                    echo "Detected application: ${env.APP_TYPE}"
                }
            }
        }

        stage('Validate') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {
                        if (!fileExists('python-demo/requirements.txt')) {
                            error "Python requirements.txt not found."
                        }
                    }
                    else if (env.APP_TYPE == 'node') {
                        if (!fileExists('node-demo/package.json')) {
                            error "Node package.json not found."
                        }
                    }
                    else if (env.APP_TYPE == 'java') {
                        if (!fileExists('java-demo/pom.xml')) {
                            error "Java pom.xml not found."
                        }
                    }
                    else {
                        error "Unsupported application type."
                    }

                    echo "Validation successful."
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {
                        bat "cd python-demo && \"${PYTHON_EXE}\" -m pip install -r requirements.txt"
                    }
                    else if (env.APP_TYPE == 'node') {
                        bat "cd node-demo && npm install"
                    }
                    else if (env.APP_TYPE == 'java') {
                        bat "cd java-demo && mvn clean compile"
                    }
                }
            }
        }

        stage('Test') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {
                        bat "cd python-demo && \"${PYTHON_EXE}\" -m pytest"
                    }
                    else if (env.APP_TYPE == 'node') {
                        bat "cd node-demo && npm test"
                    }
                    else if (env.APP_TYPE == 'java') {
                        bat "cd java-demo && mvn test"
                    }
                }
            }
        }

        stage('Build Application') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {
                        echo "Python application does not require compilation."
                    }
                    else if (env.APP_TYPE == 'node') {
                        echo "Node.js application does not require compilation."
                    }
                    else if (env.APP_TYPE == 'java') {
                        bat "cd java-demo && mvn clean package -DskipTests"
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {
                        bat "cd python-demo && docker build -t ${PYTHON_IMAGE} ."
                    }
                    else if (env.APP_TYPE == 'node') {
                        bat "cd node-demo && docker build -t ${NODE_IMAGE} ."
                    }
                    else if (env.APP_TYPE == 'java') {
                        bat "cd java-demo && docker build -t ${JAVA_IMAGE} ."
                    }
                }
            }
        }

        stage('Security Gate') {
            steps {
                script {

                    def imageName = ''

                    if (env.APP_TYPE == 'python') {
                        imageName = env.PYTHON_IMAGE
                    }
                    else if (env.APP_TYPE == 'node') {
                        imageName = env.NODE_IMAGE
                    }
                    else if (env.APP_TYPE == 'java') {
                        imageName = env.JAVA_IMAGE
                    }
                    else {
                        error "Unsupported application type for security scanning."
                    }

                    echo "Starting security scan..."
                    echo "Application: ${env.APP_TYPE}"
                    echo "Docker Image: ${imageName}"

                    bat "powershell -NoProfile -ExecutionPolicy Bypass -File security-gate.ps1 \"${imageName}\" \"${env.APP_TYPE}\""
                }
            }
        }

        stage('Docker Hub Login') {
            steps {
                script {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials',
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )
                    ]) {

                        bat "docker login -u \"%DOCKER_USERNAME%\" -p \"%DOCKER_PASSWORD%\""
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {

                    if (env.APP_TYPE == 'python') {
                        bat "docker push ${PYTHON_IMAGE}"
                    }
                    else if (env.APP_TYPE == 'node') {
                        bat "docker push ${NODE_IMAGE}"
                    }
                    else if (env.APP_TYPE == 'java') {
                        bat "docker push ${JAVA_IMAGE}"
                    }
                }
            }
        }

        stage('SSM Connection Test') {
            steps {
                script {

                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-ssm-credentials'
                        ]
                    ]) {

                        bat "\"${AWS_CLI}\" sts get-caller-identity"

                        bat "\"${AWS_CLI}\" ssm describe-instance-information --region ${AWS_DEFAULT_REGION}"

                        echo "AWS SSM connection successful."
                    }
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {

                    def imageName = ''
                    def containerName = ''
                    def hostPort = ''
                    def containerPort = ''

                    if (env.APP_TYPE == 'python') {
                        imageName = env.PYTHON_IMAGE
                        containerName = 'secure-cicd-app'
                        hostPort = '5000'
                        containerPort = '5000'
                    }
                    else if (env.APP_TYPE == 'node') {
                        imageName = env.NODE_IMAGE
                        containerName = 'secure-cicd-node-app'
                        hostPort = '3000'
                        containerPort = '3000'
                    }
                    else if (env.APP_TYPE == 'java') {
                        imageName = env.JAVA_IMAGE
                        containerName = 'secure-cicd-java-app'
                        hostPort = '8081'
                        containerPort = '8080'
                    }
                    else {
                        error "Unsupported application type."
                    }

                    def commands = "docker pull ${imageName}\ndocker stop ${containerName} || true\ndocker rm ${containerName} || true\ndocker run -d --name ${containerName} -p ${hostPort}:${containerPort} ${imageName}"

                    def escapedCommands = commands
                        .replace('\\', '\\\\')
                        .replace('"', '\\"')
                        .replace('\r\n', '\\n')
                        .replace('\n', '\\n')

                    writeFile(
                        file: 'ssm-commands.json',
                        text: '{"Parameters":{"commands":["' + escapedCommands + '"]}}'
                    )

                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-ssm-credentials'
                        ]
                    ]) {

                        def commandOutput = bat(
                            script: "\"${AWS_CLI}\" ssm send-command --instance-ids ${EC2_INSTANCE_ID} --document-name \"AWS-RunShellScript\" --parameters file://ssm-commands.json --region ${AWS_DEFAULT_REGION} --query \"Command.CommandId\" --output text",
                            returnStdout: true
                        ).trim()

                        def commandId = commandOutput.readLines().last().trim()

                        echo "SSM Command ID: ${commandId}"

                        def deploymentSuccess = false

                        for (int attempt = 1; attempt <= 24; attempt++) {

                            sleep time: 5, unit: 'SECONDS'

                            def statusOutput = bat(
                                script: "\"${AWS_CLI}\" ssm get-command-invocation --command-id ${commandId} --instance-id ${EC2_INSTANCE_ID} --region ${AWS_DEFAULT_REGION} --query \"Status\" --output text",
                                returnStdout: true
                            ).trim()

                            def status = statusOutput.readLines().last().trim()

                            echo "SSM deployment status: ${status}"

                            if (status == 'Success') {
                                deploymentSuccess = true
                                break
                            }

                            if (status == 'Failed' || status == 'Cancelled' || status == 'TimedOut' || status == 'Cancelling') {

                                def errorOutput = bat(
                                    script: "\"${AWS_CLI}\" ssm get-command-invocation --command-id ${commandId} --instance-id ${EC2_INSTANCE_ID} --region ${AWS_DEFAULT_REGION} --query \"StandardErrorContent\" --output text",
                                    returnStdout: true
                                ).trim()

                                echo "EC2 deployment error:"
                                echo errorOutput

                                error "EC2 deployment failed."
                            }
                        }

                        if (!deploymentSuccess) {
                            error "EC2 deployment timed out."
                        }
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {

                    echo "Running application health check..."

                    bat "powershell -NoProfile -ExecutionPolicy Bypass -File health-check.ps1 \"${env.APP_TYPE}\" \"${EC2_HOST}\""
                }
            }
        }
    }

    post {

        success {
            echo "============================================"
            echo "CI/CD PIPELINE SUCCESSFUL"
            echo "============================================"
            echo "Application: ${env.APP_TYPE}"
            echo "Deployment completed successfully."
        }

        failure {
            echo "============================================"
            echo "CI/CD PIPELINE FAILED"
            echo "============================================"
            echo "Application: ${env.APP_TYPE}"
            echo "Check the failed stage in Jenkins console."
        }

        always {
            echo "Pipeline execution completed."
        }
    }
}
