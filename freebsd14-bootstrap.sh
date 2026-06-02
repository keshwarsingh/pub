#!/bin/sh
#
# FreeBSD 14 bootstrap
#
# Run:
# fetch -qo - https://raw.githubusercontent.com/keshwarsingh/pub/main/freebsd14-bootstrap.sh | sh
#

set -eu

ADMIN_USER="administrator"

[ "$(id -u)" -eq 0 ] || {
  echo "Run as root"
  exit 1
}

FREEBSD_MAJOR="$(freebsd-version | cut -d. -f1)"

if [ "$FREEBSD_MAJOR" != "14" ]; then
  echo "This script is intended for FreeBSD 14.x only."
  echo "Detected: $(freebsd-version)"
  exit 1
fi

if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  echo "User ${ADMIN_USER} does not exist."
  exit 1
fi

echo "Bootstrapping pkg..."
pkg -N >/dev/null 2>&1 || env ASSUME_ALWAYS_YES=yes pkg bootstrap -f

echo "Installing packages..."
pkg install -y sudo ca_root_nss nano wget

echo "Ensuring ${ADMIN_USER} is in wheel..."
pw groupmod wheel -m "$ADMIN_USER"

echo "Installing SSH public key for ${ADMIN_USER}..."
ADMIN_HOME="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"

mkdir -p "$ADMIN_HOME/.ssh"
chmod 700 "$ADMIN_HOME/.ssh"

cat > "$ADMIN_HOME/.ssh/authorized_keys" <<'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxVnN0JXVedUR/7lNp712Qlof7etMtKOrJKuTw72wf5DOWX7IQRiGdUoWeD0PMnViPpMOTNiMphCpi21Y/cEP5i7wt0gX/fZtq4nxb07VV0TfZwFYKSoW5aqNHGHqqIUCVGOaxJdDANXMiDAkHxx8QSbhXiCi8U7CM+kOzFvZM/MD7BVirW6fRmCcD88RqkQGwCeURwL0yIBXrbn3XXX3n8I/1VbXaRBwGCXrezu0dL/vEyB87Nud2/49T8C22+Ftvisp7XCqjlMzc5uvv1s1ZCMg2RotBExx61IqsZKsBCiDe6CZZQhvLoUxwVZywOjaeWRKYda2ixUuhh4llhzL/
EOF

chmod 600 "$ADMIN_HOME/.ssh/authorized_keys"
chown -R "$ADMIN_USER:$ADMIN_USER" "$ADMIN_HOME/.ssh"

echo "Configuring passwordless sudo..."
mkdir -p /usr/local/etc/sudoers.d

cat > /usr/local/etc/sudoers.d/wheel <<'EOF'
%wheel ALL=(ALL:ALL) NOPASSWD: ALL
EOF

chmod 440 /usr/local/etc/sudoers.d/wheel
/usr/local/sbin/visudo -cf /usr/local/etc/sudoers.d/wheel

echo "Ensuring SSH is enabled..."
sysrc sshd_enable=YES

if service sshd status >/dev/null 2>&1; then
  service sshd reload || service sshd restart
else
  service sshd start
fi

echo
echo "Bootstrap complete."
echo
echo "Connect with:"
echo "  ssh ${ADMIN_USER}@<server-ip>"
echo
echo "Become root:"
echo "  sudo -i"
