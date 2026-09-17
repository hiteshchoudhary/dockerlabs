-- ChaiCode platform seed data.
-- Postgres runs every .sql file in /docker-entrypoint-initdb.d exactly once:
-- on first boot with an EMPTY data directory. If the chai-45-pgdata volume
-- already has data, this file is skipped — that's the whole point of volumes.

CREATE TABLE chai_menu (
  id        serial PRIMARY KEY,
  name      text    NOT NULL,
  price_inr integer NOT NULL
);

INSERT INTO chai_menu (name, price_inr) VALUES
  ('masala chai',  20),
  ('adrak chai',   25),
  ('elaichi chai', 30),
  ('cutting',      10);

-- Deploy log: the Challenge writes a marker row here and proves it outlives
-- the containers themselves.
CREATE TABLE deploy_log (
  id         serial PRIMARY KEY,
  note       text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO deploy_log (note) VALUES ('platform seeded');
