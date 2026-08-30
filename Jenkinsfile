pipeline {

    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPOSITORY = 'zomato-app'
        EKS_CLUSTER = 'zomato-eks-cluster'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'

                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing application dependencies...'

                sh 'npm ci'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running application tests...'

                sh 'CI=true npm test -- --watchAll=false --passWithNoTests'
            }
        }

        stage('Build React Application') {
            steps {
                echo 'Building React application...'

                sh 'npm run build'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'

                sh """
                    docker build \
                    -t ${ECR_REPOSITORY}:${IMAGE_TAG} \
                    -t ${ECR_REPOSITORY}:latest .
                """
            }
        }

        stage('Push Image to AWS ECR') {
            steps {
                echo 'Authenticating with AWS ECR...'

                sh """
                    ACCOUNT_ID=\$(aws sts get-caller-identity \
                    --query Account \
                    --output text)

                    aws ecr get-login-password \
                    --region ${AWS_REGION} | \
                    docker login \
                    --username AWS \
                    --password-stdin \
                    \$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com

                    docker tag \
                    ${ECR_REPOSITORY}:${IMAGE_TAG} \
                    \$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

                    docker tag \
                    ${ECR_REPOSITORY}:latest \
                    \$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

                    docker push \
                    \$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

                    docker push \
                    \$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest
                """
            }
        }

        stage('Deploy to EKS Staging') {
            steps {
                echo 'Deploying application to EKS staging...'

                sh """
                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${EKS_CLUSTER}

                    kubectl apply -f k8s/

                    ACCOUNT_ID=\$(aws sts get-caller-identity \
                    --query Account \
                    --output text)

                    kubectl set image deployment/zomato-app \
                    zomato-app=\$ACCOUNT_ID.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

                    kubectl rollout status deployment/zomato-app \
                    --timeout=180s
                """
            }
        }

        stage('Validate Staging') {
            steps {
                echo 'Validating Kubernetes staging deployment...'

                sh 'kubectl get pods -o wide'

                sh 'kubectl get services'

                sh 'kubectl get deployments'
            }
        }

        stage('Promote to Production') {
            steps {

                input message: 'Staging validation passed. Promote this build to production?',
                      ok: 'Deploy to Production'

                echo 'Production promotion approved.'

                sh """
                    kubectl apply -f k8s/production/

                    kubectl rollout status deployment/zomato-app \
                    --timeout=180s
                """
            }
        }
    }

    post {

        success {
            echo '=========================================='
            echo ' Zomato CI/CD Pipeline Completed'
            echo '=========================================='
        }

        failure {
            echo 'Pipeline failed. Check the Jenkins console output.'
        }

        always {
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Build Status: ${currentBuild.currentResult}"
        }
    }
}
