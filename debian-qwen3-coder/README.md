# Image `debian-qwen3-coder` — Ollama + Qwen3 Coder 30B (MoE)

Ce guide décrit comment utiliser le modèle **Qwen3 Coder 30B** (MoE, 30B
totaux / 3,3B actifs, ~19 Go de poids, contexte natif 256K) pré-téléchargé dans
l'image `ghcr.io/tatanecode/debian-qwen3-coder`, pour servir un endpoint
OpenAI-compatible local (par ex. pour un agent de code type opencode), sans
aucun téléchargement au premier démarrage.

## Contenu de l'image

- **Base** : [ollama/ollama](https://hub.docker.com/r/ollama/ollama) (image
  officielle, dérogation à la base Debian 12 comme `debian-lmstudio`)
- **Modèle pré-chargé au build** : `qwen3-coder:30b` (~19 Go de poids), présent
  dans `/root/.ollama/models/` — image finale d'environ **20 Go** (c'est voulu :
  c'est le meilleur modèle de code agentique qui tient en 32 Go de RAM)
- Aucun autre outil : pas de SSH, pas d'éditeur — uniquement le serveur Ollama.
- Variables d'environnement définies dans l'image :

| Variable | Valeur | Rôle |
|----------|--------|------|
| `OLLAMA_HOST` | `0.0.0.0:11434` | écoute sur toutes les interfaces du conteneur (requis pour publier le port) |
| `OLLAMA_CONTEXT_LENGTH` | `32768` | contexte servi par défaut (compromis : 64k avec 19 Go de poids devient juste sur un hôte à 32 Go de RAM) |
| `OLLAMA_KEEP_ALIVE` | `30m` | le modèle reste chargé en mémoire 30 min entre deux requêtes |

Le point d'entrée de l'image de base lance `ollama serve` automatiquement au
démarrage du conteneur.

| Port | Usage |
|------|-------|
| 11434 | API Ollama native (`/api/*`) **et** endpoint OpenAI-compatible (`/v1/*`) |

## Contrainte mémoire hôte

Compter environ **20 Go de RAM libres** au runtime (poids ~19 Go + contexte).
Sous Windows avec Docker Desktop, WSL2 limite par défaut la mémoire à 50 % du
hôte : sur un hôte à 32 Go, régler `C:\Users\<user>\.wslconfig` :

```ini
[wsl2]
memory=24GB
```

puis `wsl --shutdown` et relancer Docker Desktop.

## Lancer le conteneur

```bash
podman pull ghcr.io/tatanecode/debian-qwen3-coder:latest   # ~20 Go à télécharger

podman run -d \
  --name qwen3-coder \
  -p 11435:11434 \
  ghcr.io/tatanecode/debian-qwen3-coder:latest
```

(fonctionne identiquement avec `docker`)

Le port hôte **11435** permet de faire cohabiter ce serveur avec
`debian-qwen25-coder` (port hôte 11434) en même temps.

Ou via le compose du dépôt (mapping `11435:11434`) :

```bash
podman-compose up -d debian-qwen3-coder
```

Vérifier que le modèle est déjà présent (réponse immédiate, aucun téléchargement) :

```bash
curl -s http://localhost:11435/api/tags
```

Réponse attendue (extrait) :

```json
{
  "models": [
    {
      "name": "qwen3-coder:30b",
      "model": "qwen3-coder:30b",
      "size": 19890000000,
      ...
    }
  ]
}
```

## Interroger le modèle via l'API (OpenAI-compatible)

```bash
curl -s http://localhost:11435/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder:30b",
    "messages": [
      {"role": "system", "content": "Tu es un assistant de code utile et concis."},
      {"role": "user", "content": "Écris une fonction Python qui inverse une chaîne."}
    ],
    "temperature": 0.2,
    "max_tokens": 256
  }'
```

En streaming, ajouter `"stream": true` et utiliser `curl -N`.

Depuis n'importe quel client OpenAI, pointer sur `http://localhost:11435/v1`
avec n'importe quelle valeur de clé (pas d'authentification en local) :

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:11435/v1", api_key="ollama")

response = client.chat.completions.create(
    model="qwen3-coder:30b",
    messages=[{"role": "user", "content": "Bonjour ! Qui es-tu ?"}],
)
print(response.choices[0].message.content)
```

## Configurer opencode

Dans `~/.config/opencode/opencode.json` :

```json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama local (Qwen3 Coder)",
      "options": {
        "baseURL": "http://localhost:11435/v1",
        "apiKey": "ollama"
      }
    }
  },
  "model": "ollama/qwen3-coder:30b",
  "limit": { "context": 32768 }
}
```

## Paramètres ajustables au run

```bash
podman run -d --name qwen3-coder -p 11435:11434 \
  -e OLLAMA_CONTEXT_LENGTH=65536 \
  -e OLLAMA_KEEP_ALIVE=1h \
  ghcr.io/tatanecode/debian-qwen3-coder:latest
```

- **Contexte** : 32768 tokens par défaut. Le modèle a un contexte natif de
  256K ; monter à 65536 (voire plus) uniquement si la RAM hôte suit
  (~20 Go de poids + KV cache).
- **`OLLAMA_KEEP_ALIVE`** : durée de maintien du modèle en mémoire entre deux
  requêtes (évite le rechargement de 19 Go entre les appels d'un agent).

## Notes d'exploitation

- **CPU uniquement** : pas de GPU dans l'image, tout tourne sur CPU. `ollama ps`
  dans le conteneur affiche le modèle en `100% CPU` — c'est normal — et la
  colonne CONTEXT reflète `OLLAMA_CONTEXT_LENGTH`. Le chargement des 19 Go de
  poids au premier hit est long : le healthcheck a un `start-period` de 60s.
- **Sécurité** : ne jamais publier le port 11434/11435 sur une interface
  publique de l'hôte (bind `0.0.0.0` interne au conteneur uniquement,
  exposition contrôlée par le mapping de port sur localhost).
- **Artefact `.tar`** : l'export `debian-qwen3-coder-image` du job
  `export-artifacts` fera environ 20 Go, au-dessus de la limite de 10 Go des
  artefacts GitHub — l'upload de cet artefact échouera probablement pour cette
  image seule. Le build et le push vers ghcr.io / Docker Hub ne sont pas
  concernés. Si cela bloque la CI, la parade est d'exclure cette image de la
  matrice du job `export-artifacts` uniquement.

## Dépannage

| Problème | Solution |
|----------|----------|
| `connection refused` sur 11435 | Le conteneur n'est pas démarré, ou le mapping est `-p 11435:11434` : vérifier `podman ps` |
| Le modèle n'apparaît pas dans `/api/tags` | Vérifier `podman exec qwen3-coder ollama list` ; le poids doit être dans `/root/.ollama/models` |
| `OOM` / conteneur tué au premier appel | Pas assez de RAM hôte : ~20 Go libres requis, régler `.wslconfig` sous Windows/WSL2 |
| Réponses très lentes | Normal sur CPU pour 19 Go de poids ; baisser le contexte si la RAM manque |
| `healthcheck` en échec au démarrage | Laisser le `start-period` de 60s (chargement des poids au premier hit) |
