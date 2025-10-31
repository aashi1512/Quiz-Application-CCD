pipeline {
    agent any
    
    environment {
        PROJECT_ID = credentials('gcp-project-id')
        APP_NAME = 'quiz-app'
        REGION = 'us-central1'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        GCR_IMAGE = "gcr.io/${PROJECT_ID}/${APP_NAME}"
    }
    
    stages {
        stage('🔍 Checkout') {
            steps {
                echo '📥 Checking out code...'
                checkout scm
            }
        }
        
        stage('🧪 Test') {
            steps {
                echo '🔬 Running tests...'
                dir('backend') {
                    sh '''
                        python3 -m pip install -r requirements.txt
                        python3 -c "import app; print('✅ App OK')"
                    '''
                }
            }
        }
        
        stage('🐳 Build & Push Docker') {
            steps {
                echo '📦 Building Docker image...'
                dir('backend') {
                    sh """
                        gcloud builds submit \
                          --tag ${GCR_IMAGE}:${IMAGE_TAG} \
                          --tag ${GCR_IMAGE}:latest \
                          --project ${PROJECT_ID}
                    """
                }
            }
        }
        
        stage('🚀 Deploy to Cloud Run') {
            steps {
                echo '☁️  Deploying...'
                sh """
                    CONNECTION_NAME=\$(gcloud sql instances describe quiz-db-instance \
                      --project ${PROJECT_ID} \
                      --format='value(connectionName)')
                    
                    gcloud run deploy ${APP_NAME} \
                      --image ${GCR_IMAGE}:${IMAGE_TAG} \
                      --platform managed \
                      --region ${REGION} \
                      --project ${PROJECT_ID} \
                      --allow-unauthenticated \
                      --add-cloudsql-instances \$CONNECTION_NAME \
                      --set-env-vars DB_HOST=/cloudsql/\$CONNECTION_NAME \
                      --set-env-vars DB_NAME=quizdb \
                      --set-env-vars DB_USER=postgres \
                      --set-env-vars DB_PASSWORD=YourStrongCloudPassword123 \
                      --set-env-vars JWT_SECRET=prod-jwt-secret-xyz-123 \
                      --memory 512Mi \
                      --cpu 1 \
                      --quiet
                """
            }
        }
        
        stage('🏥 Health Check') {
            steps {
                sh """
                    SERVICE_URL=\$(gcloud run services describe ${APP_NAME} \
                      --region ${REGION} \
                      --project ${PROJECT_ID} \
                      --format='value(status.url)')
                    
                    sleep 5
                    curl -f \${SERVICE_URL}/health
                    echo "✅ Health check passed!"
                """
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}