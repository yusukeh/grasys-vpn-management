DROP TABLE IF EXISTS clients;

CREATE TABLE clients(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE,
  private_key TEXT,
  public_key TEXT
);
