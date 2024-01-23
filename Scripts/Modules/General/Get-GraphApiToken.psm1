function Get-GraphApiToken {
    # Set parameters: subject, tenant ID, application ID and certificate thumbprint
    param(
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [Parameter(Mandatory=$true)]
        [string]$Application
    )
    # Get the tenant ID, application ID and certificate thumbprint
    $tenantId = (Get-AzSubscription -SubscriptionId $SubscriptionId).TenantId
    $clientId = (Get-AzADApplication -DisplayNameStartWith $Application).AppId
    $Thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -eq $Subject }).Thumbprint
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My\ | Where-Object { $_.Thumbprint -eq $thumbprint }
    
    # Define the token endpoint
    $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

    # Check if the certificate was found
    if ($null -eq $cert) {
        throw "Certificate with thumbprint $thumbprint not found."
    }

    # Define the request body
    $body = @{
        "client_id" = $clientId
        "client_assertion_type" = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        "client_assertion" = [System.Convert]::ToBase64String($cert.RawData)
        "scope" = "https://graph.microsoft.com/.default"
        "grant_type" = "client_credentials"
    }

    # Send the request
    $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body $body

    # Return the access token
    return $response.access_token
}
Export-ModuleMember -Function Get-GraphApiToken
```