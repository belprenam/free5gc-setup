#!/usr/bin/env bash
# Phase 5 : SMF et UPF restent en "Pending" avec "Insufficient cpu".
#
# Pourquoi : chaque pod RÉSERVE une part de CPU (le champ "requests"). La VM n'a que
# 2 CPU et les réservations atteignaient 100 %, alors que le CPU réellement utilisé
# est faible. On baisse donc la réservation de chaque fonction 5G à 50m
# (50 millièmes de CPU), largement suffisant pour une démo avec un seul UE.
#
# Attention : un futur "helm upgrade" remettra les valeurs d'origine. Il suffira
# alors de relancer ce script.
set -e

echo "1) Réservations CPU avant :"
kubectl describe node | grep -A 5 "Allocated resources" | grep cpu

echo
echo "2) Baisse des réservations CPU des fonctions 5G et de MongoDB..."
kubectl set resources deployment --all -n free5gc --requests=cpu=50m
kubectl set resources statefulset --all -n free5gc --requests=cpu=50m

echo
echo "3) Kubernetes recrée les pods un par un avec les nouvelles réservations."
echo "   Suis le démarrage avec :"
echo "   kubectl get pods -n free5gc -w"
