$ErrorActionPreference = "Stop"

$mobileRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Resolve-Path (Join-Path $mobileRoot "..\PRM393_Cleaning\CleaningServiceApp")
$composeFile = Join-Path $backendRoot "docker-compose.e2e.yml"
$apiProcess = $null
$ready = $false
$androidDevice = flutter devices --machine | ConvertFrom-Json | Where-Object { $_.targetPlatform -like "android*" } | Select-Object -First 1

if (-not $androidDevice) {
    throw "Start an Android emulator or connect an Android device before running E2E tests."
}

try {
    docker compose -f $composeFile up -d --wait

    $env:ASPNETCORE_ENVIRONMENT = "Development"
    $env:ASPNETCORE_URLS = "http://127.0.0.1:5001"
    $env:ConnectionStrings__DefaultConnection = "Host=127.0.0.1;Port=55434;Database=cleaning_e2e;Username=postgres;Password=postgres"

    try {
        Push-Location $backendRoot
        dotnet ef database update --project DAL --startup-project CleaningService.API -- --environment Development
        $apiProcess = Start-Process dotnet -ArgumentList "run --project CleaningService.API --no-launch-profile" -PassThru -WindowStyle Hidden
    }
    finally {
        Pop-Location
    }

    $deadline = (Get-Date).AddSeconds(60)
    do {
        try {
            Invoke-WebRequest "http://127.0.0.1:5001/api/ServiceCatalog/categories" -UseBasicParsing | Out-Null
            $ready = $true
        }
        catch {
            Start-Sleep -Seconds 1
        }
    } while (-not $ready -and (Get-Date) -lt $deadline)

    if (-not $ready) {
        throw "The test API did not become ready within 60 seconds."
    }

    try {
        Push-Location $mobileRoot
        flutter drive -d $androidDevice.id --driver=test_driver/integration_test.dart --target=integration_test/app_smoke_test.dart --dart-define=API_BASE_URL=http://10.0.2.2:5001/api
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($apiProcess -and -not $apiProcess.HasExited) {
        Stop-Process -Id $apiProcess.Id -Force
    }
    docker compose -f $composeFile down --volumes --remove-orphans
}
