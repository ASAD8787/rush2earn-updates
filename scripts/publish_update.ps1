param(
  [Parameter(Mandatory = $true)]
  [string]$GitHubUser,

  [Parameter(Mandatory = $true)]
  [string]$RepoName,

  [Parameter(Mandatory = $false)]
  [string]$GitHubToken = $env:GITHUB_TOKEN,

  [Parameter(Mandatory = $false)]
  [string]$Version = "",

  [Parameter(Mandatory = $false)]
  [string]$Notes = "Bug fixes and improvements",

  [Parameter(Mandatory = $false)]
  [string]$Branch = "main",

  [Parameter(Mandatory = $false)]
  [string]$ApkPath = "build/app/outputs/flutter-apk/app-release.apk",

  [switch]$CreateRepo
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PubspecVersion {
  $pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
  $versionLine = Get-Content -Path $pubspecPath | Select-String -Pattern "^version:\s*"
  if (-not $versionLine) {
    throw "Could not find version in pubspec.yaml"
  }
  $raw = ($versionLine.Line -replace "^version:\s*", "").Trim()
  return ($raw -split "\+")[0]
}

function Get-AuthHeader {
  if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    throw "GitHub token is required. Pass -GitHubToken or set GITHUB_TOKEN."
  }
  return @{
    "Authorization" = "Bearer $GitHubToken"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
  }
}

function Invoke-GitHubJson {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $false)]$Body = $null
  )
  $headers = Get-AuthHeader
  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
  }
  return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body ($Body | ConvertTo-Json -Depth 8)
}

function Get-ContentShaOrNull {
  param(
    [Parameter(Mandatory = $true)][string]$Owner,
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Ref
  )
  $headers = Get-AuthHeader
  $uri = "https://api.github.com/repos/$Owner/$Repo/contents/${Path}?ref=$Ref"
  try {
    $res = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    return $res.sha
  } catch {
    return $null
  }
}

function Upsert-RepoFile {
  param(
    [Parameter(Mandatory = $true)][string]$Owner,
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [Parameter(Mandatory = $true)][string]$Message,
    [Parameter(Mandatory = $true)][string]$Ref
  )

  $sha = Get-ContentShaOrNull -Owner $Owner -Repo $Repo -Path $Path -Ref $Ref
  $body = @{
    message = $Message
    content = [Convert]::ToBase64String($Bytes)
    branch  = $Ref
  }
  if ($null -ne $sha) {
    $body.sha = $sha
  }
  $uri = "https://api.github.com/repos/$Owner/$Repo/contents/$Path"
  Invoke-GitHubJson -Method Put -Uri $uri -Body $body | Out-Null
}

function Get-OrCreateRelease {
  param(
    [Parameter(Mandatory = $true)][string]$Owner,
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)][string]$Tag
  )

  $headers = Get-AuthHeader
  $getUri = "https://api.github.com/repos/$Owner/$Repo/releases/tags/$Tag"
  try {
    return Invoke-RestMethod -Method Get -Uri $getUri -Headers $headers
  } catch {
    $createUri = "https://api.github.com/repos/$Owner/$Repo/releases"
    $body = @{
      tag_name = $Tag
      name = $Tag
      draft = $false
      prerelease = $false
      generate_release_notes = $false
    }
    return Invoke-GitHubJson -Method Post -Uri $createUri -Body $body
  }
}

function Upload-ReleaseAsset {
  param(
    [Parameter(Mandatory = $true)][string]$Owner,
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)]$Release,
    [Parameter(Mandatory = $true)][string]$AssetName,
    [Parameter(Mandatory = $true)][string]$AssetPath
  )

  $headers = Get-AuthHeader

  foreach ($asset in $Release.assets) {
    if ($asset.name -eq $AssetName) {
      $deleteUri = "https://api.github.com/repos/$Owner/$Repo/releases/assets/$($asset.id)"
      Invoke-RestMethod -Method Delete -Uri $deleteUri -Headers $headers | Out-Null
      break
    }
  }

  $uploadBase = $Release.upload_url -replace "\{\?name,label\}", ""
  $uploadUri = "${uploadBase}?name=$AssetName"
  $uploadHeaders = @{
    "Authorization" = "Bearer $GitHubToken"
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
  }
  $uploaded = Invoke-RestMethod `
    -Method Post `
    -Uri $uploadUri `
    -Headers $uploadHeaders `
    -InFile $AssetPath `
    -ContentType "application/vnd.android.package-archive"

  return $uploaded.browser_download_url
}

if ([string]::IsNullOrWhiteSpace($Version)) {
  $Version = Get-PubspecVersion
}

$resolvedApk = Resolve-Path -Path $ApkPath -ErrorAction Stop
$apkName = "rush2earn-$Version.apk"

if ($CreateRepo.IsPresent) {
  $createBody = @{
    name = $RepoName
    private = $false
    auto_init = $true
    description = "Rush2Earn app update artifacts"
  }
  Invoke-GitHubJson -Method Post -Uri "https://api.github.com/user/repos" -Body $createBody | Out-Null
  Start-Sleep -Seconds 2
}

$tag = "v$Version"
$release = Get-OrCreateRelease -Owner $GitHubUser -Repo $RepoName -Tag $tag
$apkUrl = Upload-ReleaseAsset -Owner $GitHubUser -Repo $RepoName -Release $release -AssetName $apkName -AssetPath $resolvedApk.Path

$rawBase = "https://raw.githubusercontent.com/$GitHubUser/$RepoName/$Branch"
$versionObject = @{
  version = $Version
  apkUrl = $apkUrl
  notes = $Notes
}
$versionJson = ($versionObject | ConvertTo-Json -Depth 5)
$versionBytes = [System.Text.Encoding]::UTF8.GetBytes($versionJson)
Upsert-RepoFile -Owner $GitHubUser -Repo $RepoName -Path "version.json" -Bytes $versionBytes -Message "Update version manifest to $Version" -Ref $Branch

$manifestUrl = "$rawBase/version.json"
Write-Host ""
Write-Host "Published update files successfully."
Write-Host "Manifest URL: $manifestUrl"
Write-Host "APK URL: $apkUrl"
Write-Host ""
Write-Host "Set this in lib/config/web3_config.dart:"
Write-Host "static const String appUpdateManifestUrl = '$manifestUrl';"
