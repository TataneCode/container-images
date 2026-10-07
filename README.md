# container-images

Images conteneurs AlmaLinux 9 pré-construites (x86_64), publiées automatiquement sur ghcr.io par GitHub Actions.

| Image | Contenu |
|---|---|
| `ghcr.io/tatanecode/alma-rust` | AlmaLinux 9, OpenSSH, Rustup/Cargo (stable) + rustfmt + clippy |
| `ghcr.io/tatanecode/alma-dotnet-node` | AlmaLinux 9, OpenSSH, .NET SDK 10, Node.js 24 LTS |

## Récupérer les images

    podman login ghcr.io
    podman pull ghcr.io/tatanecode/alma-rust:latest
    podman pull ghcr.io/tatanecode/alma-dotnet-node:latest

(fonctionne aussi avec `docker`)

## Lancer

    podman run -d --name alma-rust -p 2222:22 ghcr.io/tatanecode/alma-rust:latest
    ssh dev@localhost -p 2222    # mot de passe par défaut : changeme

## Reconstruire localement

    podman build -t alma-rust -f alma-rust/Containerfile .
    podman build -t alma-dotnet-node -f alma-dotnet-node/Containerfile .

Personnalisation au build : `--build-arg SSH_USER=... --build-arg SSH_PASSWORD=...` (+ `DOTNET_VERSION`, `NODE_MAJOR` pour l'image dotnet/node).

## Sécurité

⚠️ Le mot de passe par défaut `changeme` est fourni pour du développement local.
Pour un usage sérieux, préférez l'authentification par clé publique SSH :
montez votre clé publique sur `/home/dev/.ssh/authorized_keys` et désactivez le mot de passe.

## Publier une nouvelle version

    git tag v1.0.0 && git push --tags
