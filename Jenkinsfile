pipeline {
    agent any

    environment {
        MYSQL_USER     = credentials('MYSQL_USER')
        MYSQL_PASSWORD = credentials('MYSQL_PASSWORD')
        MYSQL_DB       = credentials('MYSQL_DB')
        MYSQL_ROOT_PASSWORD = credentials('MYSQL_ROOT_PASSWORD')
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker compose up -d --build'
            }
        }
    }


    post {
        always {
            sh 'az logout || true'
        }
        success {
            echo "Deployed ${IMAGE_NAME}:${IMAGE_TAG} to Azure App Service successfully!"
        }
        failure {
            echo "Deployment failed. Check the logs for details."
        }
    }
}
