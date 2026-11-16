#!/usr/bin/env bash
# Séparation des machines : à lancer sur la VM core5g.
#
# Pourquoi : le gNB (antenne) va tourner sur une autre VM. Il doit pouvoir joindre
#   - l'AMF par N2 (NGAP/SCTP)  -> adresse 10.100.50.249
#   - l'UPF par N3 (GTP-U)      -> adresse 10.100.50.233
# Ces deux adresses sont des interfaces macvlan créées par Multus. On les branche
# désormais sur la carte 2 (enp0s8), reliée au réseau interne VirtualBox "reseau5g",
# au lieu de enp0s3 (NAT). N4, N6 et N9 restent sur enp0s3.
# Les adresses IP ne changent pas : la configuration du SMF reste valable.
set -e

echo "1) Carte enp0s8 toujours activée au démarrage (sans adresse IP propre)..."
sudo tee /etc/netplan/60-reseau5g.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      optional: true
EOF
sudo chmod 600 /etc/netplan/60-reseau5g.yaml
sudo netplan apply
ip -br link show enp0s8

echo
echo "2) N2 et N3 de Free5GC déplacées sur enp0s8..."
helm upgrade free5gc-v1 towards5gs/free5gc \
  --namespace free5gc \
  --reuse-values \
  --set global.n2network.masterIf=enp0s8 \
  --set global.n3network.masterIf=enp0s8

echo
echo "3) Réservations CPU remises à 50m (helm upgrade remet les valeurs d'origine)..."
kubectl set resources deployment --all -n free5gc --requests=cpu=50m
kubectl set resources statefulset --all -n free5gc --requests=cpu=50m

echo
echo "4) Arrêt puis relance des fonctions 5G (évite le blocage ancien/nouveau pod)..."
kubectl scale deployment --all -n free5gc --replicas=0
sleep 20
kubectl scale deployment --all -n free5gc --replicas=1

echo
echo "5) Vérification : les réseaux n2 et n3 doivent utiliser enp0s8"
kubectl get network-attachment-definitions -n free5gc -o yaml | grep -E "name: n[2-6]network|master"

echo
echo "Terminé. Suis le redémarrage avec :"
echo "  kubectl get pods -n free5gc -w"
