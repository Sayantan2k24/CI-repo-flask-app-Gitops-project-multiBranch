pipeline {
    agent any
    environment {
        DOCKERHUB_USERNAME = "sayantan2k21"
        APP_NAME = "flask-multibranch-gitops-example"
        IMAGE_TAG = "v1.0-${BUILD_NUMBER}"
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/${APP_NAME}"
        REGISTRY_CREDS = 'docker-cred'
        BRANCH = "release/v1.0"
    }

    
    stages {
        stage('Cleanup Workspace') {
            steps {
                // including the groovy script in the declarative pipeline
                script {
                    cleanWs()
                }
            }
        }
        
        stage('Checkout SCM') {
            steps {
                git branch: 'release/v1.0',
                credentialsId: 'git-cred',
                url: 'https://github.com/Sayantan2k24/CI-repo-flask-app-Gitops-project-multiBranch.git'
            }
        }

        stage('Build Docker Image') {
            steps{
                // use docker commands on shell
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."

                    // image name total --> sayantan2k21/flask-multibranch-gitops-example:v1.0-1 for build number 1

                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-cred', passwordVariable: 'pass', usernameVariable: 'user')]) {
                    sh """
                        echo ${pass} | docker login --username ${user} --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }
        stage('Delete Image locally') {
            steps {
                 sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                 sh "docker rmi ${IMAGE_NAME}:latest"
            }
        }

        stage('Updating Kubernetes Deployment File') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'git-cred', passwordVariable: 'pass', usernameVariable: 'user')]) {
                        sh """
                            # cd Repo --> https://github.com/Sayantan2k24/CD-repo-flask-app-Gitops-project-multiBranch.git
                            
                            git clone -b ${BRANCH} https://${user}:${pass}@github.com/Sayantan2k24/CD-repo-flask-app-Gitops-project-multiBranch.git
                            cd CD-repo-flask-app-Gitops-project-multiBranch

                            echo "Original deployment.yaml contents:"
                            cat deployment.yaml
                            
                            echo "Image Tag Change Initiating.."
                            sed -i "s|image: docker.io/${IMAGE_NAME}:.*|image: docker.io/${IMAGE_NAME}:${IMAGE_TAG}|g" deployment.yaml
                            
                            echo "Updated YAML file contents:"
                            cat deployment.yaml
                            
                            git config user.email "sayantansamanta12102001@gmail.com"
                            git config user.name "Sayantan"
                            
                            git add deployment.yaml
                            git commit -m "Updated image tag to ${IMAGE_TAG}"
                            git push origin ${BRANCH}
                            
                        """
                    
                    }
       
                }
            }
        }
        
        
    }
}
