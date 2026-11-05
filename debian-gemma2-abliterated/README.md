# Image `debian-gemma2-abliterated` — Ollama + Gemma 2 9B abliterated

Ce guide décrit comment utiliser le modèle **Gemma 2 9B Instruct abliterated**
(variante « uncensored » : le comportement de refus a été retiré au niveau des
poids) pré-téléchargé dans l'image `ghcr.io/tatanecode/debian-gemma2-abliterated`,
pour servir un endpoint OpenAI-compatible local, sans aucun téléchargement au
premier démarrage.

> **Usage local uniquement** : ce modèle est une variante non censurée. Ne jamais
> publier le port 11434 sur une interface publique de l'hôte.

## Contenu de l'image

- **Base** : [ollama/ollama](https://hub.docker.com/r/ollama/ollama) (image
  officielle, dérogation à la base Debian 12 comme `debian-lmstudio`)
- **Modèle pré-chargé au build** : `jaahas/gemma-2-9b-it-abliterated:latest`
  (Gemma 2 9B abliterated, quantification Q5_K_M, ~6,6 Go de poids), présent dans
  `/root/.ollama/models/` — image finale d'environ **7 Go**
- Aucun autre outil : pas de SSH, pas d'éditeur — uniquement le serveur Ollama.
- Variables d'environnement définies dans l'image :

| Variable | Valeur | Rôle |
|----------|--------|------|
| `OLLAMA_HOST` | `0.0.0.0:11434` | écoute sur toutes les interfaces du conteneur (requis pour publier le port) |
| `OLLAMA_CONTEXT_LENGTH` | `32768` | contexte servi par défaut (Gemma 2 natif : 8K) |
| `OLLAMA_KEEP_ALIVE` | `30m` | le modèle reste chargé en mémoire 30 min entre deux requêtes |

Le point d'entrée de l'image de base lance `ollama serve` automatiquement au
démarrage du conteneur.

| Port | Usage |
|------|-------|
| 11434 | API Ollama native (`/api/*`) **et** endpoint OpenAI-compatible (`/v1/*`) |

## Lancer le conteneur

```bash
docker pull ghcr.io/tatanecode/debian-gemma2-abliterated:latest

docker run -d \
  --name gemma2-abliterated \
  -p 11436:11434 \
  ghcr.io/tatanecode/debian-gemma2-abliterated:latest
```

(fonctionne identiquement avec `podman`)

Le port hôte **11436** permet de faire cohabiter ce serveur avec
`debian-qwen25-coder` (11434) et `debian-qwen3-coder` (11435) en même temps.

Ou via le compose du dépôt (mapping `11436:11434`) :

```bash
docker compose up -d debian-gemma2-abliterated
```

Vérifier que le modèle est déjà présent (réponse immédiate, aucun téléchargement) :

```bash
curl -s http://localhost:11436/api/tags
```

Réponse attendue (extrait) :

```json
{
  "models": [
    {
      "name": "jaahas/gemma-2-9b-it-abliterated:latest",
      "model": "jaahas/gemma-2-9b-it-abliterated:latest",
      "size": 6600000000,
      ...
    }
  ]
}
```

## Interroger le modèle via l'API (OpenAI-compatible)

```bash
curl -s http://localhost:11436/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "jaahas/gemma-2-9b-it-abliterated:latest",
    "messages": [
      {"role": "system", "content": "Tu es un assistant utile et concis."},
      {"role": "user", "content": "Explique-moi les conteneurs en 2 phrases."}
    ],
    "temperature": 0.7,
    "max_tokens": 200
  }'
```

En streaming, ajouter `"stream": true` et utiliser `curl -N`.

Depuis n'importe quel client OpenAI, pointer sur `http://localhost:11436/v1`
avec n'importe quelle valeur de clé (pas d'authentification en local) :

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:11436/v1", api_key="ollama")

response = client.chat.completions.create(
    model="jaahas/gemma-2-9b-it-abliterated:latest",
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
      "name": "Ollama local (Gemma 2 9B abliterated)",
      "options": {
        "baseURL": "http://localhost:11436/v1",
        "apiKey": "ollama"
      }
    }
  },
  "model": "ollama/jaahas/gemma-2-9b-it-abliterated:latest",
  "limit": { "context": 32768 }
}
```

## Paramètres ajustables au run

```bash
docker run -d --name gemma2-abliterated -p 11436:11434 \
  -e OLLAMA_CONTEXT_LENGTH=8192 \
  -e OLLAMA_KEEP_ALIVE=1h \
  ghcr.io/tatanecode/debian-gemma2-abliterated:latest
```

- **Contexte** : 32768 tokens par défaut (le contexte natif de Gemma 2 est 8K ;
  monter au-delà consomme de la RAM pour le cache KV).
- **`OLLAMA_KEEP_ALIVE`** : durée de maintien du modèle en mémoire entre deux
  requêtes (évite le rechargement entre les appels d'un agent).

## Notes d'exploitation

- **CPU uniquement** : pas de GPU dans l'image, tout tourne sur CPU. `ollama ps`
  dans le conteneur affiche le modèle en `100% CPU` — c'est normal — et la
  colonne CONTEXT reflète `OLLAMA_CONTEXT_LENGTH`.
- **Mémoire** : compter ~8–10 Go de RAM libres au runtime (poids ~6,6 Go + contexte).
- **Sécurité** : variante non censurée destinée à un usage local ; ne jamais
  publier le port sur une interface publique (bind `0.0.0.0` interne au
  conteneur uniquement, exposition contrôlée par le mapping de port sur localhost).

## Dépannage

| Problème | Solution |
|----------|----------|
| `connection refused` sur 11436 | Le conteneur n'est pas démarré, ou le mapping est `-p 11436:11434` : vérifier `docker ps` |
| Le modèle n'apparaît pas dans `/api/tags` | Vérifier `docker exec gemma2-abliterated ollama list` ; le poids doit être dans `/root/.ollama/models` |
| Réponses lentes | Normal sur CPU pour un 9B ; baisser le contexte si la RAM manque |
| `healthcheck` en échec au démarrage | Laisser le `start-period` de 30s ; vérifier `docker inspect --format '{{.State.Health.Status}}' gemma2-abliterated` |
