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

## Create security group
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

### Launching an EC2 instance + VPN with a script
Alternatively, you can launch an EC2 instance via the script `start-vpn.sh`.
The script has some requirements that must be fulfilled for it to work properly:
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- a [configured named profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) for your `aws-cli` enviroment
- [jq](https://stedolan.github.io/jq/) installed
- the ids of the security group and subnet created in the infra setup steps above

The script was only tested on Ubuntu.

1. Execute `./start-vpn.sh <desired AWS region> <local profile name> <the previously created subnet id> <the previously created security group id> <the secret key name> <the path to the secret key file>`
2. The script will ask for some user inputs, in the form of consenting with `yes` or sudo access to install the required packages
3. When done with spinning up the EC2 instance and with configuring the VPN, the script will hang
4. Pressing CTRL+c will trigger its tear down function, that terminates the previously launched EC2 instance and turns off WireGuard
 
## References

- https://www.stavros.io/posts/how-to-configure-wireguard/ no ipv6
- https://www.ckn.io/blog/2017/11/14/wireguard-vpn-typical-setup/ dns no ubuntu 18 no ipv6
- https://dnns.no/wireguard-vpn-on-ubuntu-18.04.html no-dns
- https://docs.aws.amazon.com/vpc/latest/userguide/get-started-ipv6.html
