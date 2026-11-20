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
| `11-preparer-ueransim.sh gnb` / `ue` | Prépare les VM gNB et UE : UERANSIM, nom de machine, adresses sur reseau5g et adresse SSH fixe |

## Architecture : 3 machines virtuelles

| VM | Rôle | Réglages VirtualBox | SSH depuis Windows |
| --- | --- | --- | --- |
| `core5g` (Free5GCore) | Kubernetes + Free5GC | 8 Go, 1 vCPU, KVM, VBoxSVGA | `ssh user@192.168.56.10` |
| `ueransim-gnb` | Antenne 5G (nr-gnb) | 1536 Mo, 1 vCPU, KVM, VBoxSVGA | `ssh user@192.168.56.20` |
| `ueransim-ue` | Téléphone (nr-ue) | 1536 Mo, 1 vCPU, KVM, VBoxSVGA | `ssh user@192.168.56.30` |

Cartes réseau de chaque VM :

- Carte 1 (`enp0s3`) : NAT, accès Internet (et N6 pour l'UPF).
- Carte 2 (`enp0s8`) : réseau interne `reseau5g`, promiscuité « Allow All » (N2, N3, radio simulée).
- Carte 3 (`enp0s9`) : réseau privé hôte, pour SSH depuis Windows (VPN déconnecté).

Plan d'adressage sur `reseau5g` :

| Élément | Adresse | Interface 5G |
| --- | --- | --- |
| AMF (core5g) | 10.100.50.249 | N2 |
| UPF (core5g) | 10.100.50.233 | N3 |
| gNB | 10.100.50.250 (N2), 10.100.50.234 (N3), 192.168.100.20 (radio) | |
| UE | 192.168.100.30 (radio) | |

## Démarrer le réseau 5G

1. Démarrer `core5g`, attendre que les 12 pods soient `Running` : `kubectl get pods -n free5gc`
2. Sur le gNB : `cd ~/UERANSIM && ./build/nr-gnb -c config/gnb-reseau5g.yaml`
3. Sur l'UE : `cd ~/UERANSIM && sudo ./build/nr-ue -c config/ue-reseau5g.yaml`
4. Test sur l'UE : `ping -I uesimtun0 -c 4 8.8.8.8`

## Utilisation dans une VM

Première fois :

```bash
git clone https://github.com/belprenam/free5gc-setup
```

Ensuite, pour récupérer les nouveaux fichiers :

```bash
cd ~/free5gc-setup && git pull
```
