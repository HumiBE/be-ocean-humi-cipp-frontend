# Script to verify WEBSITE_DEPLOYMENT_ID environment variable

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# Connect to Azure if not already connected
$context = Get-AzContext
if (-not $context) {
    Write-Host "Connecting to Azure..."
    Connect-AzAccount
}

# Set subscription if provided
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
}

# Get the Function App
Write-Host "Fetching Function App: $FunctionAppName from Resource Group: $ResourceGroupName"
$functionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction Stop

Write-Host ""
Write-Host "=== Function App Status ==="
Write-Host "Name: $($functionApp.Name)"
Write-Host "State: $($functionApp.State)"
Write-Host "Runtime Version: $($functionApp.Runtime)"
Write-Host ""

# Get current app settings
Write-Host "=== Environment Variables ===" 
$settings = Get-AzFunctionAppSetting -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction Stop

if ($settings) {
    Write-Host "All settings:"
    $settings | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "=== WEBSITE_DEPLOYMENT_ID Check ==="
    if ($settings.ContainsKey("WEBSITE_DEPLOYMENT_ID")) {
        Write-Host "✓ WEBSITE_DEPLOYMENT_ID is set to: '$($settings['WEBSITE_DEPLOYMENT_ID'])'"
    } else {
        Write-Host "✗ WEBSITE_DEPLOYMENT_ID is NOT set"
    }
} else {
    Write-Host "No settings found"
}

Write-Host ""
Write-Host "=== Recent Errors (if any) ==="
# Get Application Insights logs if available
try {
    $appInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$FunctionAppName*" -or $_.Name -like "*cipp*" }
    
    if ($appInsights) {
        Write-Host "Application Insights found: $($appInsights.Name)"
        Write-Host "Check the Azure Portal for detailed error logs"
    } else {
        Write-Host "No Application Insights found. Check Azure Portal → Function App → Monitor → Logs"
    }
} catch {
    Write-Host "Could not check Application Insights: $_"
}
