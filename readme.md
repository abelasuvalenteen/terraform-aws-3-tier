Terraform AWS - 3-Tier Architecture
1. Clone the repo
2. Run below commands
   terraform init
   terraform plan
   terraform apply -auto-approve
   
Jenkins
1. Create a Pipeline Job in Jenkins
2. Configure the repository in the job
3. Apply and Save
4. Run "Build with parameters" 
      input : build (to init, plan and apply using terraform)
              destroy (to destroy using terraform)