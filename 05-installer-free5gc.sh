#!/usr/bin/env bash
# Phase 5.4 : installer Free5GC (charts towards5gs-helm) dans le namespace free5gc.
# Les fonctions avec interfaces 5G (AMF, SMF, UPF) créent leurs interfaces macvlan
# sur la carte enp0s3 (masterIf). N6 sort par le réseau NAT de VirtualBox (10.0.2.0/24).
# MongoDB : image prise dans bitnamilegacy (les anciennes images Bitnami ont été retirées).
set -e

helm -n free5gc install free5gc-v1 towards5gs/free5gc \
  --set global.n2network.masterIf=enp0s3 \
  --set global.n3network.masterIf=enp0s3 \
  --set global.n4network.masterIf=enp0s3 \
  --set global.n6network.masterIf=enp0s3 \
  --set global.n9network.masterIf=enp0s3 \
  --set global.n6network.subnetIP=10.0.2.0 \
  --set global.n6network.cidr=24 \
  --set global.n6network.gatewayIP=10.0.2.2 \
  --set free5gc-upf.upf.n6if.ipAddress=10.0.2.20 \
  --set mongodb.image.repository=bitnamilegacy/mongodb

echo
echo "Free5GC est en cours de déploiement. Suis le démarrage avec :"
echo "  kubectl get pods -n free5gc -w"
