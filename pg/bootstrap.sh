#!/bin/sh

DB_NAME="tex"
POSTGRESQL_VERSION="9.5"

#PostgreSQL
add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
wget --quiet -O - https://postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

#PgRouting
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
apt-get install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

apt-get update

# GIT
apt-get install -y git

# Postgresql (postgres:postgres)
apt-get install -y postgresql-$POSTGRESQL_VERSION postgresql-contrib-$POSTGRESQL_VERSION postgresql-client-$POSTGRESQL_VERSION
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"

# PgRouting
apt-get install -y postgresql-$POSTGRESQL_VERSION-pgrouting

# PgPythonu
apt-get install -y python-pip python-dev build-essential
pip install geopy
apt-get install postgresql-plpython-$POSTGRESQL_VERSION

# Set estonian locale
locale-gen et_EE
locale-gen et_EE.UTF-8
update-locale
dpkg-reconfigure locales
sed -i -- 's/en_US/et_EE/g' /etc/default/locale
. /etc/default/locale

# Allow access to PostgreSQL from outside (For DEV only!)
echo "host all all 0.0.0.0/0 trust" | tee -a "/etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf"
echo "listen_addresses='*'" | tee -a "/etc/postgresql/$POSTGRESQL_VERSION/main/postgresql.conf"

# Restart services
service apache2 restart
sudo -u postgres service postgresql restart

# Create database to Postgresql
sudo -u postgres createdb -E UTF8 -l et_EE.utf-8 -T template0 "$DB_NAME"

sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
sudo -u postgres psql -U postgres -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS postgis;"
sudo -u postgres psql -U postgres -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS pgrouting;"
sudo -u postgres psql -U postgres -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS plpythonu;"
sudo -u postgres psql -U postgres -d $DB_NAME -c "UPDATE pg_language SET lanpltrusted = true WHERE lanname = 'plpythonu';"

#PgGraph
cd /vagrant
git config --global --unset http.proxy
git config --global --unset https.proxy
git clone https://github.com/raitraidma/pggraph.git

sudo -u postgres psql -U postgres -d $DB_NAME -f /vagrant/pggraph/dijkstra.sql
sudo -u postgres psql -U postgres -d $DB_NAME -f /vagrant/pggraph/kruskal.sql