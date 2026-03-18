# XiVO Install Wrapper for Debian 12

<p align="center">
  <img alt="Bash" src="https://img.shields.io/badge/Bash-Script-121011?logo=gnubash">
  <img alt="Debian 12" src="https://img.shields.io/badge/Debian-12-A81D33?logo=debian">
  <img alt="XiVO" src="https://img.shields.io/badge/XiVO-2025.10--latest-0A7B83">
  <img alt="Architecture" src="https://img.shields.io/badge/Architecture-amd64-blue">
  <img alt="Status" src="https://img.shields.io/badge/Status-Ready-success">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-lightgrey">
</p>

Script Bash d’installation automatisée de **XiVO PBX** sur **Debian 12**, avec :
- contrôles préalables système,
- installation des prérequis,
- téléchargement de l’installeur officiel XiVO,
- exécution automatisée,
- journalisation complète.

---

## Sommaire

- [Aperçu](#aperçu)
- [Fonctionnalités](#fonctionnalités)
- [Pré requis](#pré-requis)
- [Fichiers du projet](#fichiers-du-projet)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Variables d’environnement](#variables-denvironnement)
- [Déroulement du script](#déroulement-du-script)
- [Exemple de sortie console](#exemple-de-sortie-console)
- [Journalisation](#journalisation)
- [Points d’attention](#points-dattention)
- [Roadmap](#roadmap)
- [Release notes](#release-notes)
- [Auteur](#auteur)
- [Licence](#licence)

---

## Aperçu

Ce dépôt fournit un **wrapper d’installation XiVO** pour **Debian 12 amd64**.

Le script :
- vérifie que l’environnement est compatible,
- corrige le locale si nécessaire,
- installe les dépendances de base,
- récupère le script officiel XiVO,
- lance l’installation,
- enregistre l’exécution dans un fichier log.

> Le script ne remplace pas l’installeur officiel XiVO.  
> Il sert à **fiabiliser, standardiser et documenter** le déploiement.

---

## Fonctionnalités

### Contrôles système
- vérification de l’exécution en **root**
- vérification de l’OS : **Debian 12**
- vérification de l’architecture : **amd64**
- contrôle du **hostname** en minuscules
- vérification du système de fichiers racine
- avertissement si la racine n’est pas en **ext4**

### Préparation système
- vérification et génération du locale **`en_US.UTF-8`**
- application du locale système
- installation des paquets prérequis :
  - `ca-certificates`
  - `curl`
  - `wget`
  - `gnupg`
  - `lsb-release`
  - `apt-transport-https`
  - `software-properties-common`

### Contrôles réseau
- détection de conflits potentiels avec les plages utilisées par XiVO :
  - `172.17.0.0/16`
  - `172.18.1.0/24`
- avertissement si les interfaces ne sont pas en nommage **legacy `eth#`**

### Déploiement XiVO
- téléchargement du script officiel XiVO
- exécution de l’installation avec version paramétrable
- affichage d’un résumé de post-installation

### Exploitation
- journal d’exécution centralisé :
  - `/var/log/xivo-install-wrapper.log`

---

## Pré requis

Avant d’exécuter le script, la machine cible doit être :

- sous **Debian 12**
- en **64 bits / amd64**
- connectée à Internet
- lancée avec un compte **root**
- configurée avec un **hostname en minuscules**
- idéalement installée de manière **minimale et propre**

---

## Fichiers du projet

```bash
.
└── install_xivo_latest.sh
