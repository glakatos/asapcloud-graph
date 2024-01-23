function New-ServicePrincipalWithCertificate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$keyValue,

        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
    )

    # Create a new service principal and assign the certificate to it
    $sp = New-AzADServicePrincipal -DisplayName azureGraphApiApp `
      -CertValue $keyValue `
      -EndDate $cert.NotAfter `
      -StartDate $cert.NotBefore

    # Wait for the service principal to be propagated
    Start-Sleep 20
  
    # Optional: Assign a role to the service principal. Example: Reader
    New-AzRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $sp.ApplicationId
}

Export-ModuleMember -Function New-ServicePrincipalWithCertificate