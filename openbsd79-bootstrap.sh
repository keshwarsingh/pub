#!/bin/sh
#
# OpenBSD 7.9 bootstrap
#
# Run:
# ftp -o - https://raw.githubusercontent.com/keshwarsingh/pub/main/openbsd79-bootstrap.sh | sh
#

set -eu

ADMIN_USER="administrator"

[ "$(id -u)" -eq 0 ] || {
  echo "Run as root"
  exit 1
}

if [ "$(uname -s)" != "OpenBSD" ]; then
  echo "This script is intended for OpenBSD only."
  exit 1
fi

OPENBSD_VERSION="$(uname -r)"

case "$OPENBSD_VERSION" in
  7.9)
    ;;
  *)
    echo "This script is intended for OpenBSD 7.9 only."
    echo "Detected: OpenBSD ${OPENBSD_VERSION}"
    exit 1
    ;;
esac

if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  echo "User ${ADMIN_USER} does not exist."
  exit 1
fi

echo "Installing packages..."
pkg_add nano wget

echo "Ensuring ${ADMIN_USER} is in wheel..."
usermod -G wheel "$ADMIN_USER"

echo "Installing SSH public key for ${ADMIN_USER}..."
ADMIN_HOME="$(userinfo "$ADMIN_USER" | awk -F': ' '/^dir/ { print $2 }')"

mkdir -p "$ADMIN_HOME/.ssh"
chmod 700 "$ADMIN_HOME/.ssh"

cat > "$ADMIN_HOME/.ssh/authorized_keys" <<'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxVnN0JXVedUR/7lNp712Qlof7etMtKOrJKuTw72wf5DOWX7IQRiGdUoWeD0PMnViPpMOTNiMphCpi21Y/cEP5i7wt0gX/fZtq4nxb07VV0TfZwFYKSoW5aqNHGHqqIUCVGOaxJdDANXMiDAkHxx8QSbhXiCi8U7CM+kOzFvZM/MD7BVirW6fRmCcD88RqkQGwCeURwL0yIBXrbn3XXX3n8I/1VbXaRBwGCXrezu0dL/vEyB87Nud2/49T8C22+Ftvisp7XCqjlMzc5uvv1s1ZCMg2RotBExx61IqsZKsBCiDe6CZZQhvLoUxwVZywOjaeWRKYda2ixUuhh4llhzL/
EOF

chmod 600 "$ADMIN_HOME/.ssh/authorized_keys"
chown -R "$ADMIN_USER:$ADMIN_USER" "$ADMIN_HOME/.ssh"

echo "Configuring doas..."
cat > /etc/doas.conf <<'EOF'
permit nopass :wheel
EOF

chmod 600 /etc/doas.conf

echo "Ensuring SSH is enabled..."
rcctl enable sshd

if rcctl check sshd >/dev/null 2>&1; then
  rcctl restart sshd
else
  rcctl start sshd
fi

echo
echo "Bootstrap complete."
echo
echo "Connect with:"
echo "  ssh ${ADMIN_USER}@<server-ip>"
echo
echo "Become root:"
echo "  doas -s"
