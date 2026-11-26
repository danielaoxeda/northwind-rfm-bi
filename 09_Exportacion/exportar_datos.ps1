# Exporta las cuatro tablas de Northwind_DW a JSON temporal usando ADO.NET.
# Luego invoca generar_xlsx_csv.py para producir CSV UTF-8 y el libro XLSX.
# Uso: powershell -ExecutionPolicy Bypass -File .\09_Exportacion\exportar_datos.ps1
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$tables = @(
    @{ Name = 'Dim_Cliente';    Key = 'ID_Cliente';      Cols = @('ID_Cliente','ID_Cliente_Northwind','Nombre_Empresa','Pais','Ciudad') },
    @{ Name = 'Dim_Producto';   Key = 'ID_Producto';     Cols = @('ID_Producto','ID_Producto_Northwind','Nombre_Producto','Categoria') },
    @{ Name = 'Dim_Tiempo';     Key = 'ID_Tiempo';       Cols = @('ID_Tiempo','Fecha_Completa','Dia','Mes','Nombre_Mes','Trimestre','Anio') },
    @{ Name = 'Hechos_Ventas';  Key = 'ID_Hecho_Venta';  Cols = @('ID_Hecho_Venta','ID_Tiempo','ID_Cliente','ID_Producto','OrderID','ProductID','Cantidad','Precio_Unitario','Descuento','Monto_Total') }
)

$tmp = Join-Path $PSScriptRoot '_tmp'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null

$connStr = 'Server=localhost;Database=Northwind_DW;Integrated Security=True;TrustServerCertificate=True;Encrypt=False'
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()

try {
    foreach ($t in $tables) {
        $cols = ($t.Cols | ForEach-Object { "[$_]" }) -join ','
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT $cols FROM dbo.$($t.Name) ORDER BY $($t.Key);"
        $cmd.CommandTimeout = 120
        $reader = $cmd.ExecuteReader()

        $rows = New-Object System.Collections.ArrayList
        while ($reader.Read()) {
            $h = [ordered]@{}
            for ($i = 0; $i -lt $t.Cols.Count; $i++) {
                $col = $t.Cols[$i]
                $v = $reader.GetValue($i)
                if ($v -is [System.DBNull]) {
                    $h[$col] = $null
                } elseif ($v -is [datetime]) {
                    $h[$col] = $v.ToString('yyyy-MM-dd')
                } elseif ($v -is [string]) {
                    $h[$col] = $v.TrimEnd()
                } elseif ($v -is [decimal]) {
                    $h[$col] = [string]$v
                } else {
                    $h[$col] = $v
                }
            }
            [void]$rows.Add($h)
        }
        $reader.Close()

        $json = ConvertTo-Json -InputObject $rows -Compress -Depth 5
        $path = Join-Path $tmp ($t.Name + '.json')
        [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host ("{0}: {1} filas" -f $t.Name, $rows.Count)
    }
} finally {
    $conn.Close()
}

& python (Join-Path $PSScriptRoot 'generar_xlsx_csv.py') --input $tmp --output $PSScriptRoot
if ($LASTEXITCODE -ne 0) { throw "generar_xlsx_csv.py fallo con codigo $LASTEXITCODE" }
