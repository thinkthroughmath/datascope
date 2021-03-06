# Datascope
Visability into your Postgres 9.2 database via [pg_stat_statements](http://www.postgresql.org/docs/9.2/static/pgstatstatements.html) and [cubism](http://square.github.com/cubism/) and using the [json datatype](http://wiki.postgresql.org/wiki/What's_new_in_PostgreSQL_9.2#JSON_datatype).

![http://f.cl.ly/items/440Z1L1n2v3q3c1Q3J0s/datascope.png](http://f.cl.ly/items/440Z1L1n2v3q3c1Q3J0s/datascope.png)

Check out a [live example](https://datascope.herokuapp.com)

## Setup - all local

This section is about running datascope locally and monitoring a local database.

* run `bundle`
* create a local postgres db and name it, e.g., 'datascope'
* run `psql -d datascope -f schema.sql`
* If you want to monitor a local database named 'mystuff', create an .env file that contains:

    RACK_ENV=development
    DATABASE_URL=postgres://localhost/datascope
    TARGET_DB=postgres://localhost/mystuff

* Then run: `foreman start`
* Then you should be able to go to http://localhost:5000 and see stats.

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

## Setup - local datascope, remote target db

If you have a heroku app whose databases you would like to monitor, you can grab the config values by using the [heroku-config plugin](https://github.com/ddollar/heroku-config). Install that, and then run `heroku config:pull -a your-app-name`.

This will put all your config vars into .env. There are ways to have heroku config either overwrite this file or not; look at the readme.

UNDER NO CIRCUMSTANCES SHOULD YOU COMMIT THE .env FILE ANYWHERE!!!

Now go edit .env. Make sure you keep these variables (or add them if you never had them):

    RACK_ENV=development
    DATABASE_URL=postgres://localhost/datascope

Delete anything you don't care about. Keep the database urls but change their var names to be TARGET_(\d)_([A-Z]) where (\d) is the order in which you'd like to see the databases displayed, and ([A-Z]) is the name you'd like displayed for this database.

For example, here is what you should have if you want to see the connections for MASTER then ENROLLMENTS:

    RACK_ENV=development
    DATABASE_URL=postgres://localhost/datascope
    TARGET_0_MASTER=postgres://...
    TARGET_1_ENROLLMENTS=postgres://...

## Setup - remote datascope, remote target db

* Create a heroku app and add a postgres database to it, making sure you request postgres 9.2 since this app uses the json datatype:

    heroku addons:add heroku-postgresql:[dev, crane, whatever] --version=9.2

* Set the postgres database as your DATABASE_URL heroku config var.
* When the database is available, run `psql -f schema.sql` on it.
* For each target database in your .env file, set a corresponding config var on heroku. Reminder: no committing your .env file anywhere!!!!!
* Deploy this code to the heroku app.
* Scale the worker process:

    heroku ps:scale worker=1