# :cloud: :cloud: :cloud: 

This repository contains the configuration for my private cloud... :smile:

It is a bunch of machines running a completely containerized environment. It is
hosting a media center, NAS services and in the future the software backbone
for a smart home automation system.

## Hardware 

Currently running:

  * 3 HP Microserver N40L with 34GB RAM, Dual GBit Nics
  * 3 rPi Model A
  * Ubiquity EdgeRouter 

## Software

CoreOS for all x64 CPUs, and Hypriot for ARM. Kubernetes as container platform.
Storage is provided by a Ceph cluster. 

## Media Center Services

  * Plex
  * Sonarr
  * Sabnzb
  * Deluge

## Cluster Services

  * Prometheus
  * Grafana

