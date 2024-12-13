.headers ON
SELECT clients.id, clients.email, wireguard_ipv4.ipaddr, wireguard_ipv6.ipaddr
FROM clients
INNER JOIN wireguard_ipv4, wireguard_ipv6
ON clients.id = wireguard_ipv4.id
AND clients.id = wireguard_ipv6.id
