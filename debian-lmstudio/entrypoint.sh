#!/bin/bash
set -e

if ! ls /etc/ssh/ssh_host_* >/dev/null 2>&1; then
    ssh-keygen -A
fi

su - "${SSH_USER:-dev}" -c "lms daemon up"
su - "${SSH_USER:-dev}" -c "lms server start"
su - "${SSH_USER:-dev}" -c "lms load ${LM_MODEL} --yes" || true

exec /usr/sbin/sshd -D
