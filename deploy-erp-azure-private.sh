#!/usr/bin/env bash
set -euo pipefail

# Private connectivity deployment for ERP in Azure (App Service + MySQL Flexible Server)
# This script creates a resource group, VNet and subnets, MySQL Flexible Server with private endpoint,
# a private DNS zone, an App Service (Linux) with a container image from ACR, and VNet integration.
# Secrets: provide DB_PASSWORD via env var or prompt at runtime.

# User-configurable via env vars, with sensible defaults
RG="${ERP_RG:-ERP-RG}"
LOCATION="${ERP_LOCATION:-centralus}"
ACR="${ERP_ACR:-erpacr}"
APP_NAME="${ERP_APP_NAME:-erp-app}"
PLAN="${ERP_PLAN:-ERP-Plan}"
DB_NAME="${ERP_DB_NAME:-erp-DB}"
SERVER_NAME="${ERP_MYSQL_SERVER:-erp}"
DB_ADMIN="${ERP_DB_ADMIN:-ddeitjsjlu}"

DB_PASSWORD="${ERP_DB_PASSWORD:-}"

echo "Starting deployment with:"
echo "RG=$RG, LOCATION=$LOCATION, ACR=$ACR, APP_NAME=$APP_NAME, PLAN=$PLAN, DB_NAME=$DB_NAME, SERVER_NAME=$SERVER_NAME"

# Prompt for password if not provided
if [ -z "$DB_PASSWORD" ]; then
  read -s -p "Enter DB admin password: " DB_PASSWORD
  echo
fi

echo "Creating resource group..."
az group create -l "$LOCATION" -n "$RG"

echo "Creating Azure Container Registry if not exists..."
az acr show -g "$RG" -n "$ACR" >/dev/null 2>&1 || az acr create -g "$RG" -n "$ACR" --sku Basic
az acr login --name "$ACR"

echo "Building and pushing Docker image..."
docker build -t "${ACR}.azurecr.io/erp-app:latest" .
docker push "${ACR}.azurecr.io/erp-app:latest"

echo "Creating Virtual Network and subnets..."
az network vnet create -g "$RG" -n ERP-APPVnet --address-prefix 10.0.0.0/16 \
  --subnet-name ERP-APPSubnet --subnet-prefix 10.0.0.0/24
az network vnet subnet create -g "$RG" --vnet-name ERP-APPVnet -n ERP-APPAppSubnet --address-prefix 10.0.1.0/24
az network vnet subnet create -g "$RG" --vnet-name ERP-APPVnet -n ERP-APPDbSubnet --address-prefix 10.0.2.0/24

echo "Creating MySQL Flexible Server (public access disabled by default)..."
az mysql flexible-server create -g "$RG" -l "$LOCATION" -n "$SERVER_NAME" \
  -d "$DB_NAME" --admin-user "$DB_ADMIN" --admin-password "$DB_PASSWORD" \
  --tier GeneralPurpose --sku-name GP_Gen5_2 --version 8.0 \
  --public-network-access Disabled

echo "Creating Database..."
az mysql db create -g "$RG" -s "$SERVER_NAME" -n "$DB_NAME"

echo "Creating Private Endpoint for MySQL..."
SERVER_ID=$(az mysql flexible-server show -g "$RG" -n "$SERVER_NAME" --query id -o tsv)
PE_NAME="mysql-pe-$SERVER_NAME"
az network private-endpoint create -g "$RG" -n "$PE_NAME" --vnet-name ERP-APPVnet --subnet ERP-APPDbSubnet \
  --private-connection-resource-id "$SERVER_ID" --private-connection-name mysql

echo "Private DNS zone setup..."
az network private-dns zone create -g "$RG" -n privatelink.mysql.database.azure.com
az network private-dns link vnet create -g "$RG" -n ERP-privdns-link -z privatelink.mysql.database.azure.com -v ERP-APPVnet --registration-enabled false
private_ip=$(az network private-endpoint ip-config list -g "$RG" -n "$PE_NAME" --query "[0].privateIpAddress" -o tsv)
az network private-dns record-set a add-record -g "$RG" -z privatelink.mysql.database.azure.com -n "$SERVER_NAME" -a "$private_ip"

echo "Creating App Service Plan and Web App..."
az appservice plan create -g "$RG" -n "$PLAN" --sku P1v2 --is-linux
az webapp create -g "$RG" -n "$APP_NAME" -p "$PLAN" --deployment-container-image-name "${ACR}.azurecr.io/erp-app:latest"

echo "Integrating Web App with the Virtual Network..."
az webapp vnet-integration add -n "$APP_NAME" -g "$RG" --vnet ERP-APPVnet --subnet ERP-APPSubnet

echo "Granting acrpull to Web App's identity..."
IDENTITY=$(az webapp identity assign -g "$RG" -n "$APP_NAME" --query principalId -o tsv)
ACR_ID=$(az acr show -g "$RG" -n "$ACR" --query id -o tsv)
az role assignment create --assignee "$IDENTITY" --scope "$ACR_ID" --role acrpull

echo "Configuring environment and DB connection string..."
CONNECTION_STRING="Server=${SERVER_NAME}.privatelink.mysql.database.azure.com;Database=${DB_NAME};User Id=${DB_ADMIN}@${SERVER_NAME};Password=${DB_PASSWORD};SslMode=Require;"
az webapp config appsettings set -g "$RG" -n "$APP_NAME" \
  --settings "ConnectionStrings:DefaultConnection=$CONNECTION_STRING" "ASPNETCORE_ENVIRONMENT=Production"

URL=$(az webapp show -g "$RG" -n "$APP_NAME" --query defaultHostName -o tsv)
echo "ERP Web App URL: https://${URL}"

echo "Done. Recommended follow-ups: enable Application Insights, consider a CI/CD workflow, and define secrets in Azure Key Vault."
