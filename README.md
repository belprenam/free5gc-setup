# free5gc-setup

Commandes et fichiers d'installation de Free5GC sous Kubernetes (charts towards5gs-helm)
sur Ubuntu 22.04, pour le projet SMART-ICT S5.

| Fichier | Rôle |
| --- | --- |
| `05-installer-free5gc.sh` | Phase 5.4 : installe Free5GC avec les bonnes interfaces réseau et l'image MongoDB `bitnamilegacy` |
| `06-corriger-mongodb.sh` | Corrige une installation existante bloquée sur `mongodb-0` en `ErrImagePull` |
| `07-trouver-image-mongodb.sh` | Cherche une version MongoDB qui existe vraiment dans `bitnamilegacy` et l'applique à Free5GC |
| `08-reduire-cpu.sh` | Baisse les réservations CPU des fonctions 5G (SMF/UPF en Pending avec « Insufficient cpu » sur 2 CPU) |
| `09-installer-ueransim.sh` | Phase 6 : installe UERANSIM (gNB + UE simulés) avec des réservations CPU réduites |
| `10-separer-n2-n3.sh` | Séparation des machines : branche N2 (AMF) et N3 (UPF) sur enp0s8 (réseau interne reseau5g) |

## Utilisation dans la VM

Première fois :

```bash
git clone https://github.com/belprenam/free5gc-setup
```

Ensuite, pour récupérer les nouveaux fichiers :

```bash
cd ~/free5gc-setup && git pull
```
