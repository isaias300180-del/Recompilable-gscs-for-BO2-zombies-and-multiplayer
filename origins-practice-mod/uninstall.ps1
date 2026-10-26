$ErrorActionPreference = 'Stop'
$target = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\scripts\zm\zm_tomb\deathbarrier_practice.gsc'
if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target
    Write-Host 'Mod retirado. Reinicia el mapa para restaurar el monitor original.'
} else {
    Write-Host 'El archivo del mod no esta instalado en la ruta predeterminada.'
}
