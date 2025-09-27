Param(
  [string]$HostName,
  [int]$Port = 443
)

# Resolve script folder
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# If no host passed, discover it dynamically
if (-not $HostName) {
  $HostName = & (Join-Path $ScriptDir 'Get-ScPatchHost.ps1') -MinBuild 420 -MaxBuild 500
}

$ErrorActionPreference = 'Stop'

# Resolve the folder this script is in (portable outputs)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PemOut    = Join-Path $ScriptDir 'cacert.crt'
$Log       = Join-Path $ScriptDir 'StarCitizenCertFix.log'

"[{0}] Start for {1}:{2}" -f (Get-Date -f 'yyyy-MM-dd HH:mm:ss'), $HostName, $Port | Out-File -Encoding utf8 $Log
function Log($m){ "[{0}] {1}" -f (Get-Date -f 'yyyy-MM-dd HH:mm:ss'), $m | Out-File -Append -Encoding utf8 $Log }

# --- Connect & get leaf ---
$tcp = [Net.Sockets.TcpClient]::new($HostName,$Port)
$script:CapturedElems = $null
$cb = [Net.Security.RemoteCertificateValidationCallback]{ param($s,$c,$chain,$e) $script:CapturedElems = $chain?.ChainElements; $true }
$ssl = [Net.Security.SslStream]::new($tcp.GetStream(),$false,$cb)
$ssl.AuthenticateAsClient($HostName)

$leaf = [Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)
Log "Leaf: $($leaf.Subject) | Issuer: $($leaf.Issuer)"

# --- Build bundle: leaf + handshake intermediates + Windows-built chain (ensures root) ---
$bundle = [System.Collections.Generic.List[Security.Cryptography.X509Certificates.X509Certificate2]]::new()
[void]$bundle.Add($leaf)

if ($script:CapturedElems) {
  for($i=1; $i -lt $script:CapturedElems.Count; $i++){
    $c = $script:CapturedElems[$i].Certificate
    if (-not $bundle.Exists({ param($e) $e.Thumbprint -eq $c.Thumbprint })) {
      [void]$bundle.Add($c)
      Log "Added from handshake: $($c.Subject) | Issuer: $($c.Issuer)"
    }
  }
}

$ch = New-Object Security.Cryptography.X509Certificates.X509Chain
$ch.ChainPolicy.RevocationMode = 'NoCheck'
[void]$ch.Build($leaf)
for($i=1; $i -lt $ch.ChainElements.Count; $i++){
  $c = $ch.ChainElements[$i].Certificate
  if (-not $bundle.Exists({ param($e) $e.Thumbprint -eq $c.Thumbprint })) {
    [void]$bundle.Add($c)
    Log "Added from build: $($c.Subject) | Issuer: $($c.Issuer)"
  }
}

# --- Write PEM like openssl s_client -showcerts ---
function To-Pem([Security.Cryptography.X509Certificates.X509Certificate2]$cert){
  $der = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
  $b64 = [Convert]::ToBase64String($der)
  $sb = [Text.StringBuilder]::new()
  for($i=0; $i -lt $b64.Length; $i+=64){
    [void]$sb.AppendLine($b64.Substring($i,[Math]::Min(64,$b64.Length-$i)))
  }
  "-----BEGIN CERTIFICATE-----`r`n$($sb.ToString())-----END CERTIFICATE-----`r`n"
}
($bundle | ForEach-Object { To-Pem $_ }) -join "`r`n" | Set-Content -Encoding ascii $PemOut
Log "Wrote PEM to $PemOut"

# --- Import: self-signed -> LocalMachine\Root, others -> LocalMachine\CA ---
$root = New-Object Security.Cryptography.X509Certificates.X509Store('Root','LocalMachine')
$ca   = New-Object Security.Cryptography.X509Certificates.X509Store('CA','LocalMachine')
$root.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$ca.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

$addedRoot = 0; $addedCA = 0
foreach($c in $bundle){
  $isSelf = ($c.Subject -eq $c.Issuer)
  if ($isSelf) {
    $exists = $root.Certificates.Find([Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,$c.Thumbprint,$false)
    if ($exists.Count -eq 0){
      $root.Add($c); $addedRoot++; Log "Imported ROOT: $($c.Subject) | Thumbprint: $($c.Thumbprint)"
    } else {
      Log "AlreadyPresent ROOT: $($c.Subject)"
    }
  } else {
    $exists = $ca.Certificates.Find([Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,$c.Thumbprint,$false)
    if ($exists.Count -eq 0){
      $ca.Add($c); $addedCA++; Log "Imported CA:   $($c.Subject) | Thumbprint: $($c.Thumbprint)"
    } else {
      Log "AlreadyPresent CA:   $($c.Subject)"
    }
  }
}

$root.Close(); $ca.Close(); $ssl.Dispose(); $tcp.Close()

Write-Host "✅ Imported: $addedCA intermediate(s) to LocalMachine\CA; $addedRoot root(s) to LocalMachine\Root"
Write-Host "📜 Log saved to: $Log"
exit 0