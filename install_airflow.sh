#!/bin/bash

# Setup environment variables
export AIRFLOW_HOME=~/airflow
export AIRFLOW_VERSION=3.3.1
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export PATH=$PATH:~/.local/bin

# Install uv and initialize virtual environment
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv ~/.venv
source ~/.venv/bin/activate

# Install Apache Airflow
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
uv pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# Initialize DB and configure refresh interval
airflow db migrate
sed -i 's/^refresh_interval\s*=.*/refresh_interval = 15/' $AIRFLOW_HOME/airflow.cfg

# Run Airflow in background
setsid airflow standalone < /dev/null > ~/airflow/standalone.log 2>&1 &
disown

# Wait for and display generated credentials
sleep 10
cat ~/airflow/simple_auth_manager_passwords.json.generated