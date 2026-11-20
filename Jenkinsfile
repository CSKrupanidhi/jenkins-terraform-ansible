pipeline {
    agent any

    stages {
        stage('Welcome') {
            steps {
                echo 'Welcome to Jenkins Terraform Ansible Project!'
            }
        }

        stage('Check Tools') {
            steps {
                sh 'git --version'
                sh 'terraform version'
                sh 'ansible --version'
                sh 'aws --version'
            }
        }

        stage('Project Information') {
            steps {
                echo 'Our DevOps automation project is ready!'
            }
        }
    }
}
