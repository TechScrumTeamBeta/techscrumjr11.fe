properties([
    parameters([
        choice(choices: ['plan', 'apply', 'destroy'], name: 'Terraform_Action')
    ])
])

pipeline {
    agent any
    tools {
        terraform 'terraform'
    }
    stages {
        stage('Preparing') {
            steps {
                sh 'echo Preparing'
            }
        }
        stage('Git Checkout') {
            steps {
                git branch: 'lidi', url: 'https://github.com/TechScrumTeamBeta/techscrumjr11.fe'
            }
        }
        stage('Init') {
            steps {
                withAWS(credentials: 'aws-lidi-jr', region: 'ap-southeast-2') {
                sh 'terraform -chdir=terraform init'
                }
            }
        }
        stage('Action') {
            steps {
                echo "${params.Terraform_Action}"
                withAWS(credentials: 'aws-lidi-jr', region: 'ap-southeast-2') {
                script {   
                        if (params.Terraform_Action == 'plan') {
                            sh 'terraform -chdir=terraform plan'
                        }   else if (params.Terraform_Action == 'apply') {
                            sh 'terraform -chdir=terraform apply -auto-approve'
                        }   else if (params.Terraform_Action == 'destroy') {
                            sh 'terraform -chdir=terraform destroy -auto-approve'
                        } else {
                            error "Invalid value for Terraform_Action: ${params.Terraform_Action}"
                        }
                    }
                }
            }
        }
    }
}