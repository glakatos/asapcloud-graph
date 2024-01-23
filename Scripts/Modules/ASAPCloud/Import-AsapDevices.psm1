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
.EXAMPLE
.NOTES
.LINK
.ISSUE
.BUG
#>
Import-Module -Name .\Connect-AsapGraphApi.psm1
function Import-MgDevices {

    # Define variables
    $subscriptionId = ""
    $tenantId = ""
    $subject = ""
    $application = ""

    # Connect to Azure if not already connected
    if (-not (Get-AzContext)) {
        Connect-AzAccount -tenantId $tenantId
        Set-AzContext -SubscriptionId $subscriptionId
    }
    
    # Connect to Graph API
    Connect-GraphApi -subject $subject -subscriptionId $subscriptionId -application $application

    # Extract devices from Graph API
    $devices = Get-MgDevice | Select-Object -Property DisplayName, EnrollmentProfileName, OperatingSystem

    # Map fields: Define a mapping between the Graph API fields and the database columns
    $fieldMapping = @{
        "DisplayName"           = "Name";
        "EnrollmentProfileName" = "type";
        "OperatingSystem"       = "description"
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
    $connectionString = "server=dbglakatos.mysql.database.azure.com;port=3306;database=devicesdemo;uid=glakatos;pwd=P@ssw0rd"
    $conn = New-Object MySql.Data.MySqlClient.MySqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()

    $transformedDevices | ForEach-Object {
        $device = $_
        $command = $conn.CreateCommand()
        $command.CommandText = "INSERT INTO devices (type,name,description) VALUES (@DisplayName, @EnrollmentProfileName, @OperatingSystem)"
        $command.Parameters.AddWithValue("@DisplayName", $device.name)
        $command.Parameters.AddWithValue("@EnrollmentProfileName", $device.type)
        $command.Parameters.AddWithValue("@OperatingSystem", $device.description)
        $command.ExecuteNonQuery()
    }

    $conn.Close()
}
Export-ModuleMember -Function Import-MgDevices