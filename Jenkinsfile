
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['BUILD', 'DESTROY'],
            description: 'Choose whether to create or destroy AWS infrastructure'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-southeast-2'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        TF_VAR_public_key_path = '/var/lib/jenkins/.ssh/aws-ansible-key.pub'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Pre-check') {
            steps {
                sh '''
                    set -eu
                    terraform version
                    aws sts get-caller-identity
                    test -f "$TF_VAR_public_key_path"
                '''

                script {
                    def publicIp = sh(
                        script: 'curl -4fsS https://checkip.amazonaws.com',
                        returnStdout: true
                    ).trim()

                    withEnv(["CHECK_PUBLIC_IP=${publicIp}"]) {
                        sh '''
                            python3 -c "
		import ipaddress, os
		ipaddress.IPv4Address(os.environ['CHECK_PUBLIC_IP'])
		"
                        '''
                    }

                    env.TF_VAR_admin_cidr = "${publicIp}/32"
                    echo "SSH CIDR: ${env.TF_VAR_admin_cidr}"
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

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Verify Terraform State') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "Current Terraform state:"
                        terraform state list
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    script {
                        if (params.ACTION == 'BUILD') {
                            sh 'terraform plan -input=false -out=tfplan'
                        } else {
                            sh 'terraform plan -destroy -input=false -out=destroy.tfplan'
                        }
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                script {
                    if (params.ACTION == 'BUILD') {
                        input message: 'Approve AWS infrastructure creation?',
                              ok: 'Approve BUILD'
                    } else {
                        input message: 'WARNING: Approve destruction of AWS infrastructure?',
                              ok: 'Approve DESTROY'
                    }
                }
            }
        }

        stage('Terraform Execute') {
            steps {
                dir('terraform') {
                    script {
                        if (params.ACTION == 'BUILD') {
                            sh 'terraform apply -input=false -auto-approve tfplan'
                        } else {
                            sh 'terraform apply -input=false -auto-approve destroy.tfplan'
                        }
                    }
                }
            }
        }

        stage('Infrastructure Result') {
            steps {
                dir('terraform') {
                    script {
                        if (params.ACTION == 'BUILD') {
                            sh 'terraform output'
                        } else {
                            sh 'terraform state list'
                            echo 'Infrastructure destruction completed.'
                        }
                    }
                }
            }
        }

	stage('Generate Ansible Inventory') {
	    when {
	        expression { params.ACTION == 'BUILD' }
	    }
	    steps {
	        script {
	            def ec2Ip

	            dir('terraform') {
	                ec2Ip = sh(
	                    script: 'terraform output -raw public_ip',
	                    returnStdout: true
	                ).trim()
	            }

	            if (!ec2Ip) {
	                error('EC2 public IP not found')
	            }

	            sh 'mkdir -p ansible/inventory'

	            writeFile(
	                file: 'ansible/inventory/hosts.ini',
	                text: """[webservers]
	${ec2Ip} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/aws-ansible-key
	"""
	            )

	            echo "Generated Ansible inventory for ${ec2Ip}"
	        }
	    }
	}
    }



    post {
        success {
            echo "Pipeline completed successfully: ${params.ACTION}"
        }
        failure {
            echo 'Pipeline failed. Review the console output.'
        }
        always {
            echo 'Pipeline execution finished.'
        }
    }
}
