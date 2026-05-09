#!/bin/sh
set -eu

GITHUB_USER="keshwarsingh"
ADMIN_USER="administrator"

KEY_URL="https://github.com/${GITHUB_USER}.keys"

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

echo "Bootstrapping pkg..."
pkg -N >/dev/null 2>&1 || env ASSUME_ALWAYS_YES=yes pkg bootstrap -f

echo "Installing packages..."
pkg install -y sudo ca_root_nss nano

echo "Ensuring ${ADMIN_USER} is in wheel..."
pw groupmod wheel -m "$ADMIN_USER"

echo "Installing GitHub SSH keys for ${ADMIN_USER}..."
ADMIN_HOME="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"

mkdir -p "$ADMIN_HOME/.ssh"
chmod 700 "$ADMIN_HOME/.ssh"

fetch -qo /tmp/github.keys "$KEY_URL"

if [ ! -s /tmp/github.keys ]; then
  echo "No SSH keys found at ${KEY_URL}"
  exit 1
fi

touch "$ADMIN_HOME/.ssh/authorized_keys"
cat /tmp/github.keys >> "$ADMIN_HOME/.ssh/authorized_keys"

sort -u "$ADMIN_HOME/.ssh/authorized_keys" \
  -o "$ADMIN_HOME/.ssh/authorized_keys"

chmod 600 "$ADMIN_HOME/.ssh/authorized_keys"
chown -R "$ADMIN_USER:$ADMIN_USER" "$ADMIN_HOME/.ssh"

rm -f /tmp/github.keys

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
