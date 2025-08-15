#!/bin/sh

"$HELPERS_PATH"/chroot_exec.sh apk add iw wireless-tools wpa_supplicant wpa_supplicant-openrc nftables eudev udev-init-scripts networkmanager networkmanager-cli linux-firmware-brcm networkmanager-wifi

mkdir -p "$ROOTFS_PATH"/etc/wpa_supplicant
cat > "$ROOTFS_PATH"/etc/wpa_supplicant/wpa_supplicant.conf << EOF
ctrl_interface=/run/wpa_supplicant
update_config=1
country=CA
EOF

# sed -i '\|default_conf=/etc/wpa_supplicant/wpa_supplicant.conf|a \
#   ifup wlan0' "$ROOTFS_PATH"/etc/init.d/wpa_supplicant

cat > "$ROOTFS_PATH"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address 192.168.1.121
netmask 255.255.255.0
gateway 192.168.1.1

auto wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

echo "net.ipv4.ip_forward=1" >> "$ROOTFS_PATH"/etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> "$ROOTFS_PATH"/etc/sysctl.conf

echo "172.16.42.2 nocturne" >> "$ROOTFS_PATH"/etc/hosts

rm -f "$ROOTFS_PATH"/etc/nftables.nft
cp "$RES_PATH"/config/nftables.nft "$ROOTFS_PATH"/etc/nftables.nft

echo "SUBSYSTEM==\"net\", ATTRS{idVendor}==\"0000\", ATTRS{idProduct}==\"1014\", NAME=\"usb0\"" > "$ROOTFS_PATH"/usr/lib/udev/rules.d/carthing.rules

cat > "$ROOTFS_PATH"/etc/NetworkManager/NetworkManager.conf << EOF
[main]
dhcp=internal
rc-manager=file
EOF

cat > "$ROOTFS_PATH"/etc/NetworkManager/system-connections/usb0.nmconnection << EOF
[connection]
id=usb0
type=ethernet
interface-name=usb0
autoconnect=true

[ipv4]
method=manual
address1=172.16.42.1/24
dns=1.1.1.1;8.8.8.8;
EOF
chmod 600 "$ROOTFS_PATH"/etc/NetworkManager/system-connections/usb0.nmconnection

wpa_passphrase "$SSID" "$PASSWORD" >> /etc/wpa_supplicant/wpa_supplicant.conf

# Add RTL8192CU specific configuration
# Blacklist rtl8xxxu driver that might conflict
echo "blacklist rtl8xxxu" >> "$ROOTFS_PATH"/etc/modprobe.d/blacklist.conf

# Create modprobe config for rtl8192cu
cat > "$ROOTFS_PATH"/etc/modprobe.d/rtl8192cu.conf << EOF
# RTL8192CU configuration
options rtl8192cu ips=0 fwlps=0 debug=0
EOF

echo "ENV{DEVTYPE}==\"gadget\", ENV{NM_UNMANAGED}=\"0\"" > "$ROOTFS_PATH"/usr/lib/udev/rules.d/98-network.rules

DEFAULT_SERVICES="${DEFAULT_SERVICES} wpa_supplicant wpa_cli nftables udev-postmount networkmanager"
SYSINIT_SERVICES="${SYSINIT_SERVICES} udev udev-trigger"
