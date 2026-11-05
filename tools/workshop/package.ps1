[CmdletBinding()]
param(
    [string]$RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')),
    [ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedCommit = 'd1565801dcf20b4ccee8719cae74c00d81d1f42a',
    [string]$OutputRoot,
    [string]$Gmad = 'C:/Program Files (x86)/Steam/steamapps/common/GarrysMod/bin/win64/gmad.exe',
    [string]$GamemodeTitle = 'Zombie Survival Redemption (Gamemode)',
    [string]$ContentTitle = 'Zombie Survival Redemption CONTENT ONLY',
    [ValidatePattern('^$|^[1-9][0-9]{0,19}$')][string]$GamemodeWorkshopId = '',
    [ValidatePattern('^$|^[1-9][0-9]{0,19}$')][string]$ContentWorkshopId = '',
    [switch]$DataStaticNavigation,
    [switch]$StageOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSVersion -lt [version]'7.2') { throw 'Use PowerShell 7.2 or newer.' }
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
if (-not $OutputRoot) { $OutputRoot = Join-Path $RepositoryRoot ('dist/workshop-' + $ExpectedCommit.Substring(0, 8)) }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/')
$outputPrefix = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'dist')).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
if (-not $OutputRoot.StartsWith($outputPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be a new directory under this repository dist folder.' }
if (Test-Path -LiteralPath $OutputRoot) { throw 'Output already exists. Choose a fresh output directory; no overwrite or cleanup is performed.' }
if ($GamemodeWorkshopId -and $ContentWorkshopId -and $GamemodeWorkshopId -ceq $ContentWorkshopId) { throw 'Gamemode and content items must have different IDs.' }

function Get-GitOutput([string[]]$Arguments) {
    $result = & git -C $RepositoryRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Git read failed.' }
    return $result
}

if ((Get-GitOutput -Arguments @('rev-parse', 'HEAD')) -cne $ExpectedCommit) { throw 'HEAD does not match the expected source commit.' }
$tree = @(Get-GitOutput -Arguments @('ls-tree', '-r', '--full-tree', $ExpectedCommit, '--', 'gamemode', 'entities', 'content', 'backgrounds', 'icon24.png', 'logo.png', 'zombiesurvival.txt'))
$inputs = [Collections.Generic.List[object]]::new()
$destinations = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$sourceTotal = 0L
$legacyNavigation = 0
foreach ($row in $tree) {
    if ($row -cnotmatch '^100644 blob ([0-9a-f]{40})\t(.+)$') { throw 'Unexpected source-tree entry.' }
    $blob = $Matches[1]
    $relative = $Matches[2]
    if ($relative -match '(^|/)\.\.(/|$)|[\r\n\\:]' -or $relative.StartsWith('/')) { throw 'Unsafe source-tree path.' }
    $package = ''
    $destination = ''
    $reason = ''
    if ($relative.StartsWith('content/', [StringComparison]::Ordinal)) {
        $package = 'content'
        $destination = $relative.Substring(8)
        if ($destination -match '^models/.*\.(sw|360|xbox)\.vtx$') { $reason = 'GMad excludes unused software and console VTX variants.' }
        elseif ($destination -cnotmatch '^(models/.*\.(mdl|phy|ani|vvd|vtx)|materials/.*\.(vmt|vtf|png|jpg|jpeg)|sound/.*\.(wav|mp3|ogg)|resource/fonts/.*\.ttf)$') { throw "Unreviewed content type: $relative" }
    } elseif ($relative -match '^(gamemode|entities)/.*\.lua$') {
        $package = 'gamemode'
        $destination = 'gamemodes/zombiesurvival/' + $relative
    } elseif ($relative -cmatch '^gamemode/misc/navmeshes/(ze_ffvii_mako_reactor_v5_3(?:\.params)?\.txt)$') {
        $legacyNavigation++
        if (-not $DataStaticNavigation) { throw 'Mako navigation TXT files need an approved data_static reader fallback before packaging. They cannot be silently omitted.' }
        $package = 'gamemode'
        $destination = 'data_static/zombiesurvival/navmeshes/' + $Matches[1]
    } elseif ($relative -cmatch '^(backgrounds/.*\.jpg|icon24\.png|logo\.png|zombiesurvival\.txt)$') {
        $package = 'gamemode'
        $destination = 'gamemodes/zombiesurvival/' + $relative
    } else { throw "Unreviewed runtime source file: $relative" }
    $source = Join-Path $RepositoryRoot $relative
    $info = Get-Item -LiteralPath $source -Force
    if ($info.PSIsContainer -or ($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $info.Length -gt 67108864) { throw "Source is not an ordinary bounded file: $relative" }
    $data = [IO.File]::ReadAllBytes($source)
    $header = [Text.Encoding]::ASCII.GetBytes('blob ' + $data.Length + [char]0)
    $gitHash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
    try { $gitHash.AppendData($header); $gitHash.AppendData($data); $actualBlob = [Convert]::ToHexString($gitHash.GetHashAndReset()).ToLowerInvariant() } finally { $gitHash.Dispose() }
    if ($actualBlob -cne $blob) { throw "Working source differs from the pinned commit: $relative" }
    $sha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data)).ToLowerInvariant()
    $sourceTotal += $data.Length
    if (-not $reason -and -not $destinations.Add($package + '/' + $destination)) { throw "Duplicate package path: $destination" }
    $inputs.Add([pscustomobject]@{Source=$relative;Package=$package;Destination=$destination;Bytes=$data.Length;SHA256=$sha;GitBlob=$blob;Excluded=[bool]$reason;Reason=$reason})
}
if ($legacyNavigation -ne 2) { throw 'The pinned Mako navigation pair was not found.' }
if ($DataStaticNavigation) {
    $mapSource = [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'gamemode/misc/maps/ze_ffvii_mako_reactor_v5_3.lua'))
    if (-not $mapSource.Contains('data_static/zombiesurvival/navmeshes/')) { throw 'Data-static navigation staging requires a matching source reader fallback.' }
}
if (@($inputs | Where-Object { $_.Source.StartsWith('content/', [StringComparison]::Ordinal) }).Count -ne 567) { throw 'Content inventory changed from the reviewed 567-file baseline.' }

[IO.Directory]::CreateDirectory($OutputRoot) | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
$records = [Collections.Generic.List[object]]::new()
$variants = [Collections.Generic.List[object]]::new()
foreach ($entry in $inputs) {
    if ($entry.Excluded) { continue }
    $source = Join-Path $RepositoryRoot $entry.Source
    $data = [IO.File]::ReadAllBytes($source)
    if ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data)).ToLowerInvariant() -cne $entry.SHA256) { throw 'Source changed during staging.' }
    $transformed = $false
    if ($entry.Source -ceq 'zombiesurvival.txt' -and $GamemodeWorkshopId) {
        $text = $utf8.GetString($data)
        if ($text -match '"workshopid"') { throw 'Source metadata already has a Workshop ID; review it explicitly.' }
        $position = $text.IndexOf('{') + 1
        if ($position -lt 1) { throw 'Gamemode metadata is malformed.' }
        $text = $text.Insert($position, "`n`t""workshopid""`t""$GamemodeWorkshopId""")
        $data = $utf8.GetBytes($text)
        $transformed = $true
    }
    if ($entry.Source -ceq 'gamemode/server/sv_downloads.lua' -and $ContentWorkshopId) {
        $text = $utf8.GetString($data)
        $declaration = 'CreateConVar("zs_content_workshop", "",'
        $read = 'local content = string.Trim(contentWorkshop:GetString())'
        if ([regex]::Matches($text, [regex]::Escape($declaration)).Count -ne 1 -or [regex]::Matches($text, [regex]::Escape($read)).Count -ne 1) { throw 'Workshop release configuration requires the reviewed blank-default resource source.' }
        $text = $text.Replace($declaration, ('CreateConVar("zs_content_workshop", "' + $ContentWorkshopId + '",'))
        $text = $text.Replace($read, ($read + "`n`tif content == """" then content = ""$ContentWorkshopId"" end"))
        $data = $utf8.GetBytes($text)
        $transformed = $true
    }
    $destination = Join-Path (Join-Path $OutputRoot $entry.Package) $entry.Destination
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    $stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($data, 0, $data.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    $sha = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sha -cne [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data)).ToLowerInvariant()) { throw 'Staged file readback mismatch.' }
    $records.Add([pscustomobject]@{Source=$entry.Source;Package=$entry.Package;Path=$entry.Destination;Bytes=$data.Length;SHA256=$sha;SourceSHA256=$entry.SHA256;ReleaseConfigurationVariant=$transformed})
    if ($transformed) {
        $diff = @(& git -C $RepositoryRoot -c core.autocrlf=false diff --no-index --no-ext-diff --no-textconv -- $source $destination)
        if ($LASTEXITCODE -ne 1) { throw 'Expected release-configuration difference was not captured.' }
        $variants.Add([pscustomobject]@{Source=$entry.Source;SourceSHA256=$entry.SHA256;ReleaseSHA256=$sha;Diff=($diff -join "`n")})
    }
}
foreach ($package in @('gamemode','content')) {
    $tags = @('fun')
    if ($package -ceq 'gamemode') { $tags = @('fun','realism') }
    $metadata = [ordered]@{title=$(if ($package -ceq 'gamemode') {$GamemodeTitle} else {$ContentTitle});type=$(if ($package -ceq 'gamemode') {'gamemode'} else {'servercontent'});tags=$tags;ignore=@()}
    [IO.File]::WriteAllText((Join-Path (Join-Path $OutputRoot $package) 'addon.json'), ($metadata | ConvertTo-Json -Depth 4) + "`n", $utf8)
}
$manifest = [ordered]@{
    Kind='zombiesurvival-workshop-runtime-packages';SourceCommit=$ExpectedCommit;CreatedUTC=[DateTimeOffset]::UtcNow.ToString('o');SourceFiles=$inputs.Count;SourceBytes=$sourceTotal
    GamemodeWorkshopId=$GamemodeWorkshopId;ContentWorkshopId=$ContentWorkshopId;DataStaticNavigation=$DataStaticNavigation.IsPresent
    Included=$records.ToArray();ExcludedContent=@($inputs | Where-Object Excluded);ReleaseConfigurationVariants=$variants.ToArray();DevelopmentFilesIncluded=$false;WorkshopPublished=$false;Archives=@();Complete=$false
}
$manifestPath = Join-Path $OutputRoot 'manifest.json'
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8) + "`n", $utf8)
if ($ContentWorkshopId) { [IO.File]::WriteAllText((Join-Path $OutputRoot 'server-configuration.txt'), "zs_content_workshop $ContentWorkshopId`n" + $(if ($GamemodeWorkshopId) {"zs_gamemode_workshop $GamemodeWorkshopId`n"}), $utf8) }
if ($StageOnly) { [ordered]@{Output=$OutputRoot;StagedFiles=$records.Count;ExcludedContent=$manifest.ExcludedContent.Count;ArchivesBuilt=$false} | ConvertTo-Json -Compress; return }

if (-not ('ZSWorkshopCRC32' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
public static class ZSWorkshopCRC32 {
    private static readonly uint[] Table = BuildTable();
    private static uint[] BuildTable() {
        var table = new uint[256];
        for (uint i = 0; i < 256; i++) {
            uint value = i;
            for (int bit = 0; bit < 8; bit++) value = (value & 1) != 0 ? 0xedb88320U ^ (value >> 1) : value >> 1;
            table[i] = value;
        }
        return table;
    }
    public static uint Update(uint state, byte[] bytes, int count) {
        for (int i = 0; i < count; i++) state = Table[(state ^ bytes[i]) & 255] ^ (state >> 8);
        return state;
    }
    public static uint Finish(uint state) { return ~state; }
}
'@
}

function Read-GmaString([IO.BinaryReader]$Reader, [int]$Limit = 1048576) {
    $bytes = [Collections.Generic.List[byte]]::new()
    while ($bytes.Count -le $Limit) {
        $next = $Reader.ReadByte()
        if ($next -eq 0) { return [Text.UTF8Encoding]::new($false, $true).GetString($bytes.ToArray()) }
        $bytes.Add($next)
    }
    throw 'GMA string exceeded its bound.'
}

function Readback-Gma([string]$Path, [object[]]$ExpectedFiles, [string]$ExpectedTitle, [string]$ExpectedType) {
    $expected = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($entry in $ExpectedFiles) { $expected.Add($entry.Path.ToLowerInvariant(), $entry) }
    $before = Get-Item -LiteralPath $Path -Force
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    $reader = [IO.BinaryReader]::new($stream, [Text.UTF8Encoding]::new($false, $true), $true)
    try {
        if ([Text.Encoding]::ASCII.GetString($reader.ReadBytes(4)) -cne 'GMAD' -or $reader.ReadByte() -ne 3) { throw 'Unexpected GMA header or version.' }
        $reader.ReadUInt64() | Out-Null
        $timestamp = $reader.ReadUInt64()
        if ((Read-GmaString $reader) -cne '') { throw 'Unexpected embedded required-content list.' }
        $title = Read-GmaString $reader
        $metadata = (Read-GmaString $reader) | ConvertFrom-Json
        Read-GmaString $reader | Out-Null
        if ($reader.ReadUInt32() -ne 1 -or $title -cne $ExpectedTitle -or $metadata.type.ToLowerInvariant() -cne $ExpectedType) { throw 'GMA metadata differs from the staging specification.' }
        $files = [Collections.Generic.List[object]]::new()
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        while ($true) {
            $index = $reader.ReadUInt32()
            if ($index -eq 0) { break }
            if ($files.Count -ge 10000 -or $index -ne $files.Count + 1) { throw 'GMA entry numbering or count is invalid.' }
            $name = Read-GmaString $reader 4096
            $size = $reader.ReadInt64()
            $crc = $reader.ReadUInt32()
            if (-not $expected.ContainsKey($name) -or -not $seen.Add($name) -or $size -ne $expected[$name].Bytes) { throw 'GMA contains an unexpected path, duplicate or file size.' }
            if ($size -le 0 -or $size -gt 67108864) { throw 'GMA entry exceeds its file bound.' }
            $files.Add([pscustomobject]@{Path=$name;Bytes=$size;CRC32=$crc;SHA256=$null})
        }
        if ($files.Count -ne $expected.Count) { throw 'GMA is missing staged files.' }
        $buffer = [byte[]]::new(1048576)
        foreach ($entry in $files) {
            $hash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
            $crc = [uint32]::MaxValue
            $remaining = $entry.Bytes
            try {
                while ($remaining -gt 0) {
                    $count = $stream.Read($buffer, 0, [int][Math]::Min($buffer.Length, $remaining))
                    if ($count -le 0) { throw 'GMA payload ended early.' }
                    $hash.AppendData($buffer, 0, $count)
                    $crc = [ZSWorkshopCRC32]::Update($crc, $buffer, $count)
                    $remaining -= $count
                }
                $entry.SHA256 = [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
                if ($entry.SHA256 -cne $expected[$entry.Path].SHA256 -or [ZSWorkshopCRC32]::Finish($crc) -ne $entry.CRC32) { throw 'GMA payload SHA256 or CRC32 does not match.' }
            } finally { $hash.Dispose() }
        }
        if ($stream.Position -ne $stream.Length - 4) { throw 'GMA payload has unexpected trailing bytes.' }
        $footer = $reader.ReadUInt32()
        $stream.Position = 0
        $remaining = $stream.Length - 4
        $crc = [uint32]::MaxValue
        while ($remaining -gt 0) {
            $count = $stream.Read($buffer, 0, [int][Math]::Min($buffer.Length, $remaining))
            if ($count -le 0) { throw 'GMA archive ended during checksum readback.' }
            $crc = [ZSWorkshopCRC32]::Update($crc, $buffer, $count)
            $remaining -= $count
        }
        if ([ZSWorkshopCRC32]::Finish($crc) -ne $footer) { throw 'GMA archive CRC32 does not match.' }
        $after = Get-Item -LiteralPath $Path -Force
        if ($before.Length -ne $after.Length -or $before.LastWriteTimeUtc.Ticks -ne $after.LastWriteTimeUtc.Ticks) { throw 'GMA changed during readback.' }
        return [ordered]@{Version=3;Title=$title;Type=$metadata.type;Timestamp=$timestamp;Files=$files.ToArray();HeaderAndPayloadVerified=$true;ArchiveCRC32Verified=$true}
    } finally { $reader.Dispose(); $stream.Dispose() }
}

$gmadInfo = Get-Item -LiteralPath $Gmad -Force
if ($gmadInfo.PSIsContainer -or ($gmadInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'GMad must be an installed ordinary executable.' }
$gmadHash = (Get-FileHash -LiteralPath $Gmad -Algorithm SHA256).Hash.ToLowerInvariant()
foreach ($package in @('gamemode','content')) {
    $folder = Join-Path $OutputRoot $package
    $archive = Join-Path $OutputRoot ('zombiesurvival-' + $package + '.gma')
    $stdout = Join-Path $OutputRoot ('gmad-' + $package + '.stdout.txt')
    $stderr = Join-Path $OutputRoot ('gmad-' + $package + '.stderr.txt')
    $process = $null
    try {
        $arguments = 'create -folder "' + $folder + '" -out "' + $archive + '" -quiet'
        $process = Start-Process -FilePath $Gmad -ArgumentList $arguments -WorkingDirectory ([IO.Path]::GetDirectoryName($Gmad)) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $originalHandle = $process.Handle
        if ($originalHandle.ToInt64() -le 0) { throw 'Original GMad handle was not available.' }
        if (-not $process.WaitForExit(120000)) { $process.Kill(); $process.WaitForExit(); throw 'Original GMad exceeded its build deadline.' }
        $process.Refresh()
        if ($process.ExitCode -isnot [int] -or $process.ExitCode -ne 0) { throw 'Original GMad failed.' }
    } finally {
        if ($null -ne $process) {
            try { if (-not $process.HasExited) { $process.WaitForExit() } }
            finally { $process.Dispose() }
        }
    }
    $log = [IO.File]::ReadAllText($stdout) + [IO.File]::ReadAllText($stderr)
    if ($log -match 'not allowed|not permitted|couldn.t|error|failed|invalid') { throw 'GMad reported a rejected file or error; retain its logs.' }
    $archiveInfo = Get-Item -LiteralPath $archive
    if ($archiveInfo.Length -le 0 -or $archiveInfo.Length -gt 2147483648) { throw 'GMA archive is outside the reviewed size bound.' }
    $expected = @($records | Where-Object {$_.Package -ceq $package})
    $verified = Readback-Gma $archive $expected $(if ($package -ceq 'gamemode') {$GamemodeTitle} else {$ContentTitle}) $(if ($package -ceq 'gamemode') {'gamemode'} else {'servercontent'})
    $manifest.Archives += [ordered]@{Package=$package;Path=$archive;Bytes=$archiveInfo.Length;SHA256=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant();GmadSHA256=$gmadHash;Readback=$verified}
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8) + "`n", $utf8)
}
foreach ($entry in $inputs) {
    if ((Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $entry.Source) -Algorithm SHA256).Hash.ToLowerInvariant() -cne $entry.SHA256) { throw 'Pinned source changed before final handback.' }
}
$manifest.Complete = $true
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8) + "`n", $utf8)
[ordered]@{Output=$OutputRoot;StagedFiles=$records.Count;ExcludedContent=$manifest.ExcludedContent.Count;ArchivesBuilt=$true;PayloadReadbackVerified=$true;WorkshopPublished=$false;Manifest=$manifestPath} | ConvertTo-Json -Compress
