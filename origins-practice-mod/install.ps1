$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 't6\scripts\zm\zm_tomb\deathbarrier_practice.gsc'
if (-not (Test-Path -LiteralPath $source)) { throw 'Extrae el ZIP completo antes de ejecutar install.ps1.' }
$directory = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\scripts\zm\zm_tomb'
$target = Join-Path $directory 'deathbarrier_practice.gsc'
New-Item -ItemType Directory -Force -Path $directory | Out-Null
if (Test-Path -LiteralPath $target) {
    $backup = $target + '.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
    Copy-Item -LiteralPath $target -Destination $backup
    Write-Host "Copia anterior guardada: $backup"
}
Copy-Item -LiteralPath $source -Destination $target -Force
Write-Host "Instalado: $target"
Write-Host 'Inicia o reinicia una partida privada de Origins como anfitrion.'
