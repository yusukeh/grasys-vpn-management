SELECT ipaddr
FROM clients 
INNER JOIN wireguard_ipv6
ON clients.id = wireguard_ipv6.id
WHERE clients.email = '{{email}}'
