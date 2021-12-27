#!/bin/bash
#az login --allow-no-subscriptions
az login --use-device-code --allow-no-subscriptions
az account list -o table --all --query "[].{TenantID: tenantId, Subscription: name, Default: isDefault} "

