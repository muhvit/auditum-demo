param(
  [Parameter(Mandatory = $true)]
  [string]$BaseUrl,

  [Parameter(Mandatory = $true)]
  [string]$TenantId,

  [Parameter(Mandatory = $true)]
  [string]$ActorUserId,

  [Parameter(Mandatory = $true)]
  [string]$IncidentCaseIndex
)

$ErrorActionPreference = "Stop"
$base = $BaseUrl.TrimEnd("/")

# Functional ingestion test scope:
# 1. Look up or create an Auditum project for the supplied tenant.
# 2. Submit five demo audit records through the HTTP API.
# 3. Print statuses and bodies so the caller can verify the write path.

function New-HexString {
  param(
    [int]$Bytes
  )

  $buffer = New-Object byte[] $Bytes
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
  return ([System.BitConverter]::ToString($buffer)).Replace("-", "").ToLowerInvariant()
}

function Invoke-CurlJson {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("GET", "POST")]
    [string]$Method,

    [Parameter(Mandatory = $true)]
    [string]$Url,

    [object]$Body
  )

  $responseFile = New-TemporaryFile
  $bodyFile = $null

  try {
    $arguments = @(
      "--silent",
      "--show-error",
      "--location",
      "--request", $Method,
      "--header", "Accept: application/json+pretty",
      "--output", $responseFile.FullName,
      "--write-out", "%{http_code}"
    )

    if ($Body -ne $null) {
      $bodyFile = New-TemporaryFile
      $Body | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $bodyFile.FullName -Encoding utf8
      $arguments += @("--header", "Content-Type: application/json", "--data", "@$($bodyFile.FullName)")
    }

    $arguments += $Url
    $statusCode = & curl.exe @arguments
    $responseBody = Get-Content -LiteralPath $responseFile.FullName -Raw

    Write-Host "$Method $Url"
    Write-Host "Status: $statusCode"
    if ($responseBody) {
      Write-Host $responseBody
    }
    Write-Host ""

    $json = $null
    if ($responseBody) {
      try {
        $json = $responseBody | ConvertFrom-Json
      } catch {
        $json = $null
      }
    }

    return [pscustomobject]@{
      StatusCode = [int]$statusCode
      Body       = $responseBody
      Json       = $json
    }
  } finally {
    Remove-Item -LiteralPath $responseFile.FullName -ErrorAction SilentlyContinue
    if ($bodyFile) {
      Remove-Item -LiteralPath $bodyFile.FullName -ErrorAction SilentlyContinue
    }
  }
}

$projectLookupUrl = "{0}/api/v1alpha1/projects?filter.external_ids={1}&page_size=1" -f $base, [uri]::EscapeDataString($TenantId)
$projectLookup = Invoke-CurlJson -Method GET -Url $projectLookupUrl

$projectId = $null
if ($projectLookup.Json -and $projectLookup.Json.projects -and $projectLookup.Json.projects.Count -gt 0) {
  $projectId = $projectLookup.Json.projects[0].id
}

if (-not $projectId) {
  $projectCreateBody = @{
    project = @{
      display_name = "Auditum Demo $TenantId"
      external_id  = $TenantId
    }
  }

  $projectCreate = Invoke-CurlJson -Method POST -Url "$base/api/v1alpha1/projects" -Body $projectCreateBody
  if (-not $projectCreate.Json -or -not $projectCreate.Json.project.id) {
    throw "Failed to create or parse Auditum project."
  }

  $projectId = $projectCreate.Json.project.id
}

Write-Host "Using Project ID: $projectId"
Write-Host ""

$traceId = New-HexString -Bytes 16
$spanId = New-HexString -Bytes 8
$traceparent = "00-$traceId-$spanId-01"
$now = [DateTime]::UtcNow

$records = @(
  @{
    labels = @{
      tenant_id           = $TenantId
      incident_case_index = $IncidentCaseIndex
    }
    resource = @{
      type = "INCIDENT"
      id   = $IncidentCaseIndex
      metadata = @{
        action         = "incident.viewed"
        source_service = "demo-curl"
      }
    }
    operation = @{
      type  = "READ"
      id    = "demo.auditum/incident.viewed"
      time  = $now.ToString("o")
      status = "SUCCEEDED"
      trace_context = @{
        traceparent = $traceparent
        tracestate  = "demo=tenant-$TenantId"
      }
      metadata = @{
        correlation_id = $traceId
      }
    }
    actor = @{
      type = "USER"
      id   = $ActorUserId
    }
  },
  @{
    labels = @{
      tenant_id           = $TenantId
      incident_case_index = $IncidentCaseIndex
    }
    resource = @{
      type = "OWNER_DATA"
      id   = "$IncidentCaseIndex-owner-data"
      metadata = @{
        action       = "owner-data.viewed"
        data_classes = "VehicleOwnerName,VehicleOwnerAddress"
      }
    }
    operation = @{
      type  = "READ"
      id    = "demo.auditum/owner-data.viewed"
      time  = $now.AddSeconds(1).ToString("o")
      status = "SUCCEEDED"
      trace_context = @{
        traceparent = $traceparent
        tracestate  = "demo=tenant-$TenantId"
      }
      metadata = @{
        correlation_id = $traceId
      }
    }
    actor = @{
      type = "USER"
      id   = $ActorUserId
    }
  },
  @{
    labels = @{
      tenant_id           = $TenantId
      incident_case_index = $IncidentCaseIndex
    }
    resource = @{
      type = "EVIDENCE"
      id   = "$IncidentCaseIndex-evidence-001"
      metadata = @{
        action   = "evidence.downloaded"
        filename = "bodycam-footage.mp4"
      }
    }
    operation = @{
      type  = "DOWNLOAD"
      id    = "demo.auditum/evidence.downloaded"
      time  = $now.AddSeconds(2).ToString("o")
      status = "SUCCEEDED"
      trace_context = @{
        traceparent = $traceparent
        tracestate  = "demo=tenant-$TenantId"
      }
      metadata = @{
        correlation_id = $traceId
      }
    }
    actor = @{
      type = "USER"
      id   = $ActorUserId
    }
  },
  @{
    labels = @{
      tenant_id           = $TenantId
      incident_case_index = $IncidentCaseIndex
    }
    resource = @{
      type = "WORKFLOW"
      id   = "$IncidentCaseIndex-authorization"
      metadata = @{
        action = "workflow.authorization-approved"
        step   = "supervisor-approval"
      }
    }
    operation = @{
      type  = "APPROVE"
      id    = "demo.auditum/workflow.authorization-approved"
      time  = $now.AddSeconds(3).ToString("o")
      status = "SUCCEEDED"
      trace_context = @{
        traceparent = $traceparent
        tracestate  = "demo=tenant-$TenantId"
      }
      metadata = @{
        correlation_id = $traceId
      }
    }
    actor = @{
      type = "USER"
      id   = $ActorUserId
    }
  },
  @{
    labels = @{
      tenant_id           = $TenantId
      incident_case_index = $IncidentCaseIndex
    }
    resource = @{
      type = "INCIDENT"
      id   = $IncidentCaseIndex
      metadata = @{
        action = "access.denied"
        reason = "missing-permission"
      }
    }
    operation = @{
      type  = "READ"
      id    = "demo.auditum/access.denied"
      time  = $now.AddSeconds(4).ToString("o")
      status = "FAILED"
      trace_context = @{
        traceparent = $traceparent
        tracestate  = "demo=tenant-$TenantId"
      }
      metadata = @{
        correlation_id = $traceId
      }
    }
    actor = @{
      type = "USER"
      id   = $ActorUserId
    }
  }
)

$recordCreateBody = @{
  records = $records
}

$recordUrl = "$base/api/v1alpha1/projects/$projectId/records:batchCreate"
[void](Invoke-CurlJson -Method POST -Url $recordUrl -Body $recordCreateBody)
