#!/usr/bin/env bash
# Phase 6 : installer UERANSIM (simulateur de gNB = antenne, et d'UE = téléphone).
#
# Pourquoi : le cœur 5G (Free5GC) ne fait rien tant qu'aucun téléphone ne s'y connecte.
# UERANSIM simule une antenne 5G (gNB) reliée à l'AMF (interface N2) et à l'UPF
# (interface N3), et un téléphone (UE) avec la carte SIM imsi-208930000000003,
# celle qu'on a enregistrée dans la WebUI.
#
# Les interfaces N2 et N3 passent par enp0s3, comme pour Free5GC.
set -e

echo "1) Installation de UERANSIM..."
helm -n free5gc install ueransim-v1 towards5gs/ueransim \
  --set global.n2network.masterIf=enp0s3 \
  --set global.n3network.masterIf=enp0s3

echo
echo "2) Baisse des réservations CPU de UERANSIM (la VM n'a que 2 CPU)..."
sleep 5
for d in $(kubectl get deployment -n free5gc -o name | grep ueransim); do
  kubectl set resources -n free5gc "$d" --requests=cpu=50m
  # Arrêt puis relance, pour éviter le blocage "ancien pod / nouveau pod" vu en Phase 5.
  kubectl scale -n free5gc "$d" --replicas=0
done
sleep 10
for d in $(kubectl get deployment -n free5gc -o name | grep ueransim); do
  kubectl scale -n free5gc "$d" --replicas=1
done

echo
echo "UERANSIM est en cours de démarrage. Suis-le avec :"
echo "  kubectl get pods -n free5gc -w"
