# Docker Compose Learning Project

A small full-stack application used to learn Docker, Docker Compose, and AWS ECS. It has a React/Vite frontend and a Flask backend.

## Project structure

```text
.
├── backend/                 # Flask API and Docker image
├── frontend/                # React + Vite app and Docker image
├── terraform/               # AWS infrastructure and ECS deployment
├── compose.yml              # Local multi-container setup
└── README.md
```

See the [Terraform deployment guide](terraform/README.md) for the AWS architecture, module descriptions, deployment procedure, and troubleshooting.

## Run locally with Docker Compose

From the project root:

```powershell
$env:VITE_API_BASE_URL = "http://localhost:5000"
docker compose up --build
```

Open the frontend at `http://localhost:3000`. The Flask API is available at `http://localhost:5000`. The frontend makes API requests from the browser, so this override makes its backend URL resolve on your computer. Compose connects the containers on a private bridge network and stores backend data in a named volume.

Stop the local services with:

```powershell
docker compose down
```

## Application endpoints

- `GET /` — backend health/message response
- `GET /save` — append sample data to the backend data file
- `GET /data` — read the saved data

## Cloud deployment

Terraform provisions an EC2-backed ECS cluster, networking, IAM, security groups, an Auto Scaling Group and capacity provider, ECR repositories, task definitions, and ECS services. The learning configuration keeps one EC2 instance and runs one frontend task and one backend task on that same instance.

Start with [`terraform/README.md`](terraform/README.md). It includes the safe first-deployment order: create the ECR repositories, build and push the images, then apply the full Terraform configuration.
