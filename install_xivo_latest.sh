#!/usr/bin/env bash
# script DevOps installation de XIVO
# Par ShadowHacker (sbeteta@beteta.org)

set -Eeuo pipefail

XIVO_ARCHIVE="${XIVO_ARCHIVE:-2025.10-latest}"
XIVO_SCRIPT_URL="${XIVO_SCRIPT_URL:-https://mirror.xivo.solutions/xivo_install.sh}"
LOG_FILE="/var/log/xivo-install-wrapper.log"

exec > >(tee -a "$LOG_FILE") 2>&1

red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[1;34m%s\033[0m\n' "$*"; }

die() {
  red "[ERREUR] $*"
  exit 1
}

warn() {
  yellow "[ATTENTION] $*"
}

info() {
  blue "[INFO] $*"
}

ok() {
  green "[OK] $*"
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Ce script doit être exécuté en root."
}

check_os() {
  [[ -r /etc/os-release ]] || die "/etc/os-release introuvable."
  . /etc/os-release

  [[ "${ID:-}" == "debian" ]] || die "OS non supporté: ${ID:-inconnu}. Attendu: Debian."
  [[ "${VERSION_ID:-}" == "12" ]] || die "Version Debian non supportée: ${VERSION_ID:-inconnue}. Attendu: Debian 12."
  ok "Debian 12 détecté."
}

check_arch() {
  local arch
  arch="$(dpkg --print-architecture)"
  [[ "$arch" == "amd64" ]] || die "Architecture non supportée: $arch. Attendu: amd64."
  ok "Architecture amd64 détectée."
}

check_hostname() {
  local hn
  hn="$(hostnamectl --static 2>/dev/null || hostname)"
  [[ "$hn" =~ [A-Z] ]] && die "Le hostname contient des majuscules: $hn. Utilise un hostname en minuscules."
  ok "Hostname valide: $hn"
}

check_fs() {
  local rootfs
  rootfs="$(findmnt -n -o FSTYPE /)"
  if [[ "$rootfs" != "ext4" ]]; then
    warn "Le système de fichiers racine est '$rootfs'. La doc XiVO recommande ext4."
  else
    ok "Système de fichiers racine ext4."
  fi
}

check_locale_and_fix() {
  local current
  current="$(localectl status 2>/dev/null | awk -F': ' '/System Locale/ {print $2}' || true)"

  if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf8$'; then
    info "Génération du locale en_US.UTF-8..."
    apt-get update
    apt-get install -y locales
    sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    locale-gen
  fi

  info "Application du locale par défaut en_US.UTF-8..."
  update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  ok "Locale configuré en en_US.UTF-8."
}

check_network_ranges() {
  local routes
  routes="$(ip -4 route show || true)"

  if echo "$routes" | grep -qE '(^| )172\.17\.0\.0/16( |$)'; then
    warn "Le réseau 172.17.0.0/16 est déjà utilisé. XiVO le préempte par défaut."
  fi

  if echo "$routes" | grep -qE '(^| )172\.18\.1\.0/24( |$)'; then
    warn "Le réseau 172.18.1.0/24 est déjà utilisé. XiVO le préempte par défaut."
  fi
}

check_interface_naming() {
  local ifs
  ifs="$(ls /sys/class/net | tr '\n' ' ')"
  if echo "$ifs" | grep -qE '\benp|\bens|\beno|\beth'; then
    if echo "$ifs" | grep -qE '\beth[0-9]+'; then
      ok "Nommage réseau compatible détecté: $ifs"
    else
      warn "Les interfaces ne semblent pas en nommage legacy eth#: $ifs"
      warn "La doc XiVO recommande net.ifnames=0 + renommage legacy eth#."
      warn "Je ne force PAS cette modification automatiquement pour éviter de casser le réseau."
    fi
  fi
}

install_prereqs() {
  info "[1] Installation des prérequis..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common
  ok "Prérequis installés."
}

download_installer() {
  info "[2] Téléchargement du script XiVO depuis ${XIVO_SCRIPT_URL} ..."
  wget -O /root/xivo_install.sh "$XIVO_SCRIPT_URL"
  chmod +x /root/xivo_install.sh
  ok "Script XiVO téléchargé dans /root/xivo_install.sh"
}

run_installer() {
  info "[3] Lancement de l’installation XiVO (${XIVO_ARCHIVE}) ... Please wait... lol :-)"
  /root/xivo_install.sh -a "${XIVO_ARCHIVE}"
  ok "Installation XiVO terminée. (OUF ! ENFIN :-)"
}

post_install_note() {
  cat <<'EOF'

============================================================
XiVO est installé.

Étapes suivantes :
------------------
1. Ouvre l’interface web XiVO.
2. Lance l’assistant de configuration.
3. Tu peux appliquer la configuration par défaut France si ton contexte est FR.
4. Vérifie ensuite les services XiVO si nécessaire.

Commandes utiles :
------------------
  systemctl --failed
  xivo-service status
  xivo-service restart

Log du wrapper :
----------------
  /var/log/xivo-install-wrapper.log
============================================================

EOF
}

main() {
  require_root
  check_os
  check_arch
  check_hostname
  check_fs
  check_locale_and_fix
  check_network_ranges
  check_interface_naming
  install_prereqs
  download_installer
  run_installer
  post_install_note
}

main "$@"
