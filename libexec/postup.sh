#!/bin/sh

iptables -A FORWARD -i $1 -j ACCEPT
#iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
iptables -t nat -A POSTROUTING -o e+ -j MASQUERADE
ip6tables -A FORWARD -i $1 -j ACCEPT
#ip6tables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o e+ -j MASQUERADE
