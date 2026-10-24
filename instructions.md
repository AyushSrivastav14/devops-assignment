# Local Setup Instructions

This guide provides step-by-step instructions for developers to run the Task Notifier stack locally using Docker Compose.

## Prerequisites

Before you begin, ensure you have the following installed on your machine:

* **Git**: To clone the repository.
* **Docker Engine**: To run the containers.
* **Docker Compose (V2)**: The modern compose plugin (accessible via `docker compose`).

## Step 1: Clone the Repository

First, clone the project repository to your local machine and navigate into the root directory:

```bash
git clone https://github.com/AyushSrivastav14/devops-assignment.git
cd devops-assignment
```

## Step 2: Launch the Application

The entire multi-service stack (FastAPI backend, Celery worker, Redis broker, and Nginx frontend) is orchestrated via Docker Compose.

To build the images and start the containers in detached mode, run:

```bash
docker compose up --build -d
```

Docker will pull the necessary base images, build the custom backend and frontend images, and spin up the network.

## Step 3: Access the Application

Once the containers are successfully running, the Nginx reverse proxy will route traffic on port 80.

1. Open your web browser.
2. Navigate to **http://localhost**

*(Note: If the page does not load and you are using WSL, please see the Troubleshooting section below).*

## Step 4: Test the End-to-End Flow

1. On the web interface, enter an email address and click **Send Notification**.
2. The UI will instantly display a `WAITING` or `PENDING` status and the newly generated Task ID.
3. The Nginx reverse proxy handles routing this to the FastAPI backend, which enqueues the task in Redis.
4. The Celery worker picks up the task and processes it.
5. The frontend polls the backend every 2 seconds until the status dynamically updates to `COMPLETED` and displays the final result payload.

## Step 5: Stop the Environment

When you are finished testing, you can gracefully stop and remove the containers, networks, and volumes by running:

```bash
docker compose down
```

---

## Troubleshooting

### 1. Cannot access `localhost` on WSL (Windows Subsystem for Linux)
**Issue:** If you are running Docker natively inside WSL rather than using Docker Desktop, Windows may not automatically resolve `localhost` to the WSL network.

**Solution:** Connect directly to the WSL virtual machine's IP address.
1. Run `hostname -I` in your WSL terminal to get your local IP address.
2. Look for the first IP address listed (e.g., `192.168.105.87`).
3. Navigate directly to that IP in your Windows browser: `http://<your-wsl-ip>`

### 2. Docker Compose V1 vs V2 Errors
**Issue:** You receive a `docker: unknown command: docker compose` error, or experience Python traceback errors when starting the stack.

**Solution:** This project requires the modern Docker Compose V2 specification (invoked with a space: `docker compose`). If you are running an older Linux/WSL setup, you might still have the legacy Python-based V1 executable (`docker-compose`) installed.

To upgrade to the official V2 plugin on Ubuntu/Debian-based systems, run these commands:

```bash
# 1. Remove the legacy version
sudo apt-get remove docker-compose

# 2. Install the modern Docker Compose CLI plugin
sudo apt-get install docker-compose-plugin

# 3. Verify the installation (should output v2.x.x or higher)
docker compose version
```