# Script to remove or modify WEBSITE_DEPLOYMENT_ID environment variable

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "remove", # remove or set
    
    [Parameter(Mandatory=$false)]
    [string]$NewValue, # Required if Action is "set"
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

if ($Action -eq "set" -and -not $NewValue) {
    Write-Error "NewValue parameter is required when Action is 'set'"
    exit 1
}

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

# Get current app settings
$appSettings = Get-AzFunctionAppSetting -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction Stop

if ($Action -eq "remove") {
    Write-Host "Removing WEBSITE_DEPLOYMENT_ID environment variable..."
    if ($appSettings.ContainsKey("WEBSITE_DEPLOYMENT_ID")) {
        $appSettings.Remove("WEBSITE_DEPLOYMENT_ID")
        Write-Host "✓ Removed WEBSITE_DEPLOYMENT_ID"
    } else {
        Write-Host "⚠ WEBSITE_DEPLOYMENT_ID not found in settings"
    }
} elseif ($Action -eq "set") {
    Write-Host "Setting WEBSITE_DEPLOYMENT_ID to: $NewValue"
    $appSettings["WEBSITE_DEPLOYMENT_ID"] = $NewValue
    Write-Host "✓ Updated WEBSITE_DEPLOYMENT_ID"
}

# Apply the settings
Write-Host "Applying settings to Function App..."
Update-AzFunctionAppSetting -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -AppSetting $appSettings

Write-Host "✓ Successfully updated Function App!"
Write-Host ""
Write-Host "The Function App will restart with the new settings."
Write-Host "Check the Azure Portal for startup status."
