pipeline {
    agent any

    tools {
        jdk 'jdk21'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        TMDB_token   = credentials('TMDB-token')
        JWT_SECRET   = credentials('jwt-secret')
        EMAIL_RECIPIENTS = '22520578@gm.uit.edu.vn'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                checkout scm
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    def targetBranch = env.CHANGE_TARGET ?: 'dev'
                    sh "git fetch --no-tags origin ${targetBranch}:${targetBranch} >/dev/null 2>&1 || true"

                    def changedFiles = sh(
                        returnStdout: true,
                        script: "git diff --name-only origin/${targetBranch}...HEAD || true"
                    ).trim().split("\\r?\\n").findAll { it?.trim() }

                    def backendChanged = changedFiles.any { it.startsWith('backend/') }
                    def frontendChanged = changedFiles.any {
                        it.startsWith('src/') || it.startsWith('public/') || [
                            'Dockerfile', 'nginx.conf', 'package.json', 'yarn.lock', 'vite.config.ts',
                            'tsconfig.json', 'tsconfig.node.json', 'index.html', 'vercel.json'
                        ].contains(it)
                    }

                    env.BUILD_BACKEND = backendChanged ? 'true' : 'false'
                    env.BUILD_FRONTEND = frontendChanged ? 'true' : 'false'

                    echo "Changed files (${changedFiles.size()}): ${changedFiles}"
                    echo "BUILD_BACKEND=${env.BUILD_BACKEND}, BUILD_FRONTEND=${env.BUILD_FRONTEND}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=netflix-clone \
                        -Dsonar.projectKey=netflix-clone
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false,
                        credentialsId: 'sonarqube-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Build & Security Scans') {
            parallel {
                stage('OWASP FS Scan') {
                    steps {
                        dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit',
                                        odcInstallation: 'DP-Check'
                        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                    }
                }

                stage('Trivy FS Scan') {
                    steps {
                        sh 'trivy fs . > trivyfs.txt'
                    }
                }

                stage('Docker Build & Push Images') {
                    when {
                        expression { return env.BUILD_BACKEND == 'true' || env.BUILD_FRONTEND == 'true' }
                    }
                    steps {
                        script {
                            withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker') {
                                sh '''
                                    set -eu

                                    export TMDB_V3_API_KEY=${TMDB_token}
                                    export JWT_SECRET=${JWT_SECRET}

                                    if [ -z "${CHANGE_ID:-}" ]; then
                                      echo "ERROR: Expected PR build (CHANGE_ID missing)."
                                      exit 1
                                    fi
                                    IMAGE_TAG=$((CHANGE_ID * 100 + BUILD_NUMBER))

                                    echo "Using IMAGE_TAG=${IMAGE_TAG}"

                                    if [ "${BUILD_FRONTEND}" = "true" ]; then
                                      docker compose -f docker-compose.ci.yml build frontend
                                      docker tag qhtsg/netflix-frontend:latest "qhtsg/netflix-frontend:${IMAGE_TAG}"
                                      docker push "qhtsg/netflix-frontend:${IMAGE_TAG}"
                                    else
                                      echo "Frontend unchanged -> skip build/push"
                                    fi

                                    if [ "${BUILD_BACKEND}" = "true" ]; then
                                      docker compose -f docker-compose.ci.yml build backend
                                      docker tag qhtsg/netflix-backend:latest  "qhtsg/netflix-backend:${IMAGE_TAG}"
                                      docker push "qhtsg/netflix-backend:${IMAGE_TAG}"
                                    else
                                      echo "Backend unchanged -> skip build/push"
                                    fi
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            when {
                expression { return env.BUILD_BACKEND == 'true' || env.BUILD_FRONTEND == 'true' }
            }
            steps {
                sh '''
                    if [ -z "${CHANGE_ID:-}" ]; then
                      echo "ERROR: Expected PR build (CHANGE_ID missing)."
                      exit 1
                    fi
                    IMAGE_TAG=$((CHANGE_ID * 100 + BUILD_NUMBER))
                    if [ "${BUILD_FRONTEND}" = "true" ]; then
                      trivy image "qhtsg/netflix-frontend:${IMAGE_TAG}"  > trivy-frontend.txt
                    fi
                    if [ "${BUILD_BACKEND}" = "true" ]; then
                      trivy image "qhtsg/netflix-backend:${IMAGE_TAG}"   > trivy-backend.txt
                    fi
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.txt', fingerprint: true

            emailext(
                subject: "[Automail] Jenkins Build ${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                to: "${env.EMAIL_RECIPIENTS}",
                body: """
                    <h2>Jenkins Build Notification</h2>
                    <p><b>Project:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Status:</b> ${currentBuild.currentResult}</p>
                    <p><b>Build URL:</b>
                       <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                    </p>
                """
            )
        }
    }
}
