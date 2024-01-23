function Get-TableData {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TableName
    )
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

            $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
            $sql.Connection = $connection

            # Set the CommandText property to your SQL query
            $sql.CommandText = "SELECT * FROM $tableName"

            # Execute the query and get the result
            $reader = $sql.ExecuteReader()

            # Create a DataTable to hold the result
            $table = New-Object System.Data.DataTable

            # Load the result into the DataTable
            $table.Load($reader)

            # Close the reader
            $reader.Close()

            # Return the DataTable
            return $table
        }
    } catch {
        Write-Error $_.Exception.Message
    } finally {
        # Close the connection
        $connection.Close()
    }
}
Export-ModuleMember -Function Get-TableData
```