# Datascope
Visability into your Postgres 9.2 database via [pg_stat_statements](http://www.postgresql.org/docs/9.2/static/pgstatstatements.html) and [cubism](http://square.github.com/cubism/) and using the [json datatype](http://wiki.postgresql.org/wiki/What's_new_in_PostgreSQL_9.2#JSON_datatype).

![http://f.cl.ly/items/440Z1L1n2v3q3c1Q3J0s/datascope.png](http://f.cl.ly/items/440Z1L1n2v3q3c1Q3J0s/datascope.png)

Check out a [live example](https://datascope.herokuapp.com)

## Setup - local

* run `bundle`
* create a local postgres db and name it, e.g., 'datascope'
* run `psql -d datascope -f schema.sql`
* If you want to monitor a local database named 'mystuff', in one terminal run:
`DATABASE_URL=postgres://localhost/datascope TARGET_DB=postgres://localhost/mystuff bundle exec ruby worker.rb`
and in another terminal run:
 `DATABASE_URL=postgres://localhost/datascope TARGET_DB=postgres://localhost/mystuff rackup`

* Then you should be able to go to http://localhost:9292 and see stats.

If you don't see any stats and your rackup logs contain:

    NoMethodError - undefined method `[]' for nil:NilClass: datascope/app.rb:45

that means you need to enable pg_stat_statements in two places.

Assuming that you use postgres installed via homebrew, edit your conf file at /usr/local/var/postgres/postgresql.conf to have:

    shared_preload_libraries = 'pg_stat_statements'


Then restart postgres by running these commands ([source](http://soff.es/running-rails-local-development-with-nginx-postgres-and-passenger-with-homebrew)):

    pg_ctl -D /usr/local/var/postgres stop -s -m fast
    pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start


I had issues with the shared memory settings -- which manifested themselves as the server not starting and lots of sad things in /usr/local/var/postgres/server.log. To fix this, I also changed to these settings in the postgresql.conf:

    shared_buffers = 300kB
    max_connections = 20

(note that this is different than what's recommended in [our setup instructions](https://github.com/thinkthroughmath/apangea/wiki/Mac-Setup), i'm not really sure of the implications).

You should have a postgres server running now, so you're ready to enable pg_stat_statements in the other place. Run `psql`, connect to each database you would like to monitor, and run `CREATE extension pg_stat_statements;` as explained in [Craig Kerstiens' post](http://www.craigkerstiens.com/2013/01/10/more-on-postgres-performance/). If this has completed correctly, you should now have a pg_stat_statements table in this database.