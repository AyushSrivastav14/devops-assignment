import os
from celery import Celery
import time


"""
This module sets up a Celery worker that can process tasks asynchronously. The module is updated to dynamilly read the Redis connection string from an environment variable, allowing for flexible configuration across different environments (e.g., development, staging, production).
"""
# Configure Celery to use Redis as the message broker

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
celery = Celery(
    "worker",  # This is the name of your Celery application
    broker=REDIS_URL,  # This is the Redis connection string
    backend=REDIS_URL,  # for storing task results
)


@celery.task
def write_log_celery(message: str):
    time.sleep(10)
    with open("log_celery.txt", "a") as f:
        f.write(f"{message}\n")
    return f"Task completed: {message}"

