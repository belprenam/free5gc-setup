#!/usr/bin/env bash
# Séparation des machines : préparer une VM UERANSIM.
#
#   bash 11-preparer-ueransim.sh gnb   -> sur la VM ueransim-gnb (installe et compile UERANSIM)
#   bash 11-preparer-ueransim.sh ue    -> sur la VM ueransim-ue (clone de la VM gnb déjà compilée)
#
# SSH depuis Windows : gnb -> ssh user@192.168.56.20 ; ue -> ssh user@192.168.56.30
#
# Plan d'adressage sur le réseau interne VirtualBox "reseau5g" (carte 2, enp0s8) :
#   AMF (core5g)  10.100.50.249  N2   | gNB 10.100.50.250/29 (N2)
#   UPF (core5g)  10.100.50.233  N3   | gNB 10.100.50.234/29 (N3)
#   radio simulée                     | gNB 192.168.100.20/24, UE 192.168.100.30/24
set -e

ROLE="$1"
if [ "$ROLE" != "gnb" ] && [ "$ROLE" != "ue" ]; then
  echo "Usage : bash 11-preparer-ueransim.sh gnb   ou   bash 11-preparer-ueransim.sh ue"
  exit 1
fi

if [ "$ROLE" = "gnb" ]; then
  echo "1) Paquets nécessaires à UERANSIM (compilation + SCTP)..."
  sudo apt update
  sudo apt install -y git make gcc g++ cmake libsctp-dev lksctp-tools iproute2 \
    linux-modules-extra-$(uname -r)
  sudo modprobe sctp
  echo sctp | sudo tee /etc/modules-load.d/sctp.conf > /dev/null

  echo
  echo "2) Téléchargement et compilation de UERANSIM (15 à 25 minutes sur 1 vCPU)..."
  cd ~
  [ -d UERANSIM ] || git clone https://github.com/aligungr/UERANSIM
  cd UERANSIM
  make

  echo
  echo "3) Fichiers de configuration pour Free5GC..."
  cat > ~/UERANSIM/config/gnb-reseau5g.yaml <<'EOF'
mcc: '208'          # PLMN 208/93, comme l'abonné enregistré dans la WebUI
mnc: '93'
nci: '0x000000010'
idLength: 32
tac: 1

linkIp: 192.168.100.20   # radio simulée, vers l'UE
ngapIp: 10.100.50.250    # N2, vers l'AMF
gtpIp: 10.100.50.234     # N3, vers l'UPF

amfConfigs:
  - address: 10.100.50.249
    port: 38412

slices:
  - sst: 0x1
    sd: 0x010203

ignoreStreamIds: true
EOF
  cp ~/UERANSIM/config/free5gc-ue.yaml ~/UERANSIM/config/ue-reseau5g.yaml
  sed -i "s/^supi:.*/supi: 'imsi-208930000000003'/" ~/UERANSIM/config/ue-reseau5g.yaml
  sed -i "s/^  - 127.0.0.1/  - 192.168.100.20/" ~/UERANSIM/config/ue-reseau5g.yaml
  NOM=ueransim-gnb
  ADRESSES="[10.100.50.250/29, 10.100.50.234/29, 192.168.100.20/24]"
  SSH_IP=192.168.56.20
else
  NOM=ueransim-ue
  ADRESSES="[192.168.100.30/24]"
  SSH_IP=192.168.56.30
fi

echo
echo "4) Nom de la machine : $NOM"
ANCIEN=$(hostname)
sudo hostnamectl set-hostname "$NOM"
sudo sed -i "s/$ANCIEN/$NOM/g" /etc/hosts

echo
echo "5) Adresses de la carte enp0s8 : $ADRESSES"
sudo tee /etc/netplan/60-reseau5g.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      optional: true
      addresses: $ADRESSES
EOF
sudo chmod 600 /etc/netplan/60-reseau5g.yaml

echo
echo "   Adresse fixe pour SSH sur la carte 3 (enp0s9, réseau privé hôte) : $SSH_IP"
echo "   (le DHCP reste actif pour ne pas couper une session SSH en cours)"
sudo tee /etc/netplan/70-ssh.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    enp0s9:
      dhcp4: true
      optional: true
      addresses: [$SSH_IP/24]
EOF
sudo chmod 600 /etc/netplan/70-ssh.yaml
sudo netplan apply
sleep 3
ip -br addr show enp0s8
ip -br addr show enp0s9

if [ "$ROLE" = "gnb" ]; then
  echo
  echo "6) Test : l'AMF (10.100.50.249) et l'UPF (10.100.50.233) répondent-ils ?"
  ping -c 2 -W 2 10.100.50.249 || echo "   -> l'AMF ne répond pas au ping (à vérifier)"
  ping -c 2 -W 2 10.100.50.233 || echo "   -> l'UPF ne répond pas au ping (à vérifier)"
  echo
  echo "Pour démarrer l'antenne :"
  echo "  cd ~/UERANSIM && ./build/nr-gnb -c config/gnb-reseau5g.yaml"
else
  echo
  echo "Test : le gNB (192.168.100.20) répond-il ?"
  ping -c 2 -W 2 192.168.100.20 || echo "   -> le gNB ne répond pas (est-il allumé ?)"
  echo
  echo "Pour démarrer le téléphone :"
  echo "  cd ~/UERANSIM && sudo ./build/nr-ue -c config/ue-reseau5g.yaml"
fi
