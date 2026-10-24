# Journey & Architectural Decisions

This document outlines the thought process, architectural decisions, and challenges navigated while containerizing the Task Notifier application and preparing it for cloud deployment.

## 1. Architectural Decisions

### Nginx Decoupling & API Routing

Instead of exposing the FastAPI backend directly, I implemented an Nginx reverse proxy. This allowed me to serve the static single-page frontend (`index.html`) while seamlessly routing API requests (`/notify/` and `/task_status/`) to the backend. This decoupling makes the application highly portable and mirrors production-grade environments where static assets and APIs are routed through a single entry point.

### Dynamic Nginx Configuration for Cloud Portability

A significant networking difference exists between local Docker Compose and AWS Fargate. Locally, Docker's DNS resolves the hostname `backend` to the API container. However, in AWS Fargate, containers grouped within the same Task Definition share an Elastic Network Interface (ENI) and must communicate over `localhost` (127.0.0.1).
To make the Nginx image truly portable without altering code between environments, I utilized `envsubst` to inject a `BACKEND_HOST` environment variable into an `nginx.conf.template` at startup.

### Application Code Refactoring: FastAPI & Celery Integration

A critical code-level decision involved resolving the task queuing logic. I updated `backend/main.py` to explicitly import the `celery` app instance directly from the `worker` module. This structural change ensures a clean separation of concerns, avoids circular dependency crashes, and guarantees that when the FastAPI routes trigger a background task, they enqueue it onto the exact same Celery instance that the worker container is configured to consume.

## 2. Enterprise Cloud & Infrastructure Strategy

To satisfy the requirement to maximize managed cloud services, I designed the AWS infrastructure using a strict, multi-tier enterprise network architecture provisioned entirely via Terraform.

### VPC, Subnet Isolation, and NAT Gateway (`network.tf`)
Rather than placing the compute instances in a default public network, the Fargate tasks are deployed into **Private Subnets**. They are assigned no public IP addresses, making them inaccessible from the open internet. To allow the Fargate tasks to securely pull Docker images from the container registry, I provisioned a **NAT Gateway** in the public subnets to handle outbound-only traffic.

### Application Load Balancer (`alb.tf`)
To allow users to access the frontend, I provisioned an **Application Load Balancer (ALB)** in the public subnets. The ALB terminates the incoming HTTP connections, inspects the traffic, and routes valid requests to the Nginx reverse proxy running inside the private Fargate task via an IP-based Target Group.

### Zero-Trust Security Groups (`security.tf`)
Network security is enforced at the interface level. I configured the Security Groups so that the Fargate containers explicitly reject all inbound traffic unless it originates directly from the ALB's security group. This ensures that even if internal routing is compromised, the application compute layer remains isolated.

### Observability: Container Insights & CloudWatch
Locally, log monitoring is handled via Docker Compose `stdout` aggregation. To translate this to the cloud, the Fargate tasks are configured with the `awslogs` logging driver to stream all container output directly to **Amazon CloudWatch**. Furthermore, I explicitly enabled **ECS Container Insights** on the cluster resource. This provides out-of-the-box, cloud-native telemetry, automatically tracking CPU, memory utilization, and network metrics for the microservices.

### CI/CD and Container Registry

I implemented a GitHub Actions workflow (`ci-cd.yaml`) to automatically build and push the Docker images upon code merges. While an enterprise AWS environment would securely utilize Amazon ECR, I configured the CI/CD pipeline to push to **Docker Hub** for this assignment. This ensures the Docker images remain public and easily accessible, allowing reviewers to instantly pull and test the application without needing to configure their own AWS IAM credentials.

## 3. Challenges & Troubleshooting

### Docker Compose Legacy vs. V2

During local testing, I encountered syntax errors stemming from the legacy `docker-compose` binary (`v1`). I migrated the environment to the modern `docker compose` plugin (`v2`), which natively supports the updated Compose specification used in this project.

### WSL Host Networking

Testing the Nginx frontend locally inside Windows Subsystem for Linux (WSL) presented a known networking hurdle. Accessing `localhost` from the Windows browser occasionally failed to route to the WSL container bridge. This was resolved by identifying the explicit WSL eth0 IP address (`ip addr show eth0` or `hostname -I`) and accessing the application via that direct IP, bypassing the Windows `localhost` loopback discrepancy.