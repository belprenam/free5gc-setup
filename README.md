# free5gc-setup

Commandes et fichiers d'installation de Free5GC sous Kubernetes (charts towards5gs-helm)
sur Ubuntu 22.04, pour le projet SMART-ICT S5.

| Fichier | Rôle |
| --- | --- |
| `05-installer-free5gc.sh` | Phase 5.4 : installe Free5GC avec les bonnes interfaces réseau et l'image MongoDB `bitnamilegacy` |
| `06-corriger-mongodb.sh` | Corrige une installation existante bloquée sur `mongodb-0` en `ErrImagePull` |

## Utilisation dans la VM

Première fois :

```bash
git clone https://github.com/belprenam/free5gc-setup
```

Ensuite, pour récupérer les nouveaux fichiers :

```bash
cd ~/free5gc-setup && git pull
```
