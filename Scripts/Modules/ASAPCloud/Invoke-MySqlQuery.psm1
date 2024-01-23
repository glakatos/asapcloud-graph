# Description: Function to execute a query on the MySql database

function Invoke-MySqlQuery {
    # Set parameters: query and database
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        [Parameter(Mandatory = $true)]
        [string]$Database
    )
    # Check if the current script has a path
    if ($PSCommandPath) {
        # If the script has a path, set the path as the default path
        $path = Split-Path -Parent $PSCommandPath
    }
    else {
        # If the script doesn't have a path, set the current directory as the default path
        $path = "C:\Program Files (x86)\MySQL\MySQL Connector NET 8.2.0"
    }

    try {
        # Create a new instance of the MySqlConnection class from the MySql.Data.MySqlClient namespace
        $connection = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
    }
    catch {
        # Handle any exceptions that occur during the creation of the MySqlConnection object
        [void][system.reflection.Assembly]::LoadFrom($path + "\MySql.Data.dll")
        $connection = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
    }
    
    if ($connection) {
        # Set the connection string
        $server = "asapcloud-portal-test-mysqldbserver.mysql.database.azure.com"
        $username = "portal@" + $server.Replace(".mysql.database.azure.com", "")
        $password = "0S\d?G:A2OR!/f6tP{(9!C*}"

        $connection.ConnectionString = "SERVER=$server;DATABASE=$database;UID=$username;PWD=$password;Allow Zero Datetime=True;"
        
        # Open the connection
        $connection.Open()
      
        # Create a new instance of the MySqlCommand class from the MySql.Data.MySqlClient namespace
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        # Set the connection for the MySqlCommand object
        $sql.Connection = $connection
        
        # Set the time zone to Europe/Amsterdam
        $sql.CommandText = "set time_zone='Europe/Amsterdam'"
        # Execute the query
        $sql.ExecuteNonQuery() | Out-Null
        
        # Set the query
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        # Set the connection for the MySqlCommand object
        $sql.Connection = $connection
        # Set the query
        $sql.CommandText = $query

        # Create a new instance of the MySqlDataAdapter class from the MySql.Data.MySqlClient namespace
        $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($sql)
        # Create a new instance of the DataSet class from the System.Data namespace
        $dataSet = New-Object System.Data.DataSet

        # Fill the DataSet object with data from the database
        $dataAdapter.Fill($dataSet) | Out-Null

        # Close the connection
        if ($dataset.Tables[0] -and $dataset.Tables[0] -ne "") {
            # Return the data
            $return = $dataSet.Tables[0] | Select-Object ($dataSet.Tables[0] | Get-Member -MemberType Property).name 
        }
        
        $connection.Close()
    }
    # If the connection couldn't be created, return an error
    else {
        Write-Error "Unable to create connection, please check if MySql.Data.dll is available"
    }
    # If the connection was created, return the data
    if ($return) {
        return $return
    }
}
Export-ModuleMember -Function Invoke-MySqlQuery
```