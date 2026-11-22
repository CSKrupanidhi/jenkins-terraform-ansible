
pipeline {

    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-southeast-2'

        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')

        TF_VAR_public_key_path =
            '/var/lib/jenkins/.ssh/aws-ansible-key.pub'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out GitHub repository'
                checkout scm
            }
        }

        stage('Pre-check') {
            steps {
                sh '''
                    set -eu

                    echo "Checking Terraform"
                    terraform version

                    echo "Checking Git"
                    git --version

                    echo "Checking AWS authentication"
                    aws sts get-caller-identity

                    echo "Checking Jenkins SSH public key"
                    test -f "$TF_VAR_public_key_path"
                '''

                script {
                    def publicIp = sh(
                        script: 'curl -4fsS https://checkip.amazonaws.com',
                        returnStdout: true
                    ).trim()

                    if (!(publicIp ==~ /[0-9]{1,3}(\\.[0-9]{1,3}){3}/)) {
                        error('Could not determine public IPv4 address')
                    }

                    env.TF_VAR_admin_cidr = "${publicIp}/32"

                    echo "SSH access restricted to ${env.TF_VAR_admin_cidr}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Format') {
            steps {
                dir('terraform') {
                    sh 'terraform fmt -check -recursive'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform plan \
                          -input=false \
                          -out=tfplan
                    '''
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input message: 'Review the Terraform plan. Approve AWS EC2 creation?',
                      ok: 'Approve Infrastructure'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform apply \
                          -input=false \
                          -auto-approve \
                          tfplan
                    '''
                }
            }
        }

        stage('Infrastructure Output') {
            steps {
                dir('terraform') {
                    sh 'terraform output'
                }
            }
        }
    }

    post {
        success {
            echo 'AWS infrastructure deployment completed!'
        }

        failure {
            echo 'Pipeline failed. Review the Jenkins console output.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
        }
    }
}

