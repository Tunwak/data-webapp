# PowerShell script to import SQL database to Railway
# This script will import the Northwind database to your Railway MySQL instance

Write-Host "=== Railway MySQL Northwind Database Importer ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will help you import the translated Northwind database to Railway." -ForegroundColor Green
Write-Host ""

Write-Host "Choose connection method:" -ForegroundColor Yellow
Write-Host "[1] Use MYSQL_URL (recommended)"
Write-Host "[2] Use individual connection details"
Write-Host ""

$method = Read-Host "Select (1 or 2)"

if ($method -eq "1") {
  Write-Host ""
  Write-Host "Please paste the MYSQL_URL from Railway:" -ForegroundColor Yellow
  Write-Host "(You can find this in Railway Console > MySQL > Variables > MYSQL_URL or DATABASE_URL)" -ForegroundColor Gray
  Write-Host ""
  
  $MYSQL_URL = Read-Host "MYSQL_URL"
  
  if ([string]::IsNullOrWhiteSpace($MYSQL_URL)) {
    Write-Host "Error: MYSQL_URL cannot be empty" -ForegroundColor Red
    exit 1
  }
  
  Write-Host ""
  Write-Host "Connection URL: $MYSQL_URL" -ForegroundColor Yellow
  Write-Host ""
  
  $proceed = Read-Host "Ready to import? (y/n)"
  if ($proceed -ne 'y' -and $proceed -ne 'Y') {
    Write-Host "Import cancelled." -ForegroundColor Red
    exit 1
  }
  
  # Set environment variable
  $env:MYSQL_URL = $MYSQL_URL

} else {
  # Get Railway MySQL credentials from user
  Write-Host "Please enter your Railway MySQL connection details:" -ForegroundColor Yellow
  Write-Host "(You can find these in Railway Console > MySQL > Variables)" -ForegroundColor Gray
  Write-Host ""

  $MYSQL_HOST = Read-Host "MYSQL_HOST (e.g., container-xxx.up.railway.app)"
  $MYSQL_PORT = Read-Host "MYSQL_PORT (default: 3306)" 
  if ([string]::IsNullOrWhiteSpace($MYSQL_PORT)) { $MYSQL_PORT = "3306" }

  $MYSQL_USER = Read-Host "MYSQL_USER (e.g., root)"

  $MYSQL_PASSWORD_SECURE = Read-Host "MYSQL_PASSWORD" -AsSecureString
  $MYSQL_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($MYSQL_PASSWORD_SECURE))

  $MYSQL_DB = Read-Host "MYSQL_DATABASE (e.g., railway)"

  Write-Host ""
  Write-Host "Connection Details:" -ForegroundColor Yellow
  Write-Host "  Host: $MYSQL_HOST"
  Write-Host "  Port: $MYSQL_PORT"
  Write-Host "  User: $MYSQL_USER"
  Write-Host "  Database: $MYSQL_DB"
  Write-Host ""

  $proceed = Read-Host "Ready to import? (y/n)"
  if ($proceed -ne 'y' -and $proceed -ne 'Y') {
    Write-Host "Import cancelled." -ForegroundColor Red
    exit 1
  }

  # Set environment variables
  $env:MYSQL_HOST = $MYSQL_HOST
  $env:MYSQL_PORT = $MYSQL_PORT
  $env:MYSQL_USER = $MYSQL_USER
  $env:MYSQL_PASSWORD = $MYSQL_PASSWORD
  $env:MYSQL_DB = $MYSQL_DB
}

Write-Host ""
Write-Host "Installing mysql2 package..." -ForegroundColor Cyan

# Install mysql2
npm install mysql2 --legacy-peer-deps

if ($LASTEXITCODE -ne 0) {
  Write-Host "Failed to install mysql2" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Starting database import..." -ForegroundColor Cyan
Write-Host ""

# Run import script
node import-db.js

if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "✅ Database import completed successfully!" -ForegroundColor Green
  Write-Host "You can now access your Northwind database on Railway." -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "❌ Database import failed. Please check the errors above." -ForegroundColor Red
  exit 1
}
