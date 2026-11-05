# Image `debian-mcp-language-server` — porteur de l'artefact `mcp-language-server.exe` (Windows amd64)

Cette image ne **sert** rien : c'est un porteur d'artefact. Au lancement, le
conteneur copie le binaire Windows embarqué vers `$DEST` (défaut `/out`) puis
s'arrête. Utile pour récupérer `mcp-language-server.exe` (pont MCP → LSP) depuis
une machine Linux/macOS sans toolchain Go, p.ex. pour le déposer sur un hôte
Windows ou dans un partage.

## Contenu de l'image

- **Base** : `debian:bookworm-slim` (porteur minimal, cohérent avec le reste du dépôt)
- **Artefact embarqué** : `/artifacts/mcp-language-server.exe`
  - compilé en cross-compilation depuis `golang:1.24-bookworm`
    (`GOOS=windows GOARCH=amd64 CGO_ENABLED=0` → binaire statique, aucune
    dépendance à l'exécution)
  - version **épinglée** : `v0.1.1` de
    [isaacphi/mcp-language-server](https://github.com/isaacphi/mcp-language-server),
    surchargeable au build : `--build-arg MCP_LANGUAGE_SERVER_VERSION=v0.1.1`
- **Entrypoint** : `/usr/local/bin/entrypoint.sh` copie l'artefact vers
  `$DEST` (défaut `/out`) puis quitte.

| Port | Usage |
|------|-------|
| aucun | le conteneur n'expose aucun port : il copie l'artefact et s'arrête (`docker run --rm`) |

## Récupérer le binaire

```bash
docker pull ghcr.io/tatanecode/debian-mcp-language-server:latest

docker run --rm \
  -v "$(pwd)/out:/out" \
  ghcr.io/tatanecode/debian-mcp-language-server:latest

ls -l out/mcp-language-server.exe
```

(fonctionne identiquement avec `podman`)

Variante avec un autre répertoire de sortie :

```bash
docker run --rm \
  -e DEST=/data \
  -v "$(pwd)/data:/data" \
  ghcr.io/tatanecode/debian-mcp-language-server:latest
```

Ou via le compose du dépôt (copie dans le volume nommé `mcp-ls-out`, monté sur
`/out`) :

```bash
docker compose up debian-mcp-language-server
# puis, pour extraire le fichier du volume nommé :
docker run --rm -v mcp-ls-out:/src -v "$(pwd):/dst alpine sh -c 'cp /src/mcp-language-server.exe /dst/'
```

## Reconstruire localement

```bash
docker build -f debian-mcp-language-server/Containerfile -t debian-mcp-language-server:dev .

# avec une autre version du serveur MCP :
docker build -f debian-mcp-language-server/Containerfile \
  --build-arg MCP_LANGUAGE_SERVER_VERSION=v0.1.0 \
  -t debian-mcp-language-server:dev .

docker run --rm -v "$(pwd)/out:/out" debian-mcp-language-server:dev
```

## Dépannage

| Problème | Solution |
|----------|----------|
| `permission denied` sur le `.exe` copié | Le binaire est copié tel quel ; sous Linux : `chmod +x out/mcp-language-server.exe` (inutile côté Windows) |
| Le fichier n'apparaît pas dans le dossier monté | Vérifier le mapping `-v <hôte>:/out` (ou `-e DEST=...` + montage correspondant) et que le conteneur a bien tourné (`docker ps -a`) |
| `go install ...@v0.1.1` échoue au build | Tag inexistant ou supprimé upstream : vérifier les tags disponibles et surcharger `--build-arg MCP_LANGUAGE_SERVER_VERSION=...` |
