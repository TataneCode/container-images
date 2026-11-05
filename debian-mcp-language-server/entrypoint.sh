#!/bin/bash
set -e

# Copie l'artefact embarque (mcp-language-server.exe, Windows amd64) vers $DEST (defaut : /out) puis sort.
DEST="${DEST:-/out}"
mkdir -p "${DEST}"
cp /artifacts/mcp-language-server.exe "${DEST}/mcp-language-server.exe"
echo "Artefact copie dans ${DEST}/mcp-language-server.exe"
