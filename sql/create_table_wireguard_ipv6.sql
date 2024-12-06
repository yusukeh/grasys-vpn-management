DROP TABLE IF EXISTS wireguard_ipv6;

CREATE TABLE wireguard_ipv6(
  id INTEGER PRIMARY KEY,
  email TEXT,
  ipaddr TEXT UNIQUE,
  created_at TEXT
);
