pipeline{
    agent any
    tools{
        jdk 'jdk21'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
        TMDB_token=credentials('TMDB-token')
        EMAIL_RECIPIENTS = 'quanghuytran335577@gmail.com'  
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/qht-nice/netflix-clone-devsecops.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=netflix-clone \
                    -Dsonar.projectKey=netflix-clone '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonarqube-token' 
                }
            } 
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker'){   
                       sh "docker build --build-arg TMDB_V3_API_KEY=${TMDB_token} -t netflix ."
                       sh "docker tag netflix qhtsg/netflix:latest "
                       sh "docker push qhtsg/netflix:latest "
                    }
                }
            }
        }
        stage("TRIVY"){
            steps{
                sh "trivy image qhtsg/netflix:latest > trivyimage.txt" 
            }
        }
        stage('Deploy to container'){
            steps{
                sh '''                    
                    docker rm -f netflix || true
                    docker run -d --name netflix -p 8081:80 qhtsg/netflix:latest
                '''
            }
        }
    }
    post {
        always {
            emailext (
                subject: "[Automail] Jenkins Build ${currentBuild.currentResult}: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                    <h2>Jenkins Build Notification</h2>
                    <p><strong>Project:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> #${env.BUILD_NUMBER}</p>
                    <p><strong>Build Status:</strong> ${currentBuild.currentResult}</p>
                    <p><strong>Build Duration:</strong> ${currentBuild.durationString}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">View Console</a></p>
                    <hr>
                """,
                mimeType: 'text/html',
                to: "${env.EMAIL_RECIPIENTS}",
            )
        }
    }
}