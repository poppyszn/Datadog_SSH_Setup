#!/bin/bash

# Set your Datadog API key
export DD_API_KEY="<Datadog_API_Key>"

# Set the Datadog site (e.g., "datadoghq.com" for US, "datadoghq.eu" for EU)
export DD_SITE="datadoghq.eu"

# Enable APM instrumentation at the host level (if desired)
export DD_APM_INSTRUMENTATION_ENABLED=host

# Fetch and execute the Datadog agent installation script
bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"
