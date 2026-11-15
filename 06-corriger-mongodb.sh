#!/usr/bin/env bash
# Correction MongoDB : l'image docker.io/bitnami/mongodb:4.4.4-debian-10-r0 n'existe plus.
# Bitnami a déplacé ses anciennes images vers docker.io/bitnamilegacy, mais la version
# 4.4.4-debian-10-r0 n'y a pas été copiée. On prend donc 4.4.13-debian-10-r52, qui existe
# dans bitnamilegacy (même branche MongoDB 4.4, même base Debian 10).
# On garde tous les autres réglages de l'installation (--reuse-values).
set -e

helm upgrade free5gc-v1 towards5gs/free5gc \
  --namespace free5gc \
  --reuse-values \
  --set mongodb.image.repository=bitnamilegacy/mongodb \
  --set mongodb.image.tag=4.4.13-debian-10-r52

# Supprime le pod bloqué pour qu'il soit recréé avec la nouvelle image.
kubectl delete pod mongodb-0 -n free5gc --ignore-not-found

echo
echo "Correction appliquée. Suis le démarrage avec :"
echo "  kubectl get pods -n free5gc -w"
