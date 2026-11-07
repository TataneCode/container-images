#!/bin/bash
set -e

# Régénère les clés d'hôte SSH si absentes (p.ex. volume vide monté sur /etc/ssh)
if ! ls /etc/ssh/ssh_host_* >/dev/null 2>&1; then
    ssh-keygen -A
fi

exec /usr/sbin/sshd -D
