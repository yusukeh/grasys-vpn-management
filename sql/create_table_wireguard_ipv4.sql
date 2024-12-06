DROP TABLE IF EXISTS wireguard_ipv4;

CREATE TABLE wireguard_ipv4(
  id INTEGER PRIMARY KEY,
  email TEXT,
  ipaddr TEXT UNIQUE,
  created_at TEXT
);
