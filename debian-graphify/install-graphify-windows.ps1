# Kit d'installation OFFLINE de graphify pour Windows x86_64 (extrait de l'image debian-graphify).
# Usage : ouvrir PowerShell dans le dossier extrait, puis   .\install.ps1
#
# Prerequisite : Python 3.11 a 3.14 present sur la machine (python.org), ou un Python
# gere par uv deja en cache (uv tool install telecharge son propre Python si en ligne).
# Sans Python, en ligne :  winget install astral-sh.uv   puis   uv tool install "graphifyy[mcp]"
$ErrorActionPreference = "Stop"
$kit = $PSScriptRoot
$uv  = Join-Path $kit "uv.exe"

& $uv tool install --offline --find-links (Join-Path $kit "wheels") "graphifyy[mcp]==__GRAPHIFY_VERSION__"
& $uv tool update-shell

$bin = & $uv tool dir
Write-Host ""
Write-Host "graphify __GRAPHIFY_VERSION__ installe. Binaires dans : $bin\bin"
Write-Host "  graphify.exe / graphify-mcp.exe  (ajoutez $bin\bin au PATH ou lancez uv tool update-shell dans un nouveau terminal)"
Write-Host ""
Write-Host "Ensuite, dans votre projet :  graphify install --platform gemini"
Write-Host "Puis, dans Gemini CLI : /graphify .   (ou branchez le serveur MCP, voir README de l'image)"
