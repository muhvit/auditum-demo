param(
  [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"
$base = $BaseUrl.TrimEnd("/")

# Smoke test scope:
# 1. Confirm the HTTP listener responds on /metrics.
# 2. Confirm the Auditum API responds to a simple project listing request.

function Invoke-SmokeRequest {
  param(
    [string]$Url
  )

  $response = Invoke-WebRequest -Method Get -Uri $Url -Headers @{ Accept = "application/json+pretty" } -UseBasicParsing
  Write-Host "GET $Url"
  Write-Host "Status: $($response.StatusCode)"
  if ($response.Content) {
    Write-Host $response.Content
  }
  Write-Host ""
}

Invoke-SmokeRequest -Url "$base/metrics"
Invoke-SmokeRequest -Url "$base/api/v1alpha1/projects?page_size=1"
