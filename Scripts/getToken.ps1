# Request an access token using the certificate
# The following PowerShell script will request an access token using the certificate. The script will use the certificate thumbprint to find the certificate in the certificate store. The certificate is then used to request an access token from Azure AD. The access token is then used to call the Microsoft Graph API.

# Check if the MSAL.PS module is installed. If not, install it.
if (-not (Get-Module -Name MSAL.PS)) {
    Install-Module -Name MSAL.PS -Scope CurrentUser
} else {
    Write-Host "MSAL.PS module is already installed"
}

# Define your tenant ID, client ID, and certificate thumbprint
$TenantId = (Get-AzSubscription -SubscriptionId "589c1433-e4c6-49d2-a68c-ad15941faf0e").TenantId
$clientId = (Get-AzADApplication -DisplayNameStartWith AsapProtalGraphApi).AppId
$Thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -eq "CN=ASAPCloudGraphApiPowerShell App-Only" }).Thumbprint

# Get the certificate from the certificate store
$certificate = Get-ChildItem -Path Cert:\CurrentUser\My\ | Where-Object {$_.Thumbprint -eq $thumbprint}

# Request the access token
$token = Get-MsalToken -ClientId $clientId -TenantId $tenantId -Certificate $certificate

# Output the access token
$token.AccessToken