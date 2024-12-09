DROP TABLE IF EXISTS wireguard_ipv6;

CREATE TABLE wireguard_ipv6(
  id INTEGER PRIMARY KEY,
  email TEXT,
  ipaddr TEXT UNIQUE,
  delete_flag INTEGER,
  created_at TEXT
);
