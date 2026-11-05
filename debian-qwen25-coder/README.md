# Image `debian-qwen25-coder` — Ollama + Qwen 2.5 Coder 7B

Ce guide décrit comment utiliser le modèle **Qwen 2.5 Coder 7B** pré-téléchargé
dans l'image `ghcr.io/tatanecode/debian-qwen25-coder`, pour servir un endpoint
OpenAI-compatible local sur `http://localhost:11434/v1` (par ex. pour un agent
de code type opencode), sans aucun téléchargement au premier démarrage.

## Contenu de l'image

- **Base** : [ollama/ollama](https://hub.docker.com/r/ollama/ollama) (image
  officielle, dérogation à la base Debian 12 comme `debian-lmstudio`)
- **Modèle pré-chargé au build** : `qwen2.5-coder:7b` (~4,7 Go de poids),
  présent dans `/root/.ollama/models/` — image finale d'environ **5,5 Go**
- Aucun autre outil : pas de SSH, pas d'éditeur — uniquement le serveur Ollama.
- Variables d'environnement définies dans l'image :

| Variable | Valeur | Rôle |
|----------|--------|------|
| `OLLAMA_HOST` | `0.0.0.0:11434` | écoute sur toutes les interfaces du conteneur (requis pour publier le port) |
| `OLLAMA_CONTEXT_LENGTH` | `32768` | contexte servi par défaut (Ollama sert ~4k sinon, inutilisable pour un agent de code) |
| `OLLAMA_KEEP_ALIVE` | `30m` | le modèle reste chargé en mémoire 30 min entre deux requêtes |

Le point d'entrée de l'image de base lance `ollama serve` automatiquement au
démarrage du conteneur.

| Port | Usage |
|------|-------|
| 11434 | API Ollama native (`/api/*`) **et** endpoint OpenAI-compatible (`/v1/*`) |

## Lancer le conteneur

```bash
docker pull ghcr.io/tatanecode/debian-qwen25-coder:latest

docker run -d \
  --name qwen25-coder \
  -p 11434:11434 \
  ghcr.io/tatanecode/debian-qwen25-coder:latest
```

(fonctionne identiquement avec `podman`)

Ou via le compose du dépôt :

```bash
docker compose up -d debian-qwen25-coder
```

Vérifier que le modèle est déjà présent (réponse immédiate, aucun téléchargement) :

```bash
curl -s http://localhost:11434/api/tags
```

Réponse attendue (extrait) :

```json
{
  "models": [
    {
      "name": "qwen2.5-coder:7b",
      "model": "qwen2.5-coder:7b",
      "size": 5056742876,
      ...
    }
  ]
}
```

## Interroger le modèle via l'API (OpenAI-compatible)

```bash
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [
      {"role": "system", "content": "Tu es un assistant de code utile et concis."},
      {"role": "user", "content": "Écris une fonction Python qui inverse une chaîne."}
    ],
    "temperature": 0.2,
    "max_tokens": 256
  }'
```

Réponse (extrait) :

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "def reverse(s):\n    return s[::-1]\n..."
      }
    }
  ]
}
```

En streaming, ajouter `"stream": true` et utiliser `curl -N`.

Depuis n'importe quel client OpenAI, pointer sur `http://localhost:11434/v1`
avec n'importe quelle valeur de clé (pas d'authentification en local) :

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")

response = client.chat.completions.create(
    model="qwen2.5-coder:7b",
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
      "name": "Ollama local (Qwen 2.5 Coder)",
      "options": {
        "baseURL": "http://localhost:11434/v1",
        "apiKey": "ollama"
      }
    }
  },
  "model": "ollama/qwen2.5-coder:7b",
  "limit": { "context": 32768 }
}
```

## Paramètres ajustables au run

```bash
docker run -d --name qwen25-coder -p 11434:11434 \
  -e OLLAMA_CONTEXT_LENGTH=65536 \
  -e OLLAMA_KEEP_ALIVE=1h \
  ghcr.io/tatanecode/debian-qwen25-coder:latest
```

- **Contexte** : 32768 tokens par défaut (compromis documenté ; opencode
  recommande 64k). Monter à 65536 si la RAM hôte suit.
- **`OLLAMA_KEEP_ALIVE`** : durée de maintien du modèle en mémoire entre deux
  requêtes (évite le rechargement entre les appels d'un agent).

## Notes d'exploitation

- **CPU uniquement** : pas de GPU dans l'image, tout tourne sur CPU (cas
  d'usage visé : laptop). `ollama ps` dans le conteneur affiche le modèle en
  `100% CPU` — c'est normal — et la colonne CONTEXT reflète
  `OLLAMA_CONTEXT_LENGTH`.
- **Mémoire** : compter ~6–8 Go de RAM libres au runtime (poids + contexte).
- **Sécurité** : ne jamais publier le port 11434 sur une interface publique de
  l'hôte (bind `0.0.0.0` interne au conteneur uniquement, exposition contrôlée
  par le mapping de port `-p 11434:11434` sur localhost).

## Dépannage

| Problème | Solution |
|----------|----------|
| `connection refused` sur 11434 | Le conteneur n'est pas démarré, ou le port n'est pas mappé : vérifier `docker ps` et `-p 11434:11434` |
| Le modèle n'apparaît pas dans `/api/tags` | Vérifier `docker exec qwen25-coder ollama list` ; le poids doit être dans `/root/.ollama/models` |
| Réponses lentes | Normal sur CPU pour un 7B ; baisser le contexte si la RAM manque |
| `healthcheck` en échec au démarrage | Laisser le `start-period` de 30s ; vérifier `docker inspect --format '{{.State.Health.Status}}' qwen25-coder` |
