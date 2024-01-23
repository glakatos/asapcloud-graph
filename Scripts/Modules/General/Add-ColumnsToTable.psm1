function Add-ColumnsToTable {
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

    # Check the connection state
    if ($connection.State -eq 'Open') {
        Write-Output "Successfully connected to the database."
    } else {
        Write-Output "Failed to connect to the database."
    }
} catch {
    Write-Output "An error occurred: $_"
}
if ($connection.State -eq 'Open') {
    try {
        # Create a new MySqlCommand object
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand

        # Set the Connection property to your MySqlConnection object
        $sql.Connection = $connection

    # Add the 'DeviceId' and 'DisplayName' columns to the 'cmdb' table
    $sql.CommandText = @"
ALTER TABLE cmdb
ADD COLUMN DeviceId VARCHAR(255),
ADD COLUMN DisplayName VARCHAR(255)
"@

        # Execute the query
        $sql.ExecuteNonQuery()
    }
    catch {
        Write-Output "An error occurred: $_"
    }
    finally {
        # Close the connection
        $connection.Close()
    }
}
}
Export-ModuleMember -Function Add-ColumnsToTable
```