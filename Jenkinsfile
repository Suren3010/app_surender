pipeline {
    agent any
    environment {
        MSBUILD_HOME = tool 'VisualStudio2022'
        DOTNET_SCANNER_HOME= tool 'sonar_scanner_dotnet'
        SONARQUBE_SERVER = 'Test_Sonar'
        SONARQUBE_CREDENTIALS_ID = 'sonarqube'
        PROJECT_KEY= 'sonar-surender'
        VSTEST_CONSOLE_HOME= tool 'vstest.console'
        BUILD_AND_PUBLISH_DOCKER_IMAGE= 'false'
    }
    options {
        timeout(time: 1, unit: 'HOURS') 
    }
    stages {
        
        stage("Nuget restore") {
            steps {
                bat "\"${MSBUILD_HOME}\\MSBuild.exe\" nagp-devops-us.sln -t:restore"
            }
        }
        stage("Start sonarqube analysis") {
            when {
                branch 'master'
            }
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
        stage("Release artifact") {
            when {
                branch 'develop'
            }
            steps {
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
            when {
                branch 'master'
            }
            steps {
                  withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    withCredentials([string(credentialsId: "${SONARQUBE_CREDENTIALS_ID}", variable: "sonar_token")]) {
                        bat "dotnet ${DOTNET_SCANNER_HOME}\\SonarScanner.MSBuild.dll end /d:sonar.login=\"${sonar_token}"
                    }
                  }
            }
        }
        //** By default this step get ignored but we can change env variable to 'true' if want to push latest image
        stage("Build and push docker image") {
            when {
                environment name: 'BUILD_AND_PUBLISH_DOCKER_IMAGE', value: 'true'
            }
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
                    bat returnStdout: true, script: "kubectl apply -f .\\K8s\\"
                }
            }
         }
     }
 }
