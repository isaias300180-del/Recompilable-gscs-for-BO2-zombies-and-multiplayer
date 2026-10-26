$ErrorActionPreference = 'Stop'
function Get-DbpHash([byte[]]$data) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
$path = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\scripts\zm\zm_tomb\deathbarrier_practice.gsc'
$bytes = [IO.File]::ReadAllBytes($path)
$oldHash = 'bd1184fe0234e1528607c68175f8f5fd196b52bd5b6fcb97b3c330d6af14728c'
$newHash = '35a5f7495c65551d0bf26b425e215dae11d8b96759ae59a2a7c4b62b1348307d'
$actualHash = Get-DbpHash $bytes
if ($actualHash -eq $newHash) { Write-Host 'Ya esta actualizado.'; return }
if ($actualHash -ne $oldHash) { throw 'Esta version es diferente. No se modifico el archivo.' }
# Exact delta against the initial build; includes updated function checksums.
# The resulting bytes must match the newly compiled source, verified below.
$edits = @{
    3292=0; 3293=0; 3294=128; 3344=0; 3345=0; 3346=128
    3425=2; 3427=2
    4476=0x66; 4477=0x66; 4478=0xe6; 4479=0x3e
    4844=0x0b; 4845=0xeb; 4846=0x2e; 4847=0x50
    4868=0x39; 4869=0xe4; 4870=0xf7; 4871=0xce
}
foreach ($offset in $edits.Keys) { $bytes[[int]$offset] = [byte]$edits[$offset] }
if ((Get-DbpHash $bytes) -ne $newHash) { throw 'No coincidio la verificacion. No se modifico el archivo.' }
$backup = $path + '.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
Copy-Item -LiteralPath $path -Destination $backup
[IO.File]::WriteAllBytes($path, $bytes)
Write-Host 'HUD corregido y balizas reducidas. Reinicia el mapa.' -ForegroundColor Green
