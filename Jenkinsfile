pipeline {
    agent any
    environment {
        MSBUILD_HOME = tool 'VisualStudio2022'
        DOTNET_SCANNER_HOME= tool 'sonar_scanner_dotnet'
        SONARQUBE_SERVER = 'Test_Sonar'
        SONARQUBE_CREDENTIALS_ID = 'sonarqube'
        PROJECT_KEY = 'sonar-surender'
        VSTEST_CONSOLE_HOME = tool 'vstest.console'
    }
    options {
        timeout(time: 1, unit: 'HOURS') 
    }
    stages {
        stage("Checkout code from version control") {
            steps {
                checkout poll: false, scm: [$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/Suren3010/app_surender.git']]]
            }
        }
        stage("Nuget restore") {
            steps {
                bat "\"${MSBUILD_HOME}\\MSBuild.exe\" nagp-devops-us.sln -t:restore"
            }
        }
        stage("Start sonarqube analysis") {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    withCredentials([string(credentialsId: "${SONARQUBE_CREDENTIALS_ID}", variable: "sonar_token")]) {
                        bat "dotnet ${DOTNET_SCANNER_HOME}\\SonarScanner.MSBuild.dll begin /k:\"${PROJECT_KEY}\" /d:sonar.login=\"${sonar_token}"
                    }
                }
            }
        }
        stage("Code build") {
            steps {
                bat "\"${MSBUILD_HOME}\\MSBuild.exe\" nagp-devops-us.sln /p:Configuration=Release /p:Platform=\"Any CPU\" /p:ProductVersion=1.0.0.${env.BUILD_NUMBER}"
                dotnetPublish configuration: 'Release', project: 'nagp-devops-us/nagp-devops-us.csproj', sdk: 'dotnet-sdk', selfContained: false
            }
        }
        stage("Test case execution") {
            when {
                branch 'master'
            }
            steps {
                bat "${VSTEST_CONSOLE_HOME} test-project\\bin\\Release\\netcoreapp3.1\\test-project.dll /EnableCodeCoverage /Logger:trx"
            }
        }
        stage("Stop sonarqube analysis") {
            steps {
                  withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    withCredentials([string(credentialsId: "${SONARQUBE_CREDENTIALS_ID}", variable: "sonar_token")]) {
                        bat "dotnet ${DOTNET_SCANNER_HOME}\\SonarScanner.MSBuild.dll end /d:sonar.login=\"${sonar_token}"
                    }
                  }
            }
        }
        stage("Build and push docker image") {
            steps {
               script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub2') {
                        def dockerImage = docker.build("surender3010/i-surender-${BRANCH_NAME}:latest")
                        dockerImage.push("latest")
                    }
                }
            }
        }
        stage("Kubernetes deployment") {
           steps {
               script {
                    withCredentials([file(credentialsId: 'GCP_CRED', variable: 'FILE')]) {
                        bat returnStdout: true, script: "gcloud auth activate-service-account --key-file ${FILE}"
                        bat returnStdout: true, script: "kubectl apply -f nagp-devops-us.deployment.yaml"
                   }
               }
           }
        }
    }
}
