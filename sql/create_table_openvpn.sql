DROP TABLE IF EXISTS openvpn;

CREATE TABLE openvpn(
  id INTEGER PRIMARY KEY,
  email TEXT,
  ipaddr TEXT,
  created_at TEXT
);
