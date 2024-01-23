
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