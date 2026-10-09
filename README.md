# container-images

Images conteneurs AlmaLinux 9 pré-construites (x86_64), publiées automatiquement sur ghcr.io par GitHub Actions.

| Image | Contenu |
|---|---|
| `ghcr.io/tatanecode/alma-rust` | AlmaLinux 9, OpenSSH, Rustup/Cargo (stable) + rustfmt + clippy, Neovim, Yazi |
| `ghcr.io/tatanecode/alma-dotnet-node` | AlmaLinux 9, OpenSSH, .NET SDK 10, Node.js 24 LTS, Neovim, Yazi |

## Récupérer les images

    podman login ghcr.io
    podman pull ghcr.io/tatanecode/alma-rust:latest
    podman pull ghcr.io/tatanecode/alma-dotnet-node:latest

(fonctionne aussi avec `docker`)

### Téléchargement direct (tar)

À chaque build, les images sont aussi exportées en archives `.tar` téléchargeables
depuis la page **Actions** du dépôt (artefacts `alma-rust-image` et
`alma-dotnet-node-image`, conservés 14 jours) :

1. Ouvrir l'onglet **Actions** et sélectionner le dernier run successful
2. En bas de page, télécharger l'artefact souhaité

Puis charger l'image localement :

    podman load -i alma-rust.tar
    # ou
    docker load -i alma-rust.tar

Utile pour les environnements sans accès au registre (réseau isolé, air-gapped).

## Lancer

    podman run -d --name alma-rust -p 2222:22 ghcr.io/tatanecode/alma-rust:latest
    ssh dev@localhost -p 2222    # mot de passe par défaut : changeme

## Reconstruire localement

    podman build -t alma-rust -f alma-rust/Containerfile .
    podman build -t alma-dotnet-node -f alma-dotnet-node/Containerfile .

Personnalisation au build : `--build-arg SSH_USER=... --build-arg SSH_PASSWORD=...` (+ `DOTNET_VERSION`, `NODE_MAJOR` pour l'image dotnet/node, `YAZI_VERSION` pour les deux images).

## Utiliser `su` dans le conteneur

L'utilisateur `dev` (ou `SSH_USER`) est créé avec `/bin/bash` comme shell.
Pour exécuter une commande en tant que cet utilisateur depuis une session root (par exemple avec `podman exec`) :

    podman exec -it alma-dotnet-node su - dev -c "dotnet --version"

Pour ouvrir un shell interactif :

    podman exec -it alma-dotnet-node su - dev

Le `-` (login shell) charge le profil de l'utilisateur (`~/.bash_profile`).
En SSH, la session utilise déjà directement l'utilisateur configuré.

## Shell par défaut : bash

Les images utilisent `/bin/bash` comme shell (utilisateur `dev` inclus).
Sous AlmaLinux/RHEL, `/bin/sh` est déjà un lien symbolique vers `bash`, donc les
scripts `sh` restent compatibles ; mais pour un shell interactif, préférez `bash`.

## Outils inclus

### Yazi (file manager console)

`yazi` est un gestionnaire de fichiers en terminal, rapide et configurable.
Binaire officiel installé dans `/usr/local/bin` (version `v26.9.1`), accompagné
de `ya` (assistant pour plugins, actions shell et paquets).

Utilisation basique :

    yazi              # ouvrir dans le répertoire courant

Navigation : flèches (ou `hjkl`), `Enter` pour ouvrir, `q` pour quitter,
`:` pour la ligne de commande, `?` pour l'aide.

Configuration dans `~/.config/yazi/yazi.toml`. Documentation complète :
https://yazi-rs.github.io

### Neovim

`nvim` est installé depuis les dépôts AlmaLinux/EPEL.

    nvim fichier.txt    # éditer un fichier

Configuration dans `~/.config/nvim/`. Documentation : https://neovim.io

## Sécurité

⚠️ Le mot de passe par défaut `changeme` est fourni pour du développement local.
Pour un usage sérieux, préférez l'authentification par clé publique SSH :
montez votre clé publique sur `/home/dev/.ssh/authorized_keys` et désactivez le mot de passe.

## Publier une nouvelle version

    git tag v1.0.0 && git push --tags
