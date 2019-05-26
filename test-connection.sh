#!/bin/bash

check_status() {
  if [[ $? == 0 ]]; then
    echo -e "\033[0;32m$1 is ok\033[0m"
  else
    echo -e "\033[0;31m$1 is NOT ok\033[0m"
  fi
}

ping 192.168.12.1 -c1 -W5 >/dev/null
check_status "IPv4 Wireguard connection to server"
ping fdc0:9a9a:cf62:87ad::1 -c1 -W5 >/dev/null
check_status "IPv6 Wireguard connection to server"
ping 8.8.8.8 -c1 -W5 >/dev/null
check_status "IPv4 Internet connectivity"
ping 2600:: -c1 -W5 >/dev/null
check_status "IPv6 Internet connectivity"
nslookup -timeout=5 google.com. 192.168.12.1 >/dev/null
check_status "IPv4 DNS resolution using custom DNS server"
nslookup -timeout=5 google.com. fdc0:9a9a:cf62:87ad::1 >/dev/null
check_status "IPv6 DNS resolution using custom DNS server"
nslookup -timeout=5 google.com. 192.168.12.1 >/dev/null
check_status "IPv4 DNS resolution"
nslookup -timeout=5 google.com. fdc0:9a9a:cf62:87ad::1 >/dev/null
check_status "IPv6 DNS resolution"

IP_DNS=$(dig @ns1-1.akamaitech.net ANY whoami.akamai.net +short)
IP_HTTP=$(curl -s http://whatismyip.akamai.com/)

if [[ "$IP_DNS" == "$IP_HTTP" ]]; then
    echo -e "\033[0;32mYour IP is $IP_HTTP and there is no IP leak in DNS requests\033[0m"
else
    echo -e "\033[0;31mYour IP is $IP_HTTP, however DNS resquests leak another one: $IP_DNS\033[0m"
fi
