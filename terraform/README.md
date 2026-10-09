# Terraform AWS Deployment

This Terraform configuration deploys the React/Vite frontend and Flask backend to Amazon ECS using **EC2 capacity**. It is a learning setup, not a production-ready architecture.

## Architecture

```text
Internet
   |
   | TCP 80 (frontend) and TCP 5000 (backend)
   v
EC2 instance security group
   |
   +-- ECS frontend task: EC2 host port 80 -> container port 5173
   |      Vite serves the React app and calls the backend public IP on port 5000
   |
   +-- ECS backend task: EC2 host port 5000 -> container port 5000
          Flask API

The EC2 instance is registered with the ECS cluster through an Auto Scaling
Group and an ECS capacity provider. Both ECS services use that capacity provider.
```

The default learning settings create **one EC2 instance** (`t3.small`) and one task for each service. The two tasks are separate containers on the same instance, using different host ports. The VPC has two public subnets, but the Auto Scaling Group has `min_size`, `desired_capacity`, and `max_size` all set to `1`.

The frontend task gets `VITE_API_BASE_URL` from Terraform, pointing to the public IP of the running ECS EC2 instance on port `5000`. This project currently runs Vite's development server in the frontend container. The security group exposes ports 80 and 5000 to `0.0.0.0/0` for learning; restrict access before using this design beyond a temporary lab.

## Terraform layout

```text
terraform/
├── main.tf                 # Connects modules and passes their inputs/outputs
├── variables.tf            # Root input variable declarations
├── terraform.tfvars.example # Sample learning environment values
├── terraform.tfvars        # Local values copied from the example (ignored by Git)
├── providers.tf            # AWS provider and default tags
├── versions.tf             # Terraform and AWS provider constraints
├── outputs.tf              # Useful resource names and repository URLs
└── modules/
    ├── networking/         # VPC, public subnets, internet gateway and routes
    ├── security/           # ECS instance security group
    ├── iam/                # ECS instance and task execution roles
    ├── ecr/                # Frontend and backend image repositories
    ├── ecs-cluster/        # ECS cluster
    ├── launch-template/    # ECS-optimized Amazon Linux EC2 launch template
    ├── autoscaling/        # ECS EC2 Auto Scaling Group
    ├── capacity-provider/  # Connects the Auto Scaling Group to ECS
    └── ecs-service/        # Task definitions and frontend/backend services
```

## Default configuration

The checked-in `terraform.tfvars.example` sets these sample values:

| Setting | Value |
| --- | --- |
| AWS region | `ap-south-1` |
| Project/environment | `react-flask-dev` |
| VPC CIDR | `10.20.0.0/16` |
| Public subnets | `10.20.1.0/24`, `10.20.2.0/24` |
| EC2 instance type | `t3.small` |
| Auto Scaling Group minimum/desired/maximum | `1` / `1` / `1` |
| Frontend/backend image tags | `latest` / `latest` |

The ECS cluster and related resource names are derived from `project_name` and `environment`. The ECR repository names are `react-flask-dev-frontend` and `react-flask-dev-backend` with these defaults. The account number is not hard-coded in the Terraform files; Terraform uses the AWS credentials selected by the AWS CLI/provider.

## Prerequisites

- Terraform `>= 1.6.0`
- AWS CLI configured with credentials allowed to create the resources in this configuration
- Docker installed and able to build Linux `amd64` images
- Access to AWS in the configured region

Check which AWS identity is active:

```powershell
aws sts get-caller-identity
aws configure get region
```

The provider region is controlled by `aws_region` in `terraform.tfvars`; the CLI's default region does not override it.

## First deployment

The ECR repositories are Terraform-managed, and the ECS task definitions refer to images in those repositories. On a new deployment, create the repositories first, push the images, and then apply the complete stack.

Run the commands from this directory (`terraform/`):

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform fmt -recursive
terraform init
terraform validate
```

The default Terraform backend stores state locally in this directory. Keep the state file private and backed up; use a remote backend with locking for shared or long-lived environments.

Create the ECR repositories:

```powershell
terraform apply -target=module.ecr
```

Review and approve the plan when Terraform prompts. The targeted apply is only a bootstrap step for the repositories; it does not deploy the full application infrastructure.

Build and push both images from the repository root. Replace the account ID if deploying with a different AWS account:

```powershell
Set-Location ..

$registry = "137631563920.dkr.ecr.ap-south-1.amazonaws.com"

aws ecr get-login-password --region ap-south-1 |
  docker login --username AWS --password-stdin $registry

docker build --platform linux/amd64 -t "$registry/react-flask-dev-backend:latest" .\backend
docker build --platform linux/amd64 -t "$registry/react-flask-dev-frontend:latest" .\frontend

docker push "$registry/react-flask-dev-backend:latest"
docker push "$registry/react-flask-dev-frontend:latest"
```

Confirm the images exist:

```powershell
aws ecr describe-images --repository-name react-flask-dev-frontend --region ap-south-1
aws ecr describe-images --repository-name react-flask-dev-backend --region ap-south-1
```

Then plan and deploy the complete configuration:

```powershell
Set-Location .\terraform

terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
terraform output
```

Review the plan before applying. It should use the existing Terraform-managed ECR repositories and the expected image tags. Avoid applying if the plan proposes unexpected resource replacement or destruction.

## Updating an application image

Rebuild and push the changed image to the same ECR repository/tag, then force a deployment of the service that uses that image. For example, after updating the backend image:

```powershell
aws ecs update-service `
  --cluster react-flask-dev `
  --service react-flask-dev-backend-service `
  --force-new-deployment `
  --region ap-south-1
```

For a changed frontend image, deploy the frontend service instead:

```powershell
aws ecs update-service `
  --cluster react-flask-dev `
  --service react-flask-dev-frontend-service `
  --force-new-deployment `
  --region ap-south-1
```

If Terraform configuration has changed, run `terraform plan` and apply the reviewed plan instead. An ECS task definition revision is created when task definition settings change.

## Verify the deployment

Check the cluster and service counts:

```powershell
aws ecs list-clusters --region ap-south-1

aws ecs describe-services `
  --cluster react-flask-dev `
  --services react-flask-dev-frontend-service react-flask-dev-backend-service `
  --region ap-south-1 `
  --query "services[].{name:serviceName,desired:desiredCount,running:runningCount,pending:pendingCount}"
```

For each service, the expected learning state is `desired = 1`, `running = 1`, and `pending = 0`.

Get the current public IP of the ECS EC2 instance and test the endpoints:

```powershell
$ip = aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=react-flask-dev-ecs-instance" "Name=instance-state-name,Values=running" `
  --region ap-south-1 `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text

Write-Output "Frontend: http://$ip/"
Write-Output "Backend:  http://$ip`:5000/"

curl.exe "http://$ip/"
curl.exe "http://$ip`:5000/"
curl.exe "http://$ip`:5000/save"
curl.exe "http://$ip`:5000/data"
```

The public IP can change if the EC2 instance is replaced or restarted. Retrieve it again rather than relying on a previously copied address.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `terraform` says there are no configuration files | Run Terraform from `terraform/`, the directory containing `main.tf` and `terraform.tfvars`. |
| ECS reports `CannotPullImageManifestError` | Confirm the task definition image URI/tag and that the image exists in the matching ECR repository. |
| Tasks remain pending or stop | Inspect service events and stopped-task reasons with `aws ecs describe-services` and `aws ecs describe-tasks`. |
| Frontend does not load | Check that the EC2 instance is running, port 80 is allowed, and the frontend task maps host port 80 to container port 5173. |
| Frontend loads but API requests fail | Check `VITE_API_BASE_URL`, backend task health, port 5000 access, and Flask CORS configuration. |
| Terraform reports an AWS identity/credentials error | Check `aws sts get-caller-identity`, credentials, network access, and `aws_region`. |
| Terraform proposes ECR repository creation unexpectedly | Confirm the working directory and Terraform state. Do not apply until the intended repositories and state are understood. |

## Data persistence and production cautions

Docker Compose mounts a named volume for local backend data. The ECS task definition does **not** currently mount durable storage, so data written inside the backend container's `/app/data` can be lost when that task is replaced.

This setup also has a single EC2 instance, no load balancer, a public development server, and public access to the Flask port. These choices are intended to make the learning flow visible and inexpensive to understand, not to provide production-grade availability or security. In particular, restrict inbound traffic and use durable storage and a production frontend server before adapting it for real users.

## Destroying the learning infrastructure

Destroying the stack removes the Terraform-managed AWS resources and may incur charges until they are removed. ECR repositories containing images may need to be emptied before AWS allows Terraform to delete them. Confirm the target account and region, then review the destroy plan:

```powershell
terraform plan -destroy
terraform destroy
```
