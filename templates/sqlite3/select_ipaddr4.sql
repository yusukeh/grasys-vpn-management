SELECT ipaddr
FROM clients 
INNER JOIN wireguard_ipv4
ON clients.id = wireguard_ipv4.id
WHERE clients.email = '{{email}}'
