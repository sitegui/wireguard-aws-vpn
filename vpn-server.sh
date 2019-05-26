#!/bin/bash -e

NET_INTERFACE=eth0
SERVER_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Install packages"
{
sudo add-apt-repository -y ppa:wireguard/wireguard
sudo apt-get update
sudo apt-get install -y wireguard unbound unbound-host
} >> logs

echo "Generate Wireguard keys and files"
{
umask 077
wg genkey | tee server.private | wg pubkey > server.public
wg genkey | tee client.private | wg pubkey > client.public


echo "[Interface]
Address = 192.168.12.1/24, fdc0:9a9a:cf62:87ad::1/64
PrivateKey = $(cat server.private)
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $NET_INTERFACE -j MASQUERADE; ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $NET_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $NET_INTERFACE -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $NET_INTERFACE -j MASQUERADE

[Peer]
PublicKey = $(cat client.public)
AllowedIPs = 192.168.12.2, fdc0:9a9a:cf62:87ad::2" > server.conf

echo "[Interface]
Address = 192.168.12.2/24, fdc0:9a9a:cf62:87ad::2/64
PrivateKey = $(cat client.private)
DNS = 192.168.12.1, fdc0:9a9a:cf62:87ad::1

[Peer]
PublicKey = $(cat server.public)
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25" > client.conf

sudo cp server.conf /etc/wireguard/wg0.conf
sudo chown root:root /etc/wireguard/wg0.conf
} >> logs

echo "Enable IP forward"
{
sudo sed -i \
    -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' \
    -e 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/' \
    /etc/sysctl.conf
sudo sysctl -p
} >> logs

echo "Start Wireguard service"
{
wg-quick up wg0
sudo systemctl enable wg-quick@wg0.service
} >> logs

echo "Configure DNS (unbound)"
{
sudo curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
echo "server:
  num-threads: 4
  verbosity: 1
  root-hints: \"/var/lib/unbound/root.hints\"
  auto-trust-anchor-file: \"/var/lib/unbound/root.key\"
  interface: 192.168.12.1
  interface: fdc0:9a9a:cf62:87ad::1
  max-udp-size: 3072
  access-control: 0.0.0.0/0 refuse
  access-control: 127.0.0.1 allow
  access-control: 192.168.12.0/24 allow
  access-control: fdc0:9a9a:cf62:87ad::/64 allow
  private-address: 192.168.12.0/24
  private-address: fdc0:9a9a:cf62:87ad::/64
  hide-identity: yes
  hide-version: yes
  harden-glue: yes
  harden-dnssec-stripped: yes
  harden-referral-path: yes
  unwanted-reply-threshold: 10000000
  val-log-level: 1
  cache-min-ttl: 1800 
  cache-max-ttl: 14400
  prefetch: yes
  prefetch-key: yes" | sudo tee /etc/unbound/unbound.conf
sudo chown -R unbound:unbound /var/lib/unbound
} >> logs

echo "Start DNS service"
{
sudo systemctl enable unbound
sudo systemctl restart unbound
} >> logs

echo "Done: server is configured"