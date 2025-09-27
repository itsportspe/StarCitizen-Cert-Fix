<# Returns the current Star Citizen backend hostname like:
   pub-sc-alpha-431-10275505.test1.cloudimperiumgames.com
#>
[CmdletBinding()]
param(
  [int]$MinBuild = 400,
  [int]$MaxBuild = 500,
  [string[]]$Domains = @('test1.cloudimperiumgames.com'),
  [string]$BuildSuffix = '10275505'
)

$ErrorActionPreference = 'SilentlyContinue'
$regexHost = '(?<=\b)(pub-sc-[a-z0-9\-]+(?:\.[a-z0-9\-]+)*\.(?:cloudimperiumgames|robertsspaceindustries)\.com)(?=\b)'

# 1) Try to discover from local launcher files (fast path)
$paths = @(
  "$env:APPDATA\CloudImperiumGames\Launcher\settings.json",
  "$env:LOCALAPPDATA\CloudImperiumGames\Launcher\settings.json",
  "$env:APPDATA\rsilauncher\logs\*.log",
  "$env:LOCALAPPDATA\rsilauncher\logs\*.log",
  "$env:PROGRAMDATA\CloudImperiumGames\**\*.json"
) | Where-Object {$_}

foreach ($glob in $paths) {
  Get-ChildItem -Path $glob -File -ErrorAction Ignore | Sort-Object LastWriteTime -Descending | ForEach-Object {
    $txt = Get-Content $_.FullName -Raw -ErrorAction Ignore
    if ($txt) {
      $m = [regex]::Match($txt, $regexHost, 'IgnoreCase')
      if ($m.Success) { $m.Value.ToLowerInvariant(); return }
    }
  }
}

# 2) Fallback: probe DNS for highest live pub-sc-alpha-<build>-<suffix>.<domain>
for ($b = $MaxBuild; $b -ge $MinBuild; $b--) {
  foreach ($d in $Domains) {
    $CandidateHost = "pub-sc-alpha-$b-$BuildSuffix.$d".ToLower()
    try {
      $ips = [System.Net.Dns]::GetHostAddresses($CandidateHost)
      if ($ips -and $ips.Count -gt 0) { $CandidateHost; return }
    } catch {}
  }
}

throw "Could not determine Star Citizen backend host (try widening -MinBuild/-MaxBuild or adjust -Domains/-BuildSuffix)."