#!/bin/sh
#
# FreeBSD 14 Utimaco P11CAT / PKCS#11 R2 helper
#
# Prepares a FreeBSD 14 host for Utimaco PKCS#11 / P11CAT administration.
#
# Requires proprietary Utimaco client components (e.g. p11cat.jar).
#
# Run:
#   fetch -qo - https://raw.githubusercontent.com/keshwarsingh/pub/main/freebsd14-utimaco-p11cat.sh | sh
#

set -eu

BASE="/usr/local/etc/utimaco"
CFG="${BASE}/cs_pkcs11_R2.cfg"
PROFILE="/root/.profile"

echo "==> FreeBSD 14 Utimaco P11CAT / PKCS#11 R2 helper"
echo

echo "==> Installing Java runtime..."
pkg install -y openjdk17

echo "==> Creating Utimaco configuration directory..."
mkdir -p "${BASE}"
chmod 700 "${BASE}"

echo
printf "Enter CryptoServer LAN IP address: "
read -r HSM_IP

if [ -z "${HSM_IP}" ]; then
    echo "No CryptoServer IP provided. Aborting."
    exit 1
fi

echo
printf "Enter slot count [10]: "
read -r SLOTCOUNT
SLOTCOUNT="${SLOTCOUNT:-10}"

echo
echo "==> Writing ${CFG}..."

cat > "${CFG}" <<EOF
# Utimaco CryptoServer PKCS#11 R2 configuration
# Adapted for FreeBSD 14

[CryptoServer]
Device = ${HSM_IP}

# Maximum number of PKCS#11 slots
SlotCount = ${SLOTCOUNT}

# Store keys internally by default
KeyExternal = false

# Example external keystore:
# KeyExternal = true
# KeyStore = /var/db/utimaco/P11.pks
EOF

chmod 600 "${CFG}"

echo "==> Persisting environment variable..."

if ! grep -q "CS_PKCS11_R2_CFG=" "${PROFILE}" 2>/dev/null; then
    {
        echo
        echo "# Utimaco PKCS#11 configuration"
        echo "export CS_PKCS11_R2_CFG=${CFG}"
    } >> "${PROFILE}"
else
    echo "CS_PKCS11_R2_CFG already exists in ${PROFILE}; leaving unchanged."
fi

echo
echo "========================================"
echo "SETUP COMPLETE"
echo "========================================"
echo
echo "Configuration file:"
echo "  ${CFG}"
echo
echo "For current shell:"
echo "  export CS_PKCS11_R2_CFG=${CFG}"
echo
echo "Next steps:"
echo
echo "1. Copy your Utimaco P11CAT JAR:"
echo "     /root/p11cat.jar"
echo
echo "2. Start P11CAT:"
echo "     export CS_PKCS11_R2_CFG=${CFG}"
echo "     java -jar /root/p11cat.jar"
echo
echo "3. In P11CAT:"
echo "     - Login Generic as ADMIN"
echo "     - Init Token (set SO PIN)"
echo "     - Login SO"
echo "     - Init PIN (set User PIN)"
echo
echo "Done."
