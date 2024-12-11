#!/bin/sh

iptables -D FORWARD -i $1 -j ACCEPT
#iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE
iptables -t nat -D POSTROUTING -o e+ -j MASQUERADE
ip6tables -D FORWARD -i $1 -j ACCEPT
#ip6tables -t nat -D POSTROUTING -o ens4 -j MASQUERADE
ip6tables -t nat -D POSTROUTING -o e+ -j MASQUERADE
