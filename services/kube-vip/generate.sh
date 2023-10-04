#! /bin/bash
export VIP=192.168.100.100
export INTERFACE=eth0
export KVVERSION=v0.6.3

function kube-vip() {
  docker run --network host --rm "ghcr.io/kube-vip/kube-vip:$KVVERSION" "$@"
}

kube-vip manifest daemonset \
  --interface $INTERFACE \
  --address $VIP \
  --inCluster \
  --taint \
  --controlplane \
  --arp \
  --leaderElection
