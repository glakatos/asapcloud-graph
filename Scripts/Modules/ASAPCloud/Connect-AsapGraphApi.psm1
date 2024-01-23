# Module to authenticate app with Azure Graph API
# Description: This function will provide "Access without a user" to Azure AD Graph API, using a Service Principal(Application) with certificate, and return the Graph context

function Connect-GraphApi {
    # Set parameters: subject, tenant ID, application ID and certificate thumbprint
    param(
        [Parameter(Mandatory=$true)]
        [string]$subject,
        [Parameter(Mandatory=$true)]
        [string]$subscriptionId,
        [Parameter(Mandatory=$true)]
        [string]$application
    )
    # Get the tenant ID, application ID and certificate thumbprint
    $tenantId = (Get-AzSubscription -SubscriptionId $subscriptionId).tenantId
    $applicationId = (Get-AzADApplication -DisplayNameStartWith $application).AppId
    $thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -eq $subject }).Thumbprint

    # Authenticate with the Graph API using the certificate
    # Note: https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/2127
    try {
        Connect-MgGraph -TenantId $tenantId -CertificateThumbprint $thumbprint -ClientId $applicationId        
        # Get the Graph context
        $graphContext = Get-MgContext | Select-Object -Property Scopes
    }
    catch {
        Write-Output "An error occurred: $_"    }

    # Return the Graph context
    return $graphContext
}
Export-ModuleMember -Function Connect-GraphApi