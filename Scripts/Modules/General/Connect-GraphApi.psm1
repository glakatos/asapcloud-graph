# Module to authenticate app with Azure Graph API
# Description: This function will provide "Access without a user" to Azure AD Graph API, using a Service Principal(Application) with certificate, and return the Graph context

function Connect-GraphApi {
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
    $TenantId = (Get-AzSubscription -SubscriptionId $SubscriptionId).TenantId
    $ApplicationId = (Get-AzADApplication -DisplayNameStartWith $Application).AppId
    $Thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -eq $Subject }).Thumbprint

    # Authenticate with the Graph API using the certificate
    # Note: https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/2127
    try {
        Connect-MgGraph -TenantId $TenantId -CertificateThumbprint $Thumbprint -ClientId $ApplicationId        
        # Get the Graph context
        $graphContext = Get-MgContext | Select-Object -Property Scopes
    }
    catch {
        Write-Output "An error occurred: $_"    }

    # Return the Graph context
    return $graphContext
}
Export-ModuleMember -Function Connect-GraphApi
```