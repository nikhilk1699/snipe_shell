## This GitHub Actions workflow is designed to automate the deployment of infrastructure using Terraform to an Azure environment. 
```
name: Sample GitHub Action

on:
  push:
    branches:
      - nikhil-kadam

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID_N }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET_N }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID_N }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID_N }}
  ROOT_PATH: '${{github.workspace}}/azure_tga'

# Use the Bash shell regardless whether the GitHub Actions runner is ubuntu-latest, macos-latest, or windows-latest
defaults:
  run:
    shell: bash
jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Check out code
        uses: actions/checkout@v2          

      - name: setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
        
      - name: Terraform Init
        run: |
          terraform init
        working-directory: ${{env.ROOT_PATH}}
      - name: Terraform plan
        run: |
          terraform plan
        working-directory: ${{env.ROOT_PATH}}
      - name: Terraform apply
        run: |
          terraform apply -auto-approve
        working-directory: ${{env.ROOT_PATH}}
```
### Trigger:
- The workflow is triggered on a push event to the specified branch nikhil-kadam.
### Environment Variables:
Azure-related environment variables are defined using GitHub Secrets. These include:
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_SUBSCRIPTION_ID
- ARM_TENANT_ID
- ROOT_PATH: The root path for Terraform configuration (azure_tga directory in the GitHub workspace).
### Defaults:
The default shell for running commands is set to Bash.

### Jobs:
The workflow contains a single job named "build" that runs on the latest version of Ubuntu.

### Steps:

- Checkout Code:
  Utilizes the actions/checkout action to fetch the source code.
- Setup Terraform:
Utilizes the hashicorp/setup-terraform action to set up Terraform, using an API token from GitHub Secrets for authentication.
- Terraform Init:
Runs the terraform init command to initialize the Terraform configuration. Specifies the working directory as the root path defined earlier.
- Terraform Plan:
Executes the terraform plan command to generate an execution plan. Specifies the working directory as the root path.
- Terraform Apply:
Runs terraform apply -auto-approve to apply the changes to the infrastructure.
The -auto-approve flag ensures that Terraform automatically approves and applies changes without manual confirmation.

![11](https://github.com/nikhilk1699/snipe_shell/assets/109533285/95f7f96f-0e2e-4279-b03c-a6b7ed46e1a7)
![Screenshot 2023-11-10 134047](https://github.com/nikhilk1699/snipe_shell/assets/109533285/cfae0883-1d3b-47a2-9706-0c6c419e1e31)
![Screenshot 2023-11-10 134008](https://github.com/nikhilk1699/snipe_shell/assets/109533285/81abc109-9de7-490e-83a3-408c8849af19)
![32](https://github.com/nikhilk1699/snipe_shell/assets/109533285/1d19ca5a-f662-4b83-b217-9cd804cdcde9)
















