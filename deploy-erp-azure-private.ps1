<#
.SYNOPSIS
Deploy ERP privately to Azure using App Service (Linux) + MySQL Flexible Server with a Private Endpoint.

.DESCRIPTION
Creates RG, VNets and subnets, private MySQL, Private Endpoint + DNS, ACR, App Service Plan, Web App (container),
and VN integration. Sets a private ConnectionStrings:DefaultConnection and Production environment.

.PARAMETERS
ResourceGroup - RG name (default: ERP-RG)
Location - Azure region (default: canadacentral)
Acr - Azure Container Registry name (default: erpacr)
AppName - Web App name (default: erp-app)
Plan - App Service Plan name (default: ERP-Plan)
DbName - MySQL database name (default: erp-DB)
ServerName - MySQL server name (default: erp)
DbAdmin - DB admin user (default: ddeitjsjlu)
DbPassword - DB admin password (optional; prompt if not supplied)

.EXAMPLE
powershell -ExecutionPolicy Bypass -File deploy-erp-azure-private.ps1 -ResourceGroup ERP-RG -Location canadacentral -Acr erpacr -AppName erp-app -Plan ERP-Plan -DbName erp-DB -ServerName erp -DbAdmin ddeitjsjlu
#>

param(
  [string]$ResourceGroup = "ERP-RG",
  [string]$Location = "canadacentral",
  [string]$Acr = "erpacr",
  [string]$AppName = "erp-app",
  [string]$Plan = "ERP-Plan",
  [string]$DbName = "erp-DB",
  [string]$ServerName = "erp",
  [string]$DbAdmin = "ddeitjsjlu",
  [string]$DbPassword
)

# Preflight: Ensure Azure CLI (az) is installed and accessible
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  Write-Host "Azure CLI (az) not found on PATH." -ForegroundColor Yellow
  Write-Host "Choose an option to proceed:" -ForegroundColor Yellow
  Write-Host "1) Install Azure CLI for Windows: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
  Write-Host "2) Open Azure Cloud Shell in your browser: https://shell.azure.com" -ForegroundColor Yellow
  Write-Host "3) Exit" -ForegroundColor Yellow
  $choice = Read-Host "Enter 1, 2, or 3"
  switch ($choice) {
    '1' { Start-Process "https://aka.ms/installazurecliwindows"; Exit 1 }
    '2' { Start-Process "https://shell.azure.com"; Exit 1 }
    '3' { Write-Host "Exiting."; Exit 1 }
    default { Write-Host "Invalid choice. Exiting."; Exit 1 }
  }
}
else {
  Write-Host "Azure CLI is available. Proceeding with deployment..." -ForegroundColor Green
}

# Prereqs: az CLI must be installed and logged in
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  Write-Error "Azure CLI (az) not found. Please install Azure CLI and run az login."
  exit 1
}

# Prompt for DB password if not provided
if (-not $DbPassword) {
  $sec = Read-Host -AsSecureString "Enter DB admin password"
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
  $PlainPwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $DbPassword = $PlainPwd
}

Write-Host "Deployment config: RG=$ResourceGroup, Location=$Location, ACR=$Acr, AppName=$AppName, Plan=$Plan, DbName=$DbName, ServerName=$ServerName"

# 1) Ensure Resource Group exists
$rgExists = az group exists -n $ResourceGroup | ConvertFrom-Json
if (-not $rgExists.exists) {
  Write-Host "Creating resource group $ResourceGroup in $Location"
  az group create -l $Location -n $ResourceGroup | Out-Null
}

# 2) Ensure ACR exists
try {
  az acr show -n $Acr -g $ResourceGroup | Out-Null
  $acrExists = $true
} catch {
  $acrExists = $false
}
if (-not $acrExists) {
  Write-Host "Creating ACR $Acr"
  az acr create -g $ResourceGroup -n $Acr --sku Basic | Out-Null
}
az acr login --name $Acr

# 3) Build and push Docker image
Write-Host "Building Docker image..."
docker build -t "$Acr.azurecr.io/erp-app:latest" .
docker push "$Acr.azurecr.io/erp-app:latest"

# 4) Create VNets and subnets
Write-Host "Creating VNets and subnets..."
az network vnet create -g $ResourceGroup -n ERP-APPVnet --address-prefix 10.0.0.0/16
az network vnet subnet create -g $ResourceGroup --vnet-name ERP-APPVnet -n ERP-APPSubnet --address-prefix 10.0.1.0/24
az network vnet subnet create -g $ResourceGroup --vnet-name ERP-APPVnet -n ERP-APPDbSubnet --address-prefix 10.0.2.0/24

# 5) Create MySQL Flexible Server (private)
Write-Host "Creating MySQL Flexible Server (private)..."
az mysql flexible-server create -g $ResourceGroup -l $Location -n $ServerName -d $DbName `
  --admin-user $DbAdmin --admin-password $DbPassword `
  --tier GeneralPurpose --sku-name GP_Gen5_2 --version 8.0 `
  --public-network-access Disabled

Write-Host "Creating Database..."
az mysql db create -g $ResourceGroup -s $ServerName -n $DbName

# 6) Private Endpoint and DNS
$PeName = "mysql-pe-$ServerName"
$ServerId = az mysql flexible-server show -g $ResourceGroup -n $ServerName --query id -o tsv
az network private-endpoint create -g $ResourceGroup -n $PeName --vnet-name ERP-APPVnet --subnet ERP-APPDbSubnet --private-connection-resource-id $ServerId --private-connection-name mysql

Write-Host "DNS setup..."
az network private-dns zone create -g $ResourceGroup -n privatelink.mysql.database.azure.com
az network private-dns link vnet create -g $ResourceGroup -n ERP-privdns-link -z privatelink.mysql.database.azure.com -v ERP-APPVnet --registration-enabled false
$privateIP = az network private-endpoint ip-config list -g $ResourceGroup -n $PeName --query "[0].privateIpAddress" -o tsv
az network private-dns record-set a add-record -g $ResourceGroup -z privatelink.mysql.database.azure.com -n $ServerName -a $privateIP

# 7) App Service Plan & Web App
Write-Host "Creating App Service Plan (Linux)..."
az appservice plan create -g $ResourceGroup -n $Plan --sku P1v2 --is-linux
Write-Host "Creating Web App..."
az webapp create -g $ResourceGroup -n $AppName -p $Plan --deployment-container-image-name "$Acr.azurecr.io/erp-app:latest"

Write-Host "Integrating Web App with VNet..."
az webapp vnet-integration add -n $AppName -g $ResourceGroup --vnet ERP-APPVnet --subnet ERP-APPSubnet

# 8) Grant ACR pull for Web App identity
Write-Host "Granting acrpull..."
$Identity = az webapp identity assign -g $ResourceGroup -n $AppName --query principalId -o tsv
$AcrId = az acr show -g $ResourceGroup -n $Acr --query id -o tsv
az role assignment create --assignee $Identity --scope $AcrId --role acrpull

# 9) App Settings (production connection string)
$Conn = "Server=${ServerName}.privatelink.mysql.database.azure.com;Database=${DbName};User Id=${DbAdmin}@${ServerName};Password=${DbPassword};SslMode=Require;"
az webapp config appsettings set -g $ResourceGroup -n $AppName --settings "ConnectionStrings:DefaultConnection=$Conn" "ASPNETCORE_ENVIRONMENT=Production"

# 10) URL
$Url = az webapp show -g $ResourceGroup -n $AppName --query defaultHostName -o tsv
Write-Host "ERP Web App URL: https://$Url"
