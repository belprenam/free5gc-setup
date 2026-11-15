#!/usr/bin/env bash
# Correction MongoDB : l'image docker.io/bitnami/mongodb:4.4.4-debian-10-r0 n'existe plus
# sur Docker Hub (Bitnami a déplacé ses anciennes images vers docker.io/bitnamilegacy).
# On garde tous les réglages de l'installation (--reuse-values) et on change seulement
# le dépôt de l'image MongoDB.
set -e

helm upgrade free5gc-v1 towards5gs/free5gc \
  --namespace free5gc \
  --reuse-values \
  --set mongodb.image.repository=bitnamilegacy/mongodb

# Supprime le pod bloqué pour qu'il soit recréé avec la nouvelle image.
kubectl delete pod mongodb-0 -n free5gc

echo
echo "Correction appliquée. Suis le démarrage avec :"
echo "  kubectl get pods -n free5gc -w"
