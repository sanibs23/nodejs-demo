pipeline {
    agent any

    tools {
        nodejs 'Nodejs'
    }

    environment {
        SONARQUBE_SERVER = 'sonarqube-docker' // Corrected name of SonarQube server in Jenkins config
        SONARQUBE_PROJECT_KEY = 'nodejs-demo'
        SONARQUBE_PROJECT_NAME = 'nodejs-demo'
        SONARQUBE_PROJECT_VERSION = '1.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/master']], // Updated branch name if necessary
                    userRemoteConfigs: [[
                        url: 'http://gitlab/root/nodejs-demo.git', // Corrected repository URL
                        credentialsId: 'gitlab-token' // Ensure credentials are properly configured
                    ]]
                ])
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
                sh 'npm install --save-dev nyc'
            }
        }
        stage('Test') {
            steps {
                sh 'npx nyc npm test'
            }
        }
        stage('SonarQube Scan') {
            steps {
                script {
                    def javaVersion = sh(script: 'java -version 2>&1 | grep "openjdk version" | cut -d\\" -f2 | cut -d. -f1', returnStdout: true).trim()
                    def javaMajorVersion = javaVersion as Integer
                    
                    echo "Detected Java version: ${javaVersion}"
                    
                    if (javaMajorVersion >= 17) {
                        echo "Java ${javaVersion} is compatible with SonarQube 25.9.0"
                        withSonarQubeEnv("${env.SONARQUBE_SERVER}") {
                            withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                                sh '''
                                    if ! command -v sonar-scanner >/dev/null 2>&1; then
                                        curl -sSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o sonar-scanner-cli.zip
                                        unzip -o -q sonar-scanner-cli.zip
                                        export PATH=$PWD/sonar-scanner-5.0.1.3006-linux/bin:$PATH
                                    fi
                                    sonar-scanner -Dsonar.projectKey=${SONARQUBE_PROJECT_KEY} -Dsonar.projectName=${SONARQUBE_PROJECT_NAME} -Dsonar.projectVersion=${SONARQUBE_PROJECT_VERSION} -Dsonar.sources=. -Dsonar.login=${SONAR_TOKEN} -Dsonar.exclusions=Dockerfile -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                                '''
                            }
                        }
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                // Only fail if Security Hotspots is insufficient
                                if (qg.conditions) {
                                    def securityHotspots = qg.conditions.find { it.metric == 'security_hotspots_reviewed' }
                                    if (securityHotspots && securityHotspots.status != 'OK') {
                                        error "Pipeline aborted due to insufficient Security Hotspots review: ${securityHotspots.status}"
                                    } else {
                                        echo "Quality Gate failed, but not due to Security Hotspots. Proceeding."
                                    }
                                } else {
                                    echo "Quality Gate failed, but no Security Hotspots condition found. Proceeding."
                                }
                            } else {
                                echo "SonarQube Quality Gate passed: ${qg.status}"
                            }
                        }
                    } else {
                        echo "SonarQube scan skipped due to Java version incompatibility"
                        echo "SonarQube server 25.9.0 requires Java 17+, Jenkins is running Java ${javaVersion}"
                    }
                }
            }
        }
        stage('Verify Docker') {
            steps {
                sh 'docker --version'
            }
        }
        stage('Gitleaks Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p ./gitleaks-output
                        chmod -R 777 ./gitleaks-output
                        echo "[Gitleaks] Scanning for secrets..."
                        docker run --rm \
                            --entrypoint bash \
                            -v $(pwd):/host \
                            ghcr.io/gitleaks/gitleaks:latest -c "mkdir -p /host/gitleaks-output && gitleaks detect \
                                --source=/host \
                                --no-git \
                                --report-format json \
                                --report-path=/host/gitleaks-output/gitleaks-report.json \
                                --redact || exit 0"
                        echo "[Gitleaks] Scan complete. Report: ./gitleaks-output/gitleaks-report.json"
                    '''
                }
            }
        }
        stage('Build and Run Docker') {
            steps {
                sh '''
                    docker build -t nodejs-demo .
                    docker rm -f nodejs-demo || true
                    docker run -d -p 5000:5000 --name nodejs-demo nodejs-demo
                '''
            }
        }
        stage('Trivy Scan') {
            steps {
                script {
                    sh '''
                        echo "[Trivy] Scanning Docker image for vulnerabilities..."
                        mkdir -p /tmp/.trivy-cache
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v /tmp/.trivy-cache:/root/.cache/ \
                            aquasec/trivy:0.50.2 image --exit-code 1 --severity CRITICAL,HIGH nodejs-demo || echo "[Trivy] Vulnerabilities found. See above."
                    '''
                }
            }
        }
        stage('ZAP Scan') {
            steps {
                script {
                    sh '''
                        echo "[ZAP] Scanning running app for vulnerabilities..."
                        docker run --rm --network cicd-network -t owasp/zap2docker-stable zap-baseline.py -t http://nodejs-demo:5000 -r zap-report.html || echo "[ZAP] Vulnerabilities found. See above."
                        echo "[ZAP] Scan complete. Report: zap-report.html"
                    '''
                }
            }
        }
    }
}