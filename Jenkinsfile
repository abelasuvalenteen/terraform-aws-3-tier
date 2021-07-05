pipeline {
    agent {
      node {
        label "win_slave"
      }
    }

    parameters {
        string(defaultValue: "build", description: "Input build or destroy", name: "buildType")
    }

    options { skipDefaultCheckout() }

    stages {
        stage('Pull Source Code') {
            steps {
               script {
                   // Clean Workspace before start
                   cleanWs()

                   // Get code from GitHub repository
                   git(
                    url: 'https://github.com/abelasuvalenteen/terraform-oci.git',
                    branch: 'master'
                    )
               }
            }
        }

        stage('Infra Setup') {
            steps {
               script {
                 if("${params.buildType}".equalsIgnoreCase("build")) {
                   echo "Building : Infra"
                   bat """
                       cd ${WORKSPACE}
                       terraform init
                       terraform plan
                       terraform apply -auto-approve
                   """
                  } else {
                   echo "Running Destroy"
                   bat """
                      cd ${WORKSPACE}
                      terraform destroy -auto-approve
                  """
                  }
               }
            }
        }
    }

    post {
        success {
            echo "Job Success"
        }
        failure {
            echo "Job Failed"
        }
    }
}
