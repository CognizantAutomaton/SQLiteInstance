class SQLiteInstance {
    # https://www.sqlitetutorial.net/sqlite-tutorial/
    [System.Data.SQLite.SQLiteConnection]$con
    [System.Data.SQLite.SQLiteTransaction]$transaction = $null

    SQLiteInstance($sqlite_path) {
        if ($sqlite_path.Length -eq 0) {
            throw "SQLiteInstance requires path to a valid SQLite database"
        } elseif (-not (Test-Path -LiteralPath $sqlite_path)) {
            throw "Error establishing connection to provided path: '$sqlite_path'"
        }

        $this.con = New-Object -TypeName System.Data.SQLite.SQLiteConnection
        $this.con.ConnectionString = "Data Source=`"$sqlite_path`";Version=3;"
        $this.con.Open()
    }

    [void]BeginTransaction() {
        $this.transaction = $this.con.BeginTransaction()
    }

    [void]CommitTransaction() {
        if ($null -eq $this.transaction) {
            throw "Transaction not open for instance"
        } else {
            $this.transaction.Commit()
            $this.transaction = $null
        }
    }

    [void]RollbackTransaction() {
        if ($null -eq $this.transaction) {
            throw "Transaction not open for instance"
        } else {
            $this.transaction.Rollback()
            $this.transaction = $null
        }
    }

    [System.Data.DataSet]Query([string]$sql_statement, [HashTable]$params) {
        # helpful queries:
        # SELECT name FROM sqlite_master
        # Pragma table_info (object_data)
        [System.Data.SQLite.SQLiteCommand]$cmd = $this.con.CreateCommand()
        $cmd.CommandText = $sql_statement

        if ($null -ne $params) {
            foreach ($p in $params.GetEnumerator()) {
                $cmd.Parameters.AddWithValue($p.Name, $p.Value)
            }
        }

        $adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $cmd
        $dataset = New-Object System.Data.DataSet
        [void]$adapter.Fill($dataset)
        return $dataset
    }

    [System.Data.DataSet]Query([string]$sql_statement) {
        return $this.Query($sql_statement, $null)
    }

    [HashTable]Execute([string]$sql_statement, [HashTable]$params) {
        [System.Data.SQLite.SQLiteCommand]$cmd = $this.con.CreateCommand()
        $cmd.CommandText = $sql_statement

        if ($null -ne $params) {
            foreach ($p in $params.GetEnumerator()) {
                $cmd.Parameters.AddWithValue($p.Name, $p.Value)
            }
        }

        [int]$numrows = $cmd.ExecuteNonQuery()
        [HashTable]$info = @{
            NumRowsAffected = $numrows
            LastInsertRowId = $cmd.Connection.LastInsertRowId
        }
        return $info
    }

    [HashTable]Execute([string]$sql_statement) {
        return $this.Execute($sql_statement, $null)
    }

    [void]Close() {
        $this.con.Close()
    }
}