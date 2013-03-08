CREATE TABLE stats (id serial primary key, created_at timestamptz default (now()), data json);
CREATE INDEX stats_created_at_idx ON stats(created_at);
