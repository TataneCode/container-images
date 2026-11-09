# Image `debian-lmstudio-twil` — LM Studio + TwIL 8B

Ce guide décrit comment utiliser le modèle **TwIL 8B** (GGUF Q4_K_M, variante
« balanced ») pré-téléchargé dans l'image `ghcr.io/tatanecode/debian-lmstudio-twil` :
interface web LM Studio **et** endpoint API OpenAI-compatible pour opencode.

> **Licence** : TwIL 8B est publié sous *webAI Non-Commercial License 1.0*
> (dérivé d'IBM Granite 4.2 8B) — usage non commercial / local.

## Contenu de l'image

- **Base** : [linuxserver/lm-studio](https://github.com/linuxserver/docker-lm-studio)
  (LM Studio complet, interface web incluse) — même base que `debian-lmstudio`
- **Modèle pré-installé** : `webAI-Official/TwIL-8B`
  (fichier `TwIL-8B-Q4_K_M-balanced.gguf`, ~5,35 Go), présent dans
  `/config/.cache/lm-studio/models/webAI-Official/TwIL-8B/`
- Aucun autre outil : pas de SSH, pas d'éditeur — uniquement LM Studio.

| Port conteneur | Usage | Port hôte (compose/run) |
|----------------|-------|-------------------------|
| 3000 | Interface web LM Studio (HTTP, à réserver derrière un reverse proxy) | **3002** |
| 3001 | Interface web LM Studio (HTTPS, certificat auto-signé) | **3003** |
| 1234 | Serveur API OpenAI-compatible (à démarrer avec `lms server start`) | **1235** |

Les ports hôte 3002/3003/1235 permettent de faire cohabiter cette image avec
`debian-lmstudio` (3000/3001/1234).

## Lancer le conteneur

```bash
docker pull ghcr.io/tatanecode/debian-lmstudio-twil:latest

docker run -d \
  --name lmstudio-twil \
  --shm-size=1gb \
  -p 3002:3000 \
  -p 3003:3001 \
  -p 1235:1234 \
  -v twil-lmstudio-config:/config \
  ghcr.io/tatanecode/debian-lmstudio-twil:latest
```

(fonctionne identiquement avec `podman`)

Ou via le compose du dépôt :

```bash
docker compose up -d debian-lmstudio-twil
```

> **GPU (optionnel)** : sur un hôte avec GPU AMD/Intel, ajouter
> `--device /dev/dri -e AUTO_GPU=true`. Sans GPU, le modèle tourne
> correctement sur CPU (Q4_K_M d'un 8B).

## Accéder à l'interface web LM Studio

1. Ouvrir **https://localhost:3003** (accepter l'avertissement de certificat
   auto-signé), ou `http://localhost:3002` derrière un reverse proxy.
2. LM Studio s'ouvre avec TwIL 8B **déjà présent dans la bibliothèque**
   (onglet développeur / mes modèles) — aucun téléchargement nécessaire.

## Démarrer le serveur API (pour opencode)

Ouvrir un shell dans le conteneur puis lancer :

```bash
docker exec -it lmstudio-twil lms server start --port 1234
```

(ou depuis l'interface web : Developer → Start Server).

Vérifier que le serveur répond :

```bash
curl http://localhost:1235/v1/models
```

Réponse attendue (extrait) :

```json
{
  "data": [
    {
      "id": "webAI-Official/TwIL-8B",
      "object": "model",
      ...
    }
  ]
}
```

## Interroger TwIL via l'API (OpenAI-compatible)

```bash
curl http://localhost:1235/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "webAI-Official/TwIL-8B",
    "messages": [
      {"role": "system", "content": "Tu es un assistant utile et concis."},
      {"role": "user", "content": "Explique-moi les conteneurs en 2 phrases."}
    ],
    "temperature": 0.7,
    "max_tokens": 200
  }'
```

En streaming : `"stream": true` avec `curl -N`.

### Depuis n'importe quel client OpenAI

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:1235/v1", api_key="lm-studio")

response = client.chat.completions.create(
    model="webAI-Official/TwIL-8B",
    messages=[{"role": "user", "content": "Bonjour ! Qui es-tu ?"}],
)
print(response.choices[0].message.content)
```

## Configurer opencode

Dans `~/.config/opencode/opencode.json` :

```json
{
  "provider": {
    "lmstudio-twil": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio local (TwIL 8B)",
      "options": {
        "baseURL": "http://localhost:1235/v1",
        "apiKey": "lm-studio"
      }
    }
  },
  "model": "lmstudio-twil/webAI-Official/TwIL-8B",
  "limit": { "context": 40960 }
}
```

## Paramètres recommandés pour TwIL 8B

La model card upstream recommande un contexte généreux et la config de
génération par défaut de `generation_config.json` :

| Paramètre | Valeur conseillée |
|-----------|-------------------|
| Contexte | 40960 tokens (la card recommande `-c 40960`) |
| Temperature | 1.0 |
| top_p | 0.95 |
| top_k | 50 |
| min_p | 0.0 |
| repeat_penalty | 1.0 |

Le modèle utilise un template ChatML (`<|im_end|>` comme EOS), géré nativement
par LM Studio — aucun flag particulier nécessaire.

## Gestion du modèle

```bash
lms ls          # modèles téléchargés
lms ps          # modèles chargés en mémoire
lms load webAI-Official/TwIL-8B       # pré-charger (JIT loading sinon)
lms unload webAI-Official/TwIL-8B     # décharger
# Les modèles sont stockés dans le volume /config — persistants entre les
# redémarrages du conteneur.
```

## Dépannage

| Problème | Solution |
|----------|----------|
| `connection refused` sur 1235 | Le serveur API n'est pas démarré : `lms server start` dans le conteneur (port conteneur 1234, hôte 1235) |
| L'UI ne charge pas sur `https://localhost:3003` | Accepter le certificat auto-signé du navigateur ; vérifier le mapping `-p 3003:3001` |
| Le modèle n'apparaît pas dans l'UI | Vérifier `lms ls` ; le fichier doit être dans `/config/.cache/lm-studio/models/webAI-Official/TwIL-8B/` |
| Réponses lentes | Sur CPU, rester en Q4_K_M ; le premier hit charge ~5,4 Go en RAM |
| `lms` non trouvé dans le shell | Le binaire est dans le PATH de l'utilisateur `abc` ; sinon `~/.lmstudio/bin/lms` |
