# Description: This function will import devices from Graph API into the database

# Import the modules
Import-Module -Name "D:\Repos\asapcloud-graph\Scripts\Modules\Connect-GraphApi.psm1"
function Import-Devices {
    try {
        Add-Type -Path 'C:\Program Files (x86)\MySQL\MySQL Connector NET 8.2.0\MySql.Data.dll'

        # Define your connection string (replace with your actual server, database, user and password)
        $server = "glakatosdemosql.mysql.database.azure.com"
        $database = "demo"
        $uid = "glakatos"
        $password = "P@ssw0rd"
        $connectionString = "server=$server;database=$database;uid=$uid;pwd=$password;"

        # Create a new MySqlConnection object with the connection string
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)

        # Open the connection
        $connection.Open()

        # Create a new MySqlCommand object
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $connection

        # Call the Connect-GraphApi function to authenticate with Microsoft Graph API
        $Subject = "CN=GraphApiPowerShell App-Only"
        $SubscriptionId = "6747d176-a3d1-49a6-b54b-760c30ee1622"
        $Application = "AsapProtalGraphApi"
        Connect-GraphApi -Subject $Subject -SubscriptionId $SubscriptionId -Application $Application

        # Use the PowerShell Graph API cmdlets to get the devices
        $devices = Get-MgDevice | Select-Object -Property DeviceId,DisplayName

        # Show the devices
        Write-Output $devices

        # Iterate over the list of devices
        foreach ($device in $devices) {
            # Set the CommandText property to your SQL query
            $sql.CommandText = @"
INSERT INTO cmdb (DeviceId, DisplayName) VALUES ('$($device.deviceId)', '$($device.displayName)')
"@

            # Execute the query
            $sql.ExecuteNonQuery()
        }
    }
    catch {
        # Handle the exception
        Write-Output "An error occurred: $_"
    }
}
Export-ModuleMember -Function Import-Devices

