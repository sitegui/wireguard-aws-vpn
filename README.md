# Wireguard AWS VPN

Run your own VPN in AWS, with IPv6 support and all!

Once I had a hard time setting up a VPN. OpenVPN is too complicated for me, so
I'll use Wireguard. I do not understand much, but after reading a ton of tutorials
over the net and almost going crazy, I think I've found the exact incantation
that shall be used to have an actually working VPN, with IPv6 support. Really,
that is much harder than it should be in my opinion. Why can't things have IPv6
by default nowadays?

## Create VPC with IPv6 enabled

1. https://sa-east-1.console.aws.amazon.com/vpc/home
2. Launch VPC Wizard
3. VPC with a Single Public Subnet
4. IPv6 CIDR block: Amazon provided IPv6 CIDR block
5. VPC name: my-vpn
6. Public subnet's IPv6 CIDR: Specify a custom IPv6 CIDR
7. Create VPC

1. https://sa-east-1.console.aws.amazon.com/ec2/v2/home
2. Security Groups
3. Create Security Group
4. Security group name: my-vpn
5. Description: my-vpn
6. VPC: my-vpn
7. Add Rule
    1. Type: SSH
    2. Source: Anywhere
8. Add Rule
    1. Type: Custom UDP Rule
    2. Port Range: 51820
    3. Source: Anywhere

## Launch an instance

1. https://sa-east-1.console.aws.amazon.com/ec2/v2/home
2. Launch Instance
3. Ubuntu Server 18.04 LTS
4. Next: configure instance details
5. Network: my-vpn
6. Auto-assign Public IP: Enable
7. Auto-assign IPv6 IP: Enable
8. Next: Add Storage
9. Next: Add Tags
10. Next: Configure Security Group
11. Select an existing security group
12. my-vpn
13. Review and Launch
14. Launch

## Launch the VPN

1. Execute `./vpn.sh <the path to the secret key file> <the instance public IP>`
2. When done, run `wg-quick down wg0` and terminate the instance

## References

https://www.stavros.io/posts/how-to-configure-wireguard/ no ipv6

https://www.ckn.io/blog/2017/11/14/wireguard-vpn-typical-setup/ dns no ubuntu 18 no ipv6

https://dnns.no/wireguard-vpn-on-ubuntu-18.04.html no-dns

https://docs.aws.amazon.com/vpc/latest/userguide/get-started-ipv6.html