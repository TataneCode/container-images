# Image `debian-graphify` — hôte graphify (CLI + serveur MCP) + kit Windows offline

Image basée sur **`python:3.13-bookworm`** (Debian 12 + Python 3.13 officiel) avec :

- **les outils pour installer graphify** : `uv` + `pip`, et `graphifyy[mcp]`
  (paquet PyPI officiel, version épinglée `0.9.112`) **pré-installé** :
  `graphify` et `graphify-mcp` sont dans le PATH
- **le kit Windows** embarqué à `/artifacts/graphify-windows-kit.zip` :
  `uv.exe` (Windows x86_64) + toutes les wheels `win_amd64` de `graphifyy[mcp]`
  + `install.ps1` → produit `graphify.exe` / `graphify-mcp.exe` sur une machine
  Windows **sans accès à Internet**
- utilisable comme **hôte du serveur MCP** (stdio ou HTTP sur le port 8080)

Projet upstream : [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify)
(licence Apache-2.0 ; paquet PyPI `graphifyy`).

| Port | Usage |
|------|-------|
| 8080 | Serveur MCP graphify en HTTP (Streamable HTTP, endpoint `/mcp`) quand on lance `python -m graphify.serve <graph.json> --transport http` |

## 1. Récupérer le kit Windows (graphify.exe)

Depuis n'importe quelle machine avec Docker :

```bash
docker pull ghcr.io/tatanecode/debian-graphify:latest

docker run --rm \
  -v "$PWD:/out" \
  --entrypoint cp \
  ghcr.io/tatanecode/debian-graphify:latest \
  /artifacts/graphify-windows-kit.zip /out/

ls graphify-windows-kit.zip
```

Transférer le zip sur la machine Windows, extraire, puis dans PowerShell :

```powershell
.\install.ps1        # installe graphifyy[mcp]==0.9.112 hors ligne via uv.exe + wheels/
```

Prérequis côté Windows : Python 3.11–3.14 (python.org) ou un Python géré par uv déjà
en cache. (En ligne, le plus simple reste `winget install astral-sh.uv` puis
`uv tool install "graphifyy[mcp]"` — le kit sert précisément pour le hors-ligne.)

`uv tool install` crée les lanceurs **`graphify.exe`** et **`graphify-mcp.exe`**
dans `%LOCALAPPDATA%\uv\tools\...\Scripts` (ajouté au PATH via `uv tool update-shell`).

### Brancher graphify sur Gemini CLI (Windows)

Dans `%USERPROFILE%\.gemini\settings.json` (MCP en stdio) :

```json
{
  "mcpServers": {
    "graphify": {
      "command": "graphify.exe",
      "args": ["C:\\chemin\\vers\\votre\\projet", "--mcp"]
    }
  }
}
```

Puis dans le projet : `graphify install --platform gemini` (enregistre le skill),
et `/graphify .` dans Gemini CLI pour construire le graphe. Variante : serveur MCP
HTTP (section 3) avec `"url": "http://localhost:8080/mcp"`.

## 2. Utiliser l'image comme hôte CLI (construire un graphe)

```bash
docker run --rm -v "$PWD:/work" -w /work ghcr.io/tatanecode/debian-graphify:latest graphify .
# produit ./graphify-out/ (graph.json, graph.html, GRAPH_REPORT.md)
```

Autres commandes dans le conteneur : `graphify query "..."`, `graphify path A B`,
`graphify explain "..."`, ou `uv tool install "graphifyy[pdf,watch]"` pour des extras.

## 3. Utiliser l'image comme hôte du serveur MCP

**MCP stdio** (un client MCP par conteneur, ex. via `docker run -i`) :

```bash
docker run --rm -i -v "$PWD:/work" -w /work ghcr.io/tatanecode/debian-graphify:latest graphify /work --mcp
```

**MCP HTTP** (partagé, ex. plusieurs clients ou Gemini CLI en remote) :

```bash
docker run --rm -d --name graphify-mcp -p 8080:8080 \
  -v "$PWD:/work" -w /work \
  ghcr.io/tatanecode/debian-graphify:latest \
  python -m graphify.serve /work/graphify-out/graph.json --transport http --host 0.0.0.0 --port 8080
```

Endpoint MCP : **http://localhost:8080/mcp** (ajouter `--api-key "$SECRET"` pour
protéger ; ne pas publier le port hors localhost sans clé).

Via le compose du dépôt (volume `graphify-data:/data`, port hôte 8080) :

```bash
# 1. construire le graphe dans le volume nommé :
docker compose run --rm -v "$PWD:/src" -w /src debian-graphify graphify . && \
  docker compose run --rm -v "$PWD/graphify-out:/src" debian-graphify cp /src/graph.json /data/graph.json
# 2. lancer le serveur MCP HTTP :
docker compose up -d debian-graphify
```

## Contenu détaillé

| Élément | Détail |
|---------|--------|
| Base | `python:3.13-bookworm` (Debian 12 Bookworm + Python 3.13) |
| Outils d'installation | `uv` (0.13.9), `pip`, `git`, `curl` |
| graphify | `graphifyy[mcp]==0.9.112` pré-installé → `graphify`, `graphify-mcp` |
| Kit Windows | `/artifacts/graphify-windows-kit.zip` (uv.exe + wheels win_amd64 + install.ps1) |
| Versions épinglées au build | `--build-arg GRAPHIFY_VERSION=... --build-arg UV_VERSION=...` |

## Dépannage

| Problème | Solution |
|----------|----------|
| `pip download --platform win_amd64` échoue au build | Une dépendance n'a pas de wheel Windows : retirer l'extra concerné (ex. `[mcp]` → base) ou monter la version de Python cible (`--python-version`) |
| Le kit Windows ne s'installe pas hors ligne | Il faut Python 3.11–3.14 sur la machine Windows (ou un uv python en cache) ; sinon installer en ligne avec `winget install astral-sh.uv` + `uv tool install "graphifyy[mcp]"` |
| Le serveur HTTP ne répond pas sur 8080 | Vérifier que `graph.json` existe au chemin passé à `graphify.serve` ; logs : `docker logs graphify-mcp` |
| `graphify` non trouvé dans le conteneur | Il est dans `/usr/local/bin` (install pip global de l'image officielle Python) |
