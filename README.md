# container-images

Images conteneurs AlmaLinux 9 et Debian 12 (Bookworm) pré-construites (x86_64), publiées automatiquement sur ghcr.io par GitHub Actions.

| Image | Contenu |
|---|---|
| `ghcr.io/tatanecode/alma-rust` | AlmaLinux 9, OpenSSH, Rustup/Cargo (stable) + rustfmt + clippy, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/alma-dotnet-node` | AlmaLinux 9, OpenSSH, .NET SDK 10, Node.js 24 LTS, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/alma-dotnet` | AlmaLinux 9, OpenSSH, .NET SDK 10 uniquement, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/alma-node` | AlmaLinux 9, OpenSSH, Node.js 24 LTS uniquement, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/debian-rust` | Debian 12 (Bookworm), OpenSSH, Rustup/Cargo (stable) + rustfmt + clippy, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/debian-dotnet-node` | Debian 12 (Bookworm), OpenSSH, .NET SDK 10, Node.js 24 LTS, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/debian-dotnet` | Debian 12 (Bookworm), OpenSSH, .NET SDK 10 uniquement, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/debian-node` | Debian 12 (Bookworm), OpenSSH, Node.js 24 LTS uniquement, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/alma-cpp` | AlmaLinux 9, OpenSSH, GCC + Clang + clang-format + clang-tidy, CMake, Ninja, GDB, Git, ccache, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/debian-cpp` | Debian 12 (Bookworm), OpenSSH, GCC + Clang + clang-format + clang-tidy, CMake, Ninja, GDB, Git, ccache, Neovim (v0.12 officiel) + LazyVim pré-configuré, Git, ripgrep, fd, Yazi |
| `ghcr.io/tatanecode/debian-lmstudio` | LM Studio (surcouche de l'image `linuxserver/lm-studio`), modèle Qwen 2.5 3B Instruct (GGUF Q4_K_M) pré-téléchargé, interface web sur le port 3001 (HTTPS) et 3000 (HTTP), serveur API OpenAI-compatible sur le port 1234 via `lms server start` |

## Récupérer les images

    podman login ghcr.io
    podman pull ghcr.io/tatanecode/alma-rust:latest
    podman pull ghcr.io/tatanecode/alma-dotnet-node:latest
    podman pull ghcr.io/tatanecode/alma-dotnet:latest
    podman pull ghcr.io/tatanecode/alma-node:latest
    podman pull ghcr.io/tatanecode/debian-rust:latest
    podman pull ghcr.io/tatanecode/debian-dotnet-node:latest
    podman pull ghcr.io/tatanecode/debian-dotnet:latest
    podman pull ghcr.io/tatanecode/debian-node:latest
    podman pull ghcr.io/tatanecode/alma-cpp:latest
    podman pull ghcr.io/tatanecode/debian-cpp:latest
    podman pull ghcr.io/tatanecode/debian-lmstudio:latest

(fonctionne aussi avec `docker`)

### Téléchargement direct (tar)

À chaque build, les images sont aussi exportées en archives `.tar` téléchargeables
depuis la page **Actions** du dépôt (artefacts `alma-rust-image`,
`alma-dotnet-node-image`, `alma-dotnet-image`, `alma-node-image`,
`debian-rust-image`, `debian-dotnet-node-image`, `debian-dotnet-image`,
`debian-node-image`,
`alma-cpp-image`, `debian-cpp-image`, `debian-lmstudio-image`, conservés 14 jours) :

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

## Lancer toutes les images (compose)

    docker compose pull
    docker compose up -d

Télécharge (version `latest` à chaque fois) et lance les 10 images, avec redirection des ports SSH :

| Conteneur | Port SSH |
|---|---|
| alma-rust | 2222 |
| alma-dotnet-node | 2223 |
| alma-dotnet | 2228 |
| alma-node | 2229 |
| alma-cpp | 2224 |
| debian-rust | 2225 |
| debian-dotnet-node | 2226 |
| debian-dotnet | 2230 |
| debian-node | 2231 |
| debian-cpp | 2227 |

    ssh dev@localhost -p 2222   # mot de passe par défaut : changeme

Arrêter tout :

    docker compose down

## Reconstruire localement

    podman build -t alma-rust -f alma-rust/Containerfile .
    podman build -t alma-dotnet-node -f alma-dotnet-node/Containerfile .
    podman build -t alma-dotnet -f alma-dotnet/Containerfile .
    podman build -t alma-node -f alma-node/Containerfile .
    podman build -t debian-rust -f debian-rust/Containerfile .
    podman build -t debian-dotnet-node -f debian-dotnet-node/Containerfile .
    podman build -t debian-dotnet -f debian-dotnet/Containerfile .
    podman build -t debian-node -f debian-node/Containerfile .
    podman build -t alma-cpp -f alma-cpp/Containerfile .
    podman build -t debian-cpp -f debian-cpp/Containerfile .

Personnalisation au build : `--build-arg SSH_USER=... --build-arg SSH_PASSWORD=...` (+ `DOTNET_VERSION`, `NODE_MAJOR` pour les images dotnet/node, `YAZI_VERSION` pour toutes les images).

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

### C++ (images `alma-cpp` et `debian-cpp`)

Chaîne d'outils complète pour développer en C++ :

- `g++` et `clang++` (compilateurs GCC et Clang)
- `clang-format` et `clang-tidy` (formattage et analyse statique)
- `cmake` et `ninja` (systèmes de build)
- `gdb` (débogueur), `git`, `pkg-config`, `ccache`

Exemple :

    g++ -std=c++20 hello.cpp -o hello
    cmake -B build -G Ninja && cmake --build build

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

### Neovim + LazyVim

`nvim` est le binaire officiel Neovim (v0.12), installé dans `/usr/local/bin`
(la version des dépôts AlmaLinux/Debian est trop ancienne pour LazyVim).

LazyVim (surcouche de Neovim basée sur lazy.nvim) est pré-installé pour
l'utilisateur `dev` avec tous ses plugins déjà restaurés au build : le premier
lancement est donc immédiatement utilisable, sans téléchargement.

    nvim fichier.txt    # éditer un fichier (LazyVim démarre automatiquement)

Quelques raccourcis utiles (`<leader>` est la barre d'espace) :

- `<leader>ff` : chercher des fichiers (telescope)
- `<leader>sg` : chercher du texte (grep live, via ripgrep)
- `<leader>e` : explorateur de fichiers (neo-tree)
- `<leader>gg` : terminal flottant lazygit (si installé)

Configuration dans `~/.config/nvim/` (starter LazyVim) :

- `lua/config/lazy.lua` : bootstrap lazy.nvim
- `lua/config/options.lua`, `keymaps.lua`, `autocmds.lua` : options, raccourcis, autocmds
- `lua/plugins/` : ajouter ses plugins ici

Documentation LazyVim : https://lazyvim.org

## Sécurité

⚠️ Le mot de passe par défaut `changeme` est fourni pour du développement local.
Pour un usage sérieux, préférez l'authentification par clé publique SSH :
montez votre clé publique sur `/home/dev/.ssh/authorized_keys` et désactivez le mot de passe.

## Publier une nouvelle version

    git tag v1.0.0 && git push --tags
