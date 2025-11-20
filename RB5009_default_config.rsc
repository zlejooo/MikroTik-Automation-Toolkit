#**************************************************************************************************
#*                                                                                                *
#*          __       _                      _____           _       __     ____             __    *
#*   ____  / /__    (_)___  ____  ____     / ___/__________(_)___  / /_   / __ \____ ______/ /__  *
#*  /_  / / / _ \  / / __ \/ __ \/ __ \    \__ \/ ___/ ___/ / __ \/ __/  / /_/ / __ `/ ___/ //_/  *
#*   / /_/ /  __/ / / /_/ / /_/ / /_/ /   ___/ / /__/ /  / / /_/ / /_   / ____/ /_/ / /__/ ,<     *
#*  /___/_/\___/_/ /\____/\____/\____/   /____/\___/_/  /_/ .___/\__/  /_/    \__,_/\___/_/|_|    *
#*            /___/                                      /_/                                      *
#*                                                                                                *
#**************************************************************************************************
#
# Script Name   : RB5009_default_config.ps1
# Author        : zlejooo
# Created.      : 2025-11-20
# Version.      : 1.0.0
# Description   : Default custom configuration for MikroTik RB5009UG+S+IN router
# Requirements  :
# Notes         :
#**************************************************************************************************

/system/script environment

# Global Variables - Modify as needed

:global DNSservers "1.1.1.1,8.8.8.8,8.8.4.4";          #Modify DNS servers as needed
:global UserName "username";                           #Modify username as needed
:global UserPassword "userpassword";                   #Modify password as needed
:global identities "Router Identity Name";             #Modify identity name as needed
:global BridgeName "BR01";                             #Modify bridge name as needed
:global NetworkAddress "192.168.1.0/24";               #Modify LAN network as needed 
:global gatewayAddress "192.168.1.1";                  #Modify Gateway address as needed 
:global BridgeIPaddress  "192.168.1.1/24";             #Modify Bridge IP address as needed
:global DHCPpool "192.168.1.100-192.168.1.250";        #Modify DHCP pool as needed

:global VPNUser "UserName";            #Modify VPN username as needed
:global VPNPassword "UserPassword";    #Modify VPN password as needed
:global ServerIP "<ip_address>";       #Modify VPN server IP as needed
:global ServerPort "<port>";           #Modify VPN server port as needed

#**************************************************************************************************


#WAN Interface Setup
/ip dhcp-client add disabled=no interface=ether1
/ip/dns/ set servers=$DNSservers
#**************************************************************************************************


#RouterOS Update and Firmware Upgrade
/system routerboard settings set auto-upgrade=yes;
/system package update check-for-updates; /system package update install;
/system routerboard upgrade;
:execute {/system reboot};
#**************************************************************************************************


#Default User and identities setup
/user/add name=$UserName password=$UserPasswrd group=full
/user/remove admin 
/system/identity/set name=$identities
#**************************************************************************************************


#Bridge and LAN Interfaces Setup
/interface bridge add name=$BridgeName
/ip address add address=$BridgeIPaddress interface=$BridgeName

/interface bridge port add bridge=$BridgeName interface=ether2
/interface bridge port add bridge=$BridgeName interface=ether3
/interface bridge port add bridge=$BridgeName interface=ether4
/interface bridge port add bridge=$BridgeName interface=ether5
/interface bridge port add bridge=$BridgeName interface=ether6
/interface bridge port add bridge=$BridgeName interface=ether7
/interface bridge port add bridge=$BridgeName interface=ether8
#**************************************************************************************************


#DHCP Server Setup
/ip pool add name="dhcp_pool" ranges=$DHCPpool
/ip dhcp-server add address-pool="dhcp_pool" disabled=no interface=$BridgeName name="DHCP" lease-time=1d
/ip dhcp-server network add address=$NetworkAddress gateway=$gatewayAddress dns-server=$gatewayAddress ntp-server=$gatewayAddress
/ip dns set allow-remote-requests=yes
#**************************************************************************************************


#NTP Client Setup
/system ntp client set enabled=yes
/system ntp client servers add address="sk.pool.ntp.org"
/system/clock/ set time-zone-name=Europe/Bratislava
/system ntp server set enabled=yes multicast=yes
#**************************************************************************************************


#Services Setup
/ip service disable telnet,ftp,api,api-ssl
/ip service set www port=8080 #Change www port if needed
/ip service set winbox port=7878 #Change Winbox port if needed
/ip neighbor discovery-settings set discover-interface-list=none
#**************************************************************************************************


#Interface List Setup
/interface list add name=LAN
/interface list add name=WAN
/interface list member add list=LAN interface=$BridgeName
/interface list member add list=WAN interface=ether1
#**************************************************************************************************


#Default Firewall Setup
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="NAT for LAN to WAN"

/ip firewall filter
add chain=input action=accept protocol=tcp dst-port=7878,22 in-interface-list=WAN comment="#TEMP!! accept management from WAN"
add chain=input action=accept protocol=tcp dst-port=7878,22 in-interface-list=LAN comment="#accept management from LAN"

add chain=input action=accept connection-state=established,related,untracked comment="#accept established,related,untracked"
add chain=forward action=accept connection-state=established,related,untracked comment="#accept established,related, untracked"

add chain=input action=accept protocol=icmp in-interface-list=LAN limit=1/1s,5 comment="#accept ICMP"
add chain=input action=drop protocol=icmp in-interface-list=LAN comment="#drop ICMP"

add chain=forward action=accept protocol=tcp dst-port=53 in-interface-list=LAN comment="#accept DNS forward"
add chain=forward action=accept protocol=udp dst-port=53 in-interface-list=LAN comment="#accept DNS forward"
add chain=input action=accept protocol=tcp dst-port=53 in-interface-list=LAN comment="#accept DNS input"
add chain=input action=accept protocol=udp dst-port=53 in-interface-list=LAN comment="#accept DNS input"
add chain=input action=accept protocol=udp dst-port=67,68 in-interface-list=LAN comment="#accept DHCP input"

add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="#accept ALL to WAN"

add chain=input action=accept protocol=igmp in-interface-list=LAN comment="#accept IGMP"

add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface-list=WAN comment="#drop all from WAN not DSTNATed"
add chain=input action=drop in-interface-list=WAN comment="#drop all input from WAN"


#VPN Client Setup with custom default route
:global VPNUser "UserName";            #Modify VPN username as needed
:global VPNPassword "UserPassword";    #Modify VPN password as needed
:global ServerIP "<ip_address>";       #Modify VPN server IP as needed
:global ServerPort "<port>";           #Modify VPN server port as needed

/ppp profile add name=CustomProfile interface-list=LAN
/interface ovpn-client/ add name=VPNtunel connect-to=$ServerIP port=$ServerPort mode=ip user=$VPNUser password=$VPNPassword profile=CustomProfile certificate=Cert cipher=aes256-cbc

/ip/route/ add dst-address=10.10.10.0/24 gateway=VPNtunel #Set your desired default route via VPN
#**************************************************************************************************