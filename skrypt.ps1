# Script: DataProcessing.ps1
# Description: Automates data validation and loading into a database
# Created on: 01/16/2025
# Changelog:
# - Initial creation with basic data processing steps
# - Updated to handle password-protected text file
# - Removed SQL username and password for Windows Authentication

param (
    [string]$IndexNumber = "407757",
    [string]$DownloadUrl = "http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip",
    [string]$TxtFilePassword = "bdp2agh",
    [string]$SQLHost = "DESKTOP-0OVLTIN\MSSQLSERVER01",
    [string]$DatabaseName = "AdventureWorksDW2019"
)

# Generate timestamp
$Timestamp = Get-Date -Format "MMddyyyyHHmmss"

# Paths
$LogFilePath = "./PROCESSED/DataProcessing_${Timestamp}.log"
$ProcessedDir = "./PROCESSED"
$DownloadedZip = "./InternetSales_new.zip"
$UnzipDir = "./InternetSales_new"

# Create Processed directory if not exists
if (!(Test-Path $ProcessedDir)) {
    New-Item -ItemType Directory -Path $ProcessedDir
}

# Log function
function Log {
    param (
        [string]$Message
    )
    $TimeStampedMessage = "$((Get-Date).ToString('yyyyMMddHHmmss')) - $Message"
    Add-Content -Path $LogFilePath -Value $TimeStampedMessage
    Write-Output $TimeStampedMessage
}

# Step a: Download file
Log "Step a: Downloading file..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadedZip
if ($?) { Log "Download successful." } else { Log "Download failed."; exit 1 }

# Step b: Unzip the file using 7-Zip

$EncryptedFilePath = Join-Path $UnzipDir "InternetSales_new.txt"
$DecryptedFilePath = Join-Path $UnzipDir "Decrypted_InternetSales_new.txt"

Log "Unzipping file using 7-Zip"
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
$zipFilePath = "InternetSales_new.zip"
$destinationPath = "C:\Users\Igor\Desktop\BDP_2_not\zad10v2\InternetSales_new"

# Sprawdź, czy folder docelowy istnieje
if (!(Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

# Rozpakowywanie pliku ZIP bez hasła
& $sevenZipPath x $zipFilePath -o"$destinationPath" -y 
if ($?) {
    Log "Unzip successful"
} else {
    Log "Unzip failed"
    exit 1
}


# Step c: Validate file
Log "Step c: Validating file..."
$InputFile = "C:\Users\Igor\Desktop\BDP_2_not\zad10v2\InternetSales_new\InternetSales_new.txt"
$ValidFile = "C:\Users\Igor\Desktop\BDP_2_not\zad10v2\InternetSales_new\InternetSales_new_valid_$Timestamp.txt"
$BadFile = "C:\Users\Igor\Desktop\BDP_2_not\zad10v2\InternetSales_new\InternetSales_new.bad_$Timestamp.txt"

Log "Validating and processing file $InputFile" -Status "Started"
try {
    $Header = Get-Content $InputFile -TotalCount 1
    $ExpectedColumns = $Header -split '\|'
    
    # Kolekcja do przechowywania unikalnych wierszy
    $SeenLines = @()
    # Funkcja do sprawdzania wartości liczbowych
function Is-Numeric {
    param ([string]$Value)
    return $Value -match "^\d+(\.\d+)?$"
}

    Get-Content $InputFile |
        Where-Object { $_ -and $_ -ne $Header } |
        ForEach-Object {
            $Columns = $_ -split '\|'
            
            # Sprawdzamy, czy $Columns[6] nie jest pusty
            if (-not [string]::IsNullOrEmpty($Columns[6])) {
                # Jeśli już widzieliśmy ten wiersz, pomijamy go
                if ($SeenLines -contains $_) {
                    return  # Kontynuuje następną iterację pętli
                }

                # Zapisujemy do $BadFile, jeśli wiersz nie jest pusty
                $_ | Out-File -Append -FilePath $BadFile
                $SeenLines += $_  # Dodajemy wiersz do kolekcji unikalnych wierszy
                return
            }

            # Jeśli wiersz spełnia inne warunki i jest unikalny
            if ($Columns.Count -eq $ExpectedColumns.Count -and
                [int]$Columns[4] -le 100 -and
                (Is-Numeric $Columns[0]) -and
                (Is-Numeric $Columns[3]) -and
                (Is-Numeric $Columns[4]) -and
                (Is-Numeric $Columns[5].Replace(",", "."))) {

                $CustomerName = $Columns[2] -replace '"', ''
                if ($CustomerName -match '^(?<LastName>[^,]+),(?<FirstName>.+)$') {
                    $Columns[2] = $Matches['FirstName'] + '|' + $Matches['LastName']
                    $Columns[5] = $Columns[5] -replace ',', '.'
                    $NewLine = $Columns -join '|'

                    # Jeśli wiersz nie był jeszcze widziany, dodajemy do wyników
                    if ($SeenLines -notcontains $NewLine) {
                        $SeenLines += $NewLine
                        $NewLine
                    }
                }
            } else {
                # Zapisujemy do $BadFile w przypadku innych błędów
                $_ | Out-File -Append -FilePath $BadFile
            }
        } | Set-Content -Path $ValidFile

    Log "Validating and processing file $InputFile" -Status "Successful"
} catch {
    Log "Validating and processing file $InputFile" -Status "Failed"
    throw $_
}


Log "Validation complete. Valid lines saved to $ValidatedFilePath"

# Step d: Create MySQL table
Log "Step d: Creating table..."
$CreateTableSQL = @"
CREATE TABLE CUSTOMERS_$IndexNumber (

    ProductKey INT NOT NULL,
    CurrencyAlternateKey VARCHAR(10) NOT NULL,
    FIRST_NAME VARCHAR(100),
    LAST_NAME VARCHAR(100),
    OrderDateKey DATE NOT NULL,
    OrderQuantity INT NOT NULL,
    UnitPrice DECIMAL(18, 2) NOT NULL,
    SecretCode VARCHAR(10) NULL
);
"@
# Using Windows Authentication for SQL Server connection
Invoke-Sqlcmd -ServerInstance $SQLHost -Query $CreateTableSQL -Database $DatabaseName
if ($?) { Log "Table creation successful." } else { Log "Table creation failed."; exit 1 }

# Step e: INSERT
try {
    $query = @"
    BULK INSERT CUSTOMERS_$IndexNumber
    FROM '$ValidFile'
    WITH (
        FIELDTERMINATOR = '|',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    )
"@
    Invoke-Sqlcmd -ServerInstance $SQLHost -Query $query -Database $DatabaseName
    Log "Data loading to table $TableName - Successful"
} catch {
    Log "Data loading to table $TableName - Failed: $_"
    exit 1
}

# Step f: move
try {
    $ProcessedFile = Join-Path $ProcessedDir "${Timestamp}_$(Split-Path $InputFile -Leaf)"
    Move-Item -Path $ValidFile -Destination $ProcessedFile
    Log "File moved to $ProcessedFile - Successful"
} catch {
    Log "File move - Failed: $_"
    exit 1
}

# Step g: Update

try {
    $updateQuery = @"
    UPDATE CUSTOMERS_$IndexNumber
    SET SecretCode = LEFT(NEWID(), 10)
"@
    Invoke-Sqlcmd -Query $updateQuery -ServerInstance $SQLHost -Database $DatabaseName
    Log "SecretCode column updated - Successful"
} catch {
    Log "SecretCode update - Failed: $_"
    exit 1
}

# Step h: export
try {
    $ExportCsv = "./PROCESSED/export_${Timestamp}.csv"
    $exportQuery = "SELECT * FROM CUSTOMERS_$IndexNumber"
    Invoke-Sqlcmd -Query $exportQuery -ServerInstance $SQLHost -Database $DatabaseName| Export-Csv -Path $ExportCsv -NoTypeInformation
    Log "Table $TableName exported to CSV - Successful"
} catch {
    Log "Table export - Failed: $_"
    exit 1
}

try {
    (Get-Content $ExportCsv) | ForEach-Object { $_ -replace '"', '' } | Set-Content $ExportCsv
    Log "Deleting quotations" $true
} catch {
    Log "Deleting quotations" $false
    throw
}

# Step i: compress
try {
    $ZipFile = "$ExportCsv.zip"
    Compress-Archive -Path $ExportCsv -DestinationPath $ZipFile
    Log "CSV file compressed to $ZipFile - Successful"
} catch {
    Log "CSV compression - Failed: $_"
    exit 1
}
