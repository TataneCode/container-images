# Image `debian-lmstudio` – Utiliser Qwen 2.5 3B

Ce guide décrit comment utiliser le modèle **Qwen 2.5 3B Instruct**
(GGUF, quantification Q4_K_M) pré-téléchargé dans l'image
`ghcr.io/tatanecode/debian-lmstudio`.

## Contenu de l'image

- **Base** : [linuxserver/lm-studio](https://github.com/linuxserver/docker-lm-studio)
  (LM Studio complet, interface web incluse)
- **Modèle pré-installé** : `lmstudio-community/Qwen2.5-3B-Instruct-GGUF`
  (fichier `Qwen2.5-3B-Instruct-Q4_K_M.gguf`, ~2 Go), présent dans
  `/config/.cache/lm-studio/models/lmstudio-community/Qwen2.5-3B-Instruct-GGUF/`
- Aucun autre outil : pas de SSH, pas d'éditeur — uniquement LM Studio.

| Port | Usage |
|------|-------|
| 3000 | Interface web LM Studio (HTTP, à réserver derrière un reverse proxy) |
| 3001 | Interface web LM Studio (HTTPS, certificat auto-signé) |
| 1234 | Serveur API OpenAI-compatible (à démarrer avec `lms server start`) |

## Lancer le conteneur

```bash
podman pull ghcr.io/tatanecode/debian-lmstudio:latest

podman run -d \
  --name lmstudio \
  --shm-size=1gb \
  -p 3000:3000 \
  -p 3001:3001 \
  -p 1234:1234 \
  -v lmstudio-config:/config \
  ghcr.io/tatanecode/debian-lmstudio:latest
```

(fonctionne identiquement avec `docker`)

Ou via le compose du dépôt :

```bash
podman-compose up -d debian-lmstudio
```

> **GPU (optionnel)** : sur un hôte avec GPU AMD/Intel, ajouter
> `--device /dev/dri -e AUTO_GPU=true`. Sans GPU, le modèle tourne
> correctement sur CPU (le Q4_K_M d'un 3B reste rapide).

## Accéder à l'interface LM Studio

1. Ouvrir **https://localhost:3001** (accepter l'avertissement de certificat
   auto-signé), ou `http://localhost:3000` derrière un reverse proxy.
2. LM Studio s'ouvre avec Qwen 2.5 3B **déjà présent dans la bibliothèque**
   (onglet développeur / mes modèles) — aucun téléchargement nécessaire.
3. Démarrer le serveur local depuis l'interface (Developer → Start Server),
   ou en CLI (voir ci-dessous).

## Démarrer le serveur API (CLI)

Ouvrir un shell dans le conteneur puis lancer :

```bash
podman exec -it lmstudio bash
lms server start --port 1234
```

Vérifier que le serveur répond :

```bash
curl http://localhost:1234/v1/models
```

Réponse attendue (extrait) :

```json
{
  "data": [
    {
      "id": "lmstudio-community/Qwen2.5-3B-Instruct-GGUF",
      "object": "model",
      ...
    }
  ]
}
```

## Charger le modèle en mémoire

Avec le JIT loading activé (par défaut), le modèle est chargé
automatiquement à la première requête. Sinon :

```bash
lms load lmstudio-community/Qwen2.5-3B-Instruct-GGUF
```

Lister les modèles disponibles :

```bash
lms ls          # modèles téléchargés
lms ps          # modèles chargés en mémoire
```

## Interroger Qwen via l'API (OpenAI-compatible)

### Chat (non-streaming)

```bash
curl http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "lmstudio-community/Qwen2.5-3B-Instruct-GGUF",
    "messages": [
      {"role": "system", "content": "Tu es un assistant utile et concis."},
      {"role": "user", "content": "Explique-moi les conteneurs en 2 phrases."}
    ],
    "temperature": 0.7,
    "max_tokens": 200
  }'
```

Réponse (extrait) :

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Les conteneurs sont des environnements isolés..."
      }
    }
  ]
}
```

### Chat en streaming

```bash
curl -N http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "lmstudio-community/Qwen2.5-3B-Instruct-GGUF",
    "messages": [
      {"role": "user", "content": "Écris un haïku sur Docker."}
    ],
    "stream": true
  }'
```

### Chat interactif en CLI (sans API)

```bash
lms chat
```

### Complétion simple

```bash
curl http://localhost:1234/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "lmstudio-community/Qwen2.5-3B-Instruct-GGUF",
    "prompt": "La capitale de la France est",
    "max_tokens": 10
  }'
```

### Depuis n'importe quel client OpenAI

L'API étant compatible OpenAI, n'importe quel SDK fonctionne en pointant
sur `http://localhost:1234/v1` avec n'importe quelle valeur de clé (par
défaut, LM Studio n'exige pas d'authentification en local) :

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:1234/v1", api_key="lm-studio")

response = client.chat.completions.create(
    model="lmstudio-community/Qwen2.5-3B-Instruct-GGUF",
    messages=[
        {"role": "system", "content": "Tu es un assistant utile et concis."},
        {"role": "user", "content": "Bonjour ! Qui es-tu ?"}
    ],
    temperature=0.7,
)
print(response.choices[0].message.content)
```

```js
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://localhost:1234/v1",
  apiKey: "lm-studio",
});

const response = await client.chat.completions.create({
  model: "lmstudio-community/Qwen2.5-3B-Instruct-GGUF",
  messages: [{ role: "user", content: "Bonjour ! Qui es-tu ?" }],
});
console.log(response.choices[0].message.content);
```

## Chat dans le terminal sans serveur

Le CLI `lms` permet aussi de discuter directement :

```bash
lms chat lmstudio-community/Qwen2.5-3B-Instruct-GGUF
```

## Paramètres recommandés pour Qwen 2.5 3B

| Paramètre | Valeur conseillée |
|-----------|-------------------|
| Contexte | 4096 tokens (montable jusqu'à 32k selon la RAM disponible) |
| Temperature | 0.7 (chat), 0.2 (tâches factuelles / code) |
| `max_tokens` | selon la réponse attendue (ex. 512) |

Bonnes pratiques propres aux Qwen 2.5 Instruct :

- Toujours fournir un **system prompt** clair — le modèle est très
  sensible aux instructions système.
- Le modèle gère le **multi-tours** ; conserver l'historique dans
  `messages` pour un contexte cohérent.
- Pour des sorties plus déterministes, descendre `temperature` vers 0.2
  et/ou activer un seed fixe.

## Gestion du modèle

```bash
# Décharger le modèle de la mémoire
lms unload lmstudio-community/Qwen2.5-3B-Instruct-GGUF

# Télécharger une autre quantification (ex. Q8_0, ~3.3 Go, plus précise)
lms get lmstudio-community/Qwen2.5-3B-Instruct-GGUF Q8_0

# Les modèles sont stockés dans le volume /config — persistants entre
# les redémarrages du conteneur si un volume est monté sur /config.
```

## Dépannage

| Problème | Solution |
|----------|----------|
| `connection refused` sur le port 1234 | Le serveur API n'est pas démarré : `lms server start` dans le conteneur |
| L'UI ne charge pas sur `https://localhost:3001` | Accepter le certificat auto-signé du navigateur |
| Le modèle n'apparaît pas dans l'UI | Vérifier `lms ls` ; le fichier doit être dans `/config/.cache/lm-studio/models/` |
| Réponses lentes | Sur CPU, rester en Q4_K_M ; monter le contexte seulement si nécessaire |
| `lms` non trouvé dans le shell | Le binaire est dans le PATH de l'utilisateur `abc` ; sinon `~/.lmstudio/bin/lms` |
