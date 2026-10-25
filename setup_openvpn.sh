#!/bin/bash
set -e

# ============================================================
# Скрипт настройки OpenVPN RAS на AlmaLinux 9 (задача 2)
# Вся работа ведется в /home/vagrant
# Запускать от root (sudo) после поднятия ВМ
# ============================================================

echo ">>> [1/7] Установка пакетов..."
# epel-release уже должен быть установлен из Vagrantfile
dnf install -y openvpn easy-rsa iptables-legacy iptables-legacy-libs

echo ">>> [2/7] Подготовка PKI (easy-rsa) в /home/vagrant..."
CA_DIR="/home/vagrant/openvpn-ca"
mkdir -p "$CA_DIR"
cp -r /usr/share/easy-rsa/3/* "$CA_DIR/"
cd "$CA_DIR"
./easyrsa init-pki

echo ">>> [3/7] Создание CA и серверных сертификатов..."
./easyrsa --batch build-ca nopass
./easyrsa --batch gen-req server nopass
./easyrsa --batch sign-req server server
./easyrsa gen-dh
openvpn --genkey --secret ta.key

echo ">>> [4/7] Генерация клиентского сертификата (client1)..."
./easyrsa --batch gen-req client1 nopass
./easyrsa --batch sign-req client client1

echo ">>> [5/7] Копирование файлов и создание server.conf..."
mkdir -p /etc/openvpn/server
cp pki/ca.crt /etc/openvpn/server/
cp pki/issued/server.crt /etc/openvpn/server/
cp pki/private/server.key /etc/openvpn/server/
cp pki/dh.pem /etc/openvpn/server/
cp ta.key /etc/openvpn/server/

# Создаём server.conf
cat > /etc/openvpn/server/server.conf << 'EOF'
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

echo ">>> [6/7] Настройка IP-форвардинга и NAT (iptables)..."
# Включаем форвардинг
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-openvpn.conf
sysctl -p /etc/sysctl.d/99-openvpn.conf

# Определяем интерфейс, смотрящий в интернет (шлюз по умолчанию)
OUT_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "Интерфейс для NAT: $OUT_IFACE"

# Очищаем старые правила (на случай повторного запуска)
iptables -t nat -F POSTROUTING 2>/dev/null || true
iptables -F FORWARD 2>/dev/null || true

# Добавляем правила
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$OUT_IFACE" -j MASQUERADE
iptables -A FORWARD -i tun0 -o "$OUT_IFACE" -j ACCEPT
iptables -A FORWARD -i "$OUT_IFACE" -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Сохраняем правила
iptables-save > /etc/sysconfig/iptables

echo ">>> [7/7] Запуск OpenVPN и сборка client1.ovpn в /home/vagrant..."
systemctl enable --now openvpn-server@server

# Собираем unified .ovpn файл
cd "$CA_DIR"
OVPN_FILE="/home/vagrant/client1.ovpn"

cat > "$OVPN_FILE" << 'EOF'
client
dev tun
proto udp
remote 192.168.50.10 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
key-direction 1
EOF

echo '<ca>' >> "$OVPN_FILE"
cat pki/ca.crt >> "$OVPN_FILE"
echo '</ca>' >> "$OVPN_FILE"

echo '<cert>' >> "$OVPN_FILE"
cat pki/issued/client1.crt >> "$OVPN_FILE"
echo '</cert>' >> "$OVPN_FILE"

echo '<key>' >> "$OVPN_FILE"
cat pki/private/client1.key >> "$OVPN_FILE"
echo '</key>' >> "$OVPN_FILE"

echo '<tls-auth>' >> "$OVPN_FILE"
cat ta.key >> "$OVPN_FILE"
echo '</tls-auth>' >> "$OVPN_FILE"

# Меняем владельца файла на vagrant, чтобы было удобно читать без sudo
chown vagrant:vagrant "$OVPN_FILE"

echo "============================================================"
echo "Готово! Файл client1.ovpn создан по пути: $OVPN_FILE"
echo "Чтобы забрать его, выполни команду (без sudo):"
echo "cat /home/vagrant/client1.ovpn"
echo "Затем скопируй вывод и вставь в файл client1.ovpn на хосте."
echo "============================================================"
