#!/usr/bin/env bash
# Phase 5 : trouver automatiquement une image MongoDB qui existe vraiment dans
# docker.io/bitnamilegacy, puis l'appliquer à Free5GC.
#
# Pourquoi : les versions 4.4.4-debian-10-r0 et 4.4.13-debian-10-r52 n'existent pas
# dans bitnamilegacy. Plutôt que de deviner, on demande la liste réelle à Docker Hub.
set -e

echo "1) Recherche des versions MongoDB disponibles dans bitnamilegacy..."

TAG=$(python3 - <<'PY'
import json, urllib.request

def tags(prefix):
    url = ("https://hub.docker.com/v2/repositories/bitnamilegacy/mongodb/tags"
           "?page_size=100&name=" + prefix)
    out = []
    while url and len(out) < 1000:
        with urllib.request.urlopen(url, timeout=30) as r:
            data = json.load(r)
        out += [t["name"] for t in data.get("results", [])]
        url = data.get("next")
    return out

def key(t):
    # ex. 4.4.15-debian-10-r8 -> (4,4,15, 8)
    base, _, rest = t.partition("-")
    nums = [int(x) for x in base.split(".") if x.isdigit()]
    rev = int(rest.rsplit("-r", 1)[1]) if "-r" in rest and rest.rsplit("-r", 1)[1].isdigit() else 0
    return (nums, rev)

# On préfère MongoDB 4.4 (version prévue par le chart), puis 5.0 en secours.
for prefix in ("4.4.", "5.0."):
    found = [t for t in tags(prefix)
             if t.startswith(prefix) and "-debian-" in t and "-r" in t]
    if found:
        found.sort(key=key)
        print(found[-1])
        break
PY
)

if [ -z "$TAG" ]; then
  echo "Aucune version 4.4 ou 5.0 trouvée dans bitnamilegacy/mongodb."
  echo "Envoie une capture de cet écran à Claude."
  exit 1
fi

echo "   -> version choisie : bitnamilegacy/mongodb:$TAG"
echo
echo "2) Application à Free5GC..."
helm upgrade free5gc-v1 towards5gs/free5gc \
  --namespace free5gc \
  --reuse-values \
  --set mongodb.image.repository=bitnamilegacy/mongodb \
  --set mongodb.image.tag="$TAG"

kubectl delete pod mongodb-0 -n free5gc --ignore-not-found

echo
echo "Correction appliquée avec bitnamilegacy/mongodb:$TAG"
echo "Suis le démarrage avec :"
echo "  kubectl get pods -n free5gc -w"
