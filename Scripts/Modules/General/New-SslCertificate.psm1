function New-SslCertificate {
        param(
                [Parameter(Mandatory=$true)]
                [string]$Subject,

                [Parameter(Mandatory=$true)]
                [string]$FilePath
        )

        # Certificates are stored in the ..\Certificate folder. Modify the path if needed.
        $cert = New-SelfSignedCertificate -Subject $Subject `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable `
            -KeySpec Signature `
            -KeyLength 2048 `
            -KeyAlgorithm RSA -HashAlgorithm SHA256

        # Export the certificate to a file
        Export-Certificate -Cert $cert -FilePath $FilePath
}

Export-ModuleMember -Function New-SslCertificate
```