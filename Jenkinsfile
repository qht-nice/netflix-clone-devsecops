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
                // Multibranch/PR builds: build the actual PR source (not hardcoded main)
                checkout scm
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
                    steps {
                        script {
                            withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker') {
                                sh '''
                                    set -euo pipefail

                                    export TMDB_V3_API_KEY=${TMDB_token}
                                    export JWT_SECRET=${JWT_SECRET}

                                    # PR-only tagging strategy (numeric + changes every build):
                                    # - CHANGE_ID is the PR number (e.g. 21)
                                    # - BUILD_NUMBER increments for each run of the PR job
                                    # Combine them into a single numeric tag so Image Updater (allow-tags: ^[0-9]+$) can track it.
                                    # Assumes BUILD_NUMBER < 10000
                                    if [ -z "${CHANGE_ID:-}" ]; then
                                      echo "ERROR: Expected PR build (CHANGE_ID missing)."
                                      exit 1
                                    fi
                                    IMAGE_TAG=$((CHANGE_ID * 10000 + BUILD_NUMBER))

                                    echo "Using IMAGE_TAG=${IMAGE_TAG}"

                                    docker compose -f docker-compose.ci.yml build
                                    docker tag qhtsg/netflix-frontend:latest "qhtsg/netflix-frontend:${IMAGE_TAG}"
                                    docker tag qhtsg/netflix-backend:latest  "qhtsg/netflix-backend:${IMAGE_TAG}"

                                    # PR-only: do NOT push :latest (avoid clobbering)
                                    docker push "qhtsg/netflix-frontend:${IMAGE_TAG}"
                                    docker push "qhtsg/netflix-backend:${IMAGE_TAG}"
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Trivy Image Scan (2 Images)') {
            steps {
                sh '''
                    # Keep this aligned with IMAGE_TAG above.
                    if [ -z "${CHANGE_ID:-}" ]; then
                      echo "ERROR: Expected PR build (CHANGE_ID missing)."
                      exit 1
                    fi
                    IMAGE_TAG=$((CHANGE_ID * 10000 + BUILD_NUMBER))
                    trivy image "qhtsg/netflix-frontend:${IMAGE_TAG}"  > trivy-frontend.txt
                    trivy image "qhtsg/netflix-backend:${IMAGE_TAG}"   > trivy-backend.txt
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
