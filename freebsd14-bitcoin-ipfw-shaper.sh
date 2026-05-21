#!/bin/sh
#
# Bitcoin Core ipfw/dummynet traffic shaper for FreeBSD 14
#
# Installs persistent traffic shaping for Bitcoin P2P traffic:
#   - 100 Mbps upload
#   - 100 Mbps download
#
# Monitored ports:
#   - TCP 8333 (Bitcoin mainnet)
#
# Run:
#   fetch -qo - https://raw.githubusercontent.com/keshwarsingh/pub/main/freebsd14-bitcoin-ipfw-shaper.sh | sh
#

set -eu

RULES="/etc/ipfw.rules"

echo "Loading ipfw and dummynet..."
kldload ipfw 2>/dev/null || true
kldload dummynet 2>/dev/null || true

echo "Persisting kernel modules..."
sysrc -f /boot/loader.conf ipfw_load="YES"
sysrc -f /boot/loader.conf dummynet_load="YES"

echo "Writing ${RULES}..."
cat > "${RULES}" <<'EOF'
#!/bin/sh

ipfw -q flush

# 100 Mbps upload
ipfw pipe 1 config bw 100Mbit/s

# 100 Mbps download
ipfw pipe 2 config bw 100Mbit/s

# Outbound Bitcoin traffic
ipfw add 100 pipe 1 tcp from me to any 8333
ipfw add 101 pipe 1 tcp from me 8333 to any

# Inbound Bitcoin traffic
ipfw add 110 pipe 2 tcp from any to me 8333
ipfw add 111 pipe 2 tcp from any 8333 to me

# Allow all other traffic
ipfw add 65000 allow ip from any to any
EOF

chmod 700 "${RULES}"

echo "Enabling ipfw..."
sysrc firewall_enable="YES"
sysrc firewall_type="OPEN"
sysrc firewall_script="${RULES}"

echo "Applying rules..."
sh "${RULES}"

echo
echo "Bitcoin Core ipfw/dummynet shaping installed."
echo
echo "Limits:"
echo "  Upload:   100 Mbps"
echo "  Download: 100 Mbps"
echo
echo "Active rules:"
ipfw -a list

echo
echo "Active pipes:"
ipfw pipe show

echo
echo "Monitor live counters with:"
echo
echo "while true; do clear; ipfw -a list; echo; ipfw pipe show; sleep 1; done"
