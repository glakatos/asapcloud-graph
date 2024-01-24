<#PSScriptInfo
.SYNOPSIS
    Function to import devices from Microsoft Graph API into a MySql database
.VERSION 1.0.0
.GUID we3213e2-3213-3213-3213-3213e3213e32
.AUTHOR Gabor Lakatos - galakatos@asapcloud.com
.DESCRIPTION
    This module uses the Microsoft Graph Powershell SDK to connect to the Graph API and extract devices. The fields are then mapped to a MySql database and inserted into the database.
    This module relies on the Connect-AsapGraphApi function to connect to the Graph API.
.PARAMETER
    $subscriptionId
        The subscription ID of the Azure subscription where the Graph API app is registered
    $tenantId
        The tenant ID of the Azure AD tenant where the Graph API app is registered
    $subject
        The subject of the Certificate used to authenticate to the Graph API aka the CN
    $application
        The name of the Graph API app that has the required permissions to access the Graph API
    $fieldMapping
        A hashtable that defines the mapping between the Graph API fields and the target database columns. The keys are the Graph API fields and the values are the database columns.
        Update this hashtable to match your database schema.
.EXAMPLE
    cd to\the\folder\where\the\module\is\located
    Import-Module -Name .\Import-AsapDevices.psm1
    Import-MgDevices
.NOTES
    Make sure to update the 'Add-Type -Path' to match the location of the MySql.Data.dll file on your system.
    This file is usually located in C:\Program Files (x86)\MySQL\MySQL Connector NET 8.2.0\MySql.Data.dll
    The connector can be downloaded from https://dev.mysql.com/downloads/connector/net/
.LINK
    https://www.giraffeacademy.com/databases/sql/
.ISSUE
    Fields that are not mapped, but are present in the database schema and do not allow null values will cause an error such as:
        Exception calling "ExecuteNonQuery" with "0" argument(s): "Field 'vendor' doesn't have a default value"
        Exception calling "ExecuteNonQuery" with "0" argument(s): "Column 'vendor' cannot be null"

    As a workaround, you can update the database schema to allow null values for these fields or you can update the field mapping to include these fields:
    The mysql query to update the schema so it allows null values:
        ALTER TABLE cmdb MODIFY vendor VARCHAR(255);
.BUG
#>
Import-Module -Name .\Connect-AsapGraphApi.psm1
function Import-MgDevices {

    # Define variables
    $subscriptionId = "6747d176-a3d1-49a6-b54b-760c30ee1622"
    $tenantId = "60922053-03d2-40e3-837a-5ca3fca7102b"
    $subject = "CN=ASAPCloudGraphApiPowerShell App-Only"
    $application = "AsapProtalGraphApi"

    # Connect to Azure if not already connected
    if (-not (Get-AzContext)) {
        Connect-AzAccount -tenantId $tenantId
        Set-AzContext -SubscriptionId $subscriptionId
    }
    
    # Connect to Graph API
    Connect-GraphApi -subject $subject -subscriptionId $subscriptionId -application $application

    # Extract devices from Graph API
    $devices = Get-MgDevice | Select-Object -Property ProfileType,DisplayName,EnrollmentProfileName,Id,DeviceOwnership,OperatingSystem,ComplianceExpirationDateTime,ApproximateLastSignInDateTime,RegistrationDateTime

    # Map fields: Define a mapping between the Graph API fields (on the left) and the database columns (on the right)
    $fieldMapping = @{
        "ProfileType"                   = "type";
        "DisplayName"                   = "name";
        "EnrollmentProfileName"         = "description";
        "Id"                            = "serialNumber";
        "DeviceOwnership"               = "userId";
        "OperatingSystem"               = "operatingSystem";
        "ComplianceExpirationDateTime"  = "warrantyDate";
        "ApproximateLastSignInDateTime" = "lastSeen";
        "RegistrationDateTime"          = "creationDate"
    }

    # Transorm data: for each device, create a new object where the property names align with the database columns
    $transformedDevices = $devices | ForEach-Object {
        $device = $_
        $transformedDevice = New-Object PSObject  
        $fieldMapping.GetEnumerator() | ForEach-Object {
            $transformedDevice | Add-Member -NotePropertyName $_.Value -NotePropertyValue $device.($_.Key)
        }
        $transformedDevice
    }

    # Store Data: Connect to your MySql database and insert the data
    try {
        Add-Type -Path 'C:\Program Files (x86)\MySQL\MySQL Connector NET 8.2.0\MySql.Data.dll'
        $connectionString = "server=dbglakatos.mysql.database.azure.com;port=3306;database=devices;uid=glakatos;pwd=P@ssw0rd"
        $conn = New-Object MySql.Data.MySqlClient.MySqlConnection
        $conn.ConnectionString = $connectionString
        $conn.Open()
    
        $transformedDevices | ForEach-Object {
            $device = $_
            $command = $conn.CreateCommand()
            $command.CommandText = "INSERT INTO cmdb (type,name,description,serialNumber,userId,operatingSystem,warrantyDate,lastSeen,creationDate) VALUES (@ProfileType,@DisplayName,@EnrollmentProfileName,@Id,@DeviceOwnership,@OperatingSystem,@ComplianceExpirationDateTime,@ApproximateLastSignInDateTime,@RegistrationDateTime);"
            $command.Parameters.AddWithValue("@ProfileType", $device.type)
            $command.Parameters.AddWithValue("@DisplayName", $device.name)
            $command.Parameters.AddWithValue("@EnrollmentProfileName", $device.description)
            $command.Parameters.AddWithValue("@Id", $device.serialNumber)
            $command.Parameters.AddWithValue("@DeviceOwnership", $device.userId)
            $command.Parameters.AddWithValue("@OperatingSystem", $device.operatingSystem)
            $command.Parameters.AddWithValue("@ComplianceExpirationDateTime", $device.warrantyDate)
            $command.Parameters.AddWithValue("@ApproximateLastSignInDateTime", $device.lastSeen)
            $command.Parameters.AddWithValue("@RegistrationDateTime", $device.creationDate)
            $command.ExecuteNonQuery()
        }
    
        $conn.Close()    
    }
    catch {
        # Output error message into a log file with the current date and time
        $errorMessage = $_.Exception.Message
        $logDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $fileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $logFile = ".\Logs\Import-AsapDevices-$fileDate.log"
        $logMessage = "$logDate - $errorMessage"
        Add-Content -Path $logFile -Value $logMessage

    }
}
Export-ModuleMember -Function Import-MgDevices