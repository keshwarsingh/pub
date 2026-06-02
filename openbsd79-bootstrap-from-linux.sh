#!/bin/bash
#
# OpenBSD 7.9 installer bootstrap from Linux
#
# Run:
# wget -O - https://raw.githubusercontent.com/keshwarsingh/pub/main/openbsd79-bootstrap-from-linux.sh | bash
#

set -euo pipefail

OPENBSD_VERSION="7.9"
OPENBSD_ARCH="amd64"

BSD_RD="/boot/bsd.rd"
GRUB_OPENBSD="/etc/grub.d/99_openbsd"
GRUB_TIMEOUT_OVERRIDE="/etc/default/grub.d/99-openbsd-timeout.cfg"

OPENBSD_URL="https://ftp.openbsd.org/pub/OpenBSD/${OPENBSD_VERSION}/${OPENBSD_ARCH}/bsd.rd"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

if [ ! -f /boot/grub/x86_64-efi/bsd.mod ]; then
    echo "GRUB BSD support not found."
    exit 1
fi

echo "Downloading OpenBSD ${OPENBSD_VERSION} installer..."
wget -O "${BSD_RD}" "${OPENBSD_URL}"

if [ ! -s "${BSD_RD}" ]; then
    echo "Download failed."
    exit 1
fi

echo "Creating GRUB timeout override..."
mkdir -p /etc/default/grub.d

cat > "${GRUB_TIMEOUT_OVERRIDE}" <<'EOF'
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
GRUB_RECORDFAIL_TIMEOUT=10
EOF

echo "Creating OpenBSD GRUB menu entry..."

cat > "${GRUB_OPENBSD}" <<'EOF'
#!/bin/sh
cat <<'GRUB_EOF'

menuentry "OpenBSD 7.9 Installer" {
    kopenbsd /boot/bsd.rd
}

GRUB_EOF
EOF

chmod +x "${GRUB_OPENBSD}"

echo "Updating GRUB..."
update-grub

echo
echo "Verifying GRUB entry..."
grep -n "OpenBSD 7.9 Installer" /boot/grub/grub.cfg || {
    echo "OpenBSD menu entry not found."
    exit 1
}

echo
echo "Verifying GRUB timeout..."
grep -E 'timeout_style|set timeout' /boot/grub/grub.cfg

echo
echo "Done."
echo
echo "Reboot the server and select:"
echo
echo "  OpenBSD 7.9 Installer"
echo
echo "from the GRUB menu."
