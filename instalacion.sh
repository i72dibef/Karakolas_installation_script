#!/bin/bash
clear
echo "instalacion.sh"
echo "Requiere Debian  7 (Wheezy) o superior"
echo ""
echo "Instalación de Karakolas bajo Web2py-Nginx y MariaDB"

touch /tofpr 2> /dev/null
# Comprobando si el usuario tiene permisos
if [ "$?" != "0" ]; then
	echo "Debes ejecutar este script como root (administrador) o con sudo"
	exit 1
fi
rm /tofpr

# Obteniendo el nombre de dominio
#echo -e "Introduce un nombre de dominio para la aplicación (Ej: www.ejemplo.org, ejemplo.org): \c "
#read DOMAINS
#echo
DOMAINS="test-web2py-with-nginx.com"

echo -e "Desea desactivar el repositorio cdrom de Debian? Sí[s] | No [n]: \c"
read opc
if [ "$opc" = "s" ]; then
	cp /etc/apt/sources.list /etc/apt/sources.list_back
	sed -i '/^deb cdrom/d' /etc/apt/sources.list
fi

# Obteniendo la contraseña de Administrador para Web2py
echo -e "Introduce una contraseña para el administrador de Web2py: \c "
read -s PW

# Actualizando el software e instalando los nuevos paquetes necesarios
apt-get update
apt-get -y upgrade
apt-get -y autoremove
apt-get -y autoclean

echo "Instalando Nginx+uWSGI y otros paquetes necesarios"
apt-get -y install nginx
apt-get -y install latex-xcolor texlive-latex-extra texlive-fonts-recommended python-numpy python-setuptools mercurial
apt-get -y install build-essential python-dev libxml2-dev python-pip unzip wipe gzip
easy_install xlutils
pip install --upgrade pip
PIPPATH=`which pip`
echo "Installing uWSGI"
$PIPPATH install --upgrade uwsgi
echo

# Creando las secciones de Nginx necesarias
echo "Creando las secciones de Nginx necesarias en /etc/nginx/conf.d/web2py ..."
mkdir /etc/nginx/conf.d/web2py
echo '
gzip_static on;
gzip_http_version 1.1;
gzip_proxied expired no-cache no-store private auth;
gzip_disable "MSIE [1-6]\.";
gzip_vary on;
' > /etc/nginx/conf.d/web2py/gzip_static.conf

echo '
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
' > /etc/nginx/conf.d/web2py/gzip.conf



# Creando el archivo de configuración para Web2py /etc/nginx/sites-available/web2py
echo
echo
echo -e "Desea que se comprima el contenido de la web? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
echo "server {
	listen 80;
	server_name $DOMAINS;
	###to enable correct use of response.static_version
	#location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
	# alias /home/www-data/web2py/applications/\$1/static/\$2;
	# expires max;
	#}
	###
	###if you use something like myapp = dict(languages=['en', 'it', 'jp'], default_language='en') in your routes.py
	#location ~* ^/(\w+)/(en|it|jp)/static/(.*)$ {
	# alias /home/www-data/web2py/applications/\$1/;
	# try_files static/\$2/\$3 static/\$3 = 404;
	#}
	###
	location ~* ^/(\w+)/static/ {
	root /home/www-data/web2py/applications/;
	#remove next comment on production
	#expires max;
	### if you want to use pre-gzipped static files (recommended)
	### check scripts/zip_static_files.py and remove the comments
	# include /etc/nginx/conf.d/web2py/gzip_static.conf;
	###
	}
	location / {
	#uwsgi_pass 127.0.0.1:9001;
	uwsgi_pass unix:///tmp/web2py.socket;
	include uwsgi_params;
	uwsgi_param UWSGI_SCHEME \$scheme;
	uwsgi_param SERVER_SOFTWARE 'nginx/\$nginx_version';
	###remove the comments to turn on if you want gzip compression of your pages
	include /etc/nginx/conf.d/web2py/gzip.conf;
	### end gzip section
	### remove the comments if you use uploads (max 10 MB)
	#client_max_body_size 10m;
	###
	}
	}
	server {
	listen 443 ssl;
	server_name $DOMAINS;
	ssl_certificate /etc/nginx/ssl/web2py.crt;
	ssl_certificate_key /etc/nginx/ssl/web2py.key;
	ssl_prefer_server_ciphers on;
	ssl_session_cache shared:SSL:10m;
	ssl_session_timeout 10m;
	ssl_ciphers ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA:DHE-DSS-AES256-SHA:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA;
	ssl_protocols SSLv3 TLSv1;
	keepalive_timeout 70;
	location / {
	#uwsgi_pass 127.0.0.1:9001;
	uwsgi_pass unix:///tmp/web2py.socket;
	include uwsgi_params;
	uwsgi_param UWSGI_SCHEME \$scheme;
	uwsgi_param SERVER_SOFTWARE 'nginx/\$nginx_version';
	###remove the comments to turn on if you want gzip compression of your pages
	include /etc/nginx/conf.d/web2py/gzip.conf;
	### end gzip section
	### remove the comments if you want to enable uploads (max 10 MB)
	#client_max_body_size 10m;
	###
	}
	## if you serve static files through https, copy here the section
	## from the previous server instance to manage static files
	}" >/etc/nginx/sites-available/web2py
else
	echo "server {
	listen 80;
	server_name $DOMAINS;
	###to enable correct use of response.static_version
	#location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
	# alias /home/www-data/web2py/applications/\$1/static/\$2;
	# expires max;
	#}
	###
	###if you use something like myapp = dict(languages=['en', 'it', 'jp'], default_language='en') in your routes.py
	#location ~* ^/(\w+)/(en|it|jp)/static/(.*)$ {
	# alias /home/www-data/web2py/applications/\$1/;
	# try_files static/\$2/\$3 static/\$3 = 404;
	#}
	###
	location ~* ^/(\w+)/static/ {
	root /home/www-data/web2py/applications/;
	#remove next comment on production
	#expires max;
	### if you want to use pre-gzipped static files (recommended)
	### check scripts/zip_static_files.py and remove the comments
	# include /etc/nginx/conf.d/web2py/gzip_static.conf;
	###
	}
	location / {
	#uwsgi_pass 127.0.0.1:9001;
	uwsgi_pass unix:///tmp/web2py.socket;
	include uwsgi_params;
	uwsgi_param UWSGI_SCHEME \$scheme;
	uwsgi_param SERVER_SOFTWARE 'nginx/\$nginx_version';
	###remove the comments to turn on if you want gzip compression of your pages
	# include /etc/nginx/conf.d/web2py/gzip.conf;
	### end gzip section
	### remove the comments if you use uploads (max 10 MB)
	#client_max_body_size 10m;
	###
	}
	}
	server {
	listen 443 ssl;
	server_name $DOMAINS;
	ssl_certificate /etc/nginx/ssl/web2py.crt;
	ssl_certificate_key /etc/nginx/ssl/web2py.key;
	ssl_prefer_server_ciphers on;
	ssl_session_cache shared:SSL:10m;
	ssl_session_timeout 10m;
	ssl_ciphers ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA:DHE-DSS-AES256-SHA:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA;
	ssl_protocols SSLv3 TLSv1;
	keepalive_timeout 70;
	location / {
	#uwsgi_pass 127.0.0.1:9001;
	uwsgi_pass unix:///tmp/web2py.socket;
	include uwsgi_params;
	uwsgi_param UWSGI_SCHEME \$scheme;
	uwsgi_param SERVER_SOFTWARE 'nginx/\$nginx_version';
	###remove the comments to turn on if you want gzip compression of your pages
	# include /etc/nginx/conf.d/web2py/gzip.conf;
	### end gzip section
	### remove the comments if you want to enable uploads (max 10 MB)
	#client_max_body_size 10m;
	###
	}
	## if you serve static files through https, copy here the section
	## from the previous server instance to manage static files
	}" >/etc/nginx/sites-available/web2py
fi



ln -s /etc/nginx/sites-available/web2py /etc/nginx/sites-enabled/web2py
rm /etc/nginx/sites-enabled/default
mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
openssl genrsa 1024 > web2py.key
chmod 400 web2py.key
openssl req -new -x509 -nodes -sha1 -days 1780 -key web2py.key > web2py.crt
openssl x509 -noout -fingerprint -text < web2py.crt > web2py.info

# Preparando los directorios para uWSGI
echo 'Preparando los directorios para uWSGI ...'
mkdir -p /etc/uwsgi
mkdir -p /var/log/uwsgi

# Creando el archivo de configuración /etc/uwsgi/web2py.ini
echo "Creando el archivo de configuración /etc/uwsgi/web2py.ini ..."
echo "[uwsgi]
socket = /tmp/web2py.socket
pythonpath = /home/www-data/web2py/
mount = /=wsgihandler:application
processes = 4
master = true
harakiri = 60
reload-mercy = 8
cpu-affinity = 1
stats = /tmp/web2py.stats.socket
max-requests = 2000
limit-as = 512
reload-on-as = 256
reload-on-rss = 192
uid = www-data
gid = www-data
cron = 0 0 -1 -1 -1 python /home/www-data/web2py/web2py.py -Q -S welcome -M -R scripts/sessions2trash.py -A -o
no-orphans = true
enable-threads = true
" >/etc/uwsgi/web2py.ini

# Creando un archivo de configuración por defecto para el demonio uWSGI
echo 'Creando un archivo de configuración por defecto para el demonio uWSGI ...'
echo ' # Default settings for uwsgi. This file is sourced by /usr/local/bin/uwsgi from /etc/init.d/uwsgi.
#Gracefuly provided by setup-web2py-nginx-uwsgi-debian7.sh
# Options to pass to /etc/init.d/uwsgi
CONFIG_DIR="/etc/uwsgi/"
LOG_FILE="/var/log/uwsgi/uwsgi.log"
' > /etc/default/uwsgi

# Creando un archivo de configuración para uWSGI en emperor-mode para System V en /etc/init.d/uwsgi
echo 'Creando un archivo de configuración para uWSGI en emperor-mode para System V en /etc/init.d/uwsgi ...'
echo '#! /bin/sh
### BEGIN INIT INFO
# Provides: uwsgi
# Required-Start: $syslog
# Required-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: starts uwsgi in emperor mode
# Description: starts uwsgi in emperor mode according /etc/uwsgi/*
#
### END INIT INFO
# Author: Upgrade Solutions <upgrade@upgradesolutions.com.br>
# Do NOT "set -e"
# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/usr/local/bin:/usr/local/sbin:/sbin:/usr/sbin:/bin:/usr/bin
DESC="uWSGI in Emperor Mode"
NAME=uwsgi
DAEMON=/usr/local/bin/$NAME
DAEMON_ARGS=
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0
# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME
DAEMON_ARGS="--master --die-on-term --emperor "$CONFIG_DIR" --daemonize "$LOG_FILE" "
# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh
# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions
#
# Function that starts the daemon/service
#
do_start()
{
# Return
# 0 if daemon has been started
# 1 if daemon was already running
# 2 if daemon could not be started
start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
|| return 1
start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
$DAEMON_ARGS \
|| return 2
# Add code here, if necessary, that waits for the process to be ready
# to handle requests from services started subsequently which depend
# on this one. As a last resort, sleep for some time.
}
#
# Function that stops the daemon/service
#
do_stop()
{
# Return
# 0 if daemon has been stopped
# 1 if daemon was already stopped
# 2 if daemon could not be stopped
# other if a failure occurred
start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
RETVAL="$?"
[ "$RETVAL" = 2 ] && return 2
# Wait for children to finish too if this is a daemon that forks
# and if the daemon is only ever run from this initscript.
# If the above conditions are not satisfied then add some other code
# that waits for the process to drop all resources that could be
# needed by services started subsequently. A last resort is to
# sleep for some time.
start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
[ "$?" = 2 ] && return 2
# Many daemons dont delete their pidfiles when they exit.
rm -f $PIDFILE
return "$RETVAL"
}
#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
#
# If the daemon can reload its configuration without
# restarting (for example, when it is sent a SIGHUP),
# then implement that here.
#
start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
return 0
}
case "$1" in
start)
[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
do_start
case "$?" in
0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
esac
;;
stop)
[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
do_stop
case "$?" in
0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
esac
;;
status)
status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
;;
reload|force-reload)
#
# If do_reload() is not implemented then leave this commented out
# and leave "force-reload" as an alias for "restart".
#
log_daemon_msg "Reloading $DESC" "$NAME"
do_reload
log_end_msg $?
;;
restart) #|force-reload)
#
# If the "reload" option is implemented then remove the
# "force-reload" alias
#
log_daemon_msg "Restarting $DESC" "$NAME"
do_stop
case "$?" in
0|1)
do_start
case "$?" in
0) log_end_msg 0 ;;
1) log_end_msg 1 ;; # Old process is still running
*) log_end_msg 1 ;; # Failed to start
esac
;;
*)
# Failed to stop
log_end_msg 1
;;
esac
;;
*)
#echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
exit 3
;;
esac
:' > /etc/init.d/uwsgi


# Estableciento los ajustes por defecto para inicializar uWSGI en el arranque
echo 'Estableciento los ajustes por defecto para inicializar uWSGI en el arranque ...'
chmod 755 /etc/init.d/uwsgi
update-rc.d defaults uwsgi

# Instalando Web2py
echo 'Instalando Web2py ...'
mkdir /home/www-data
cd /home/www-data
wget http://web2py.com/examples/static/web2py_src.zip
unzip web2py_src.zip
rm web2py_src.zip
mv web2py web2py


# Descargando la última versión de sessions2trash.py
wget http://web2py.googlecode.com/hg/scripts/sessions2trash.py -O /home/www-data/web2py/scripts/sessions2trash.py
#chown -R www-data:www-data web2py
cd /home/www-data/web2py
cp /home/www-data/web2py/handlers/wsgihandler.py /home/www-data/web2py/wsgihandler.py
cd applications
hg clone http://hg.savannah.nongnu.org/hgweb/karakolas/
cd karakolas /home/www-data/web2py/karakolas
hg update default
mv models/10_connection_string.py-EDITME models/10_connection_string.py
mv models/25_setup_email.py-EDITME models/25_setup_email.py
cd /home/www-data/web2py
sudo -u www-data python -c "from gluon.main import save_password; save_password(raw_input('Introduce la contraseña del administrador de Web2py: '),443)"
sudo -u www-data python -c "from gluon.main import save_password; save_password(raw_input('Vuelve a introducir la contraseña: '),80)"
chown -R www-data:www-data /home/www-data/

# Creando el script para Wipe /home/www-data/web2py/web2py_wipe_app.sh
echo "Creando el script para Wipe en /home/www-data/web2py/web2py_wipe_app.sh"
echo "
#!/bin/bash
wipe -qrfQ 1 /etc/uwsgi/web2py.ini /tmp/web2py* /home/www-data/web2py
/etc/init.d/nginx stop
find /etc/nginx/ -name *web2py* -exec wipe -qrfQ 1 {} \\;
/etc/init.d/uwsgi reload
/etc/init.d/nginx start
" > /home/www-data/web2py/web2py_wipe_app.sh && chmod +x /home/www-data/web2py/web2py_wipe_app.sh


# Instalando servidor MariaDB
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
#echo "
# MariaDB 5.5 repository list 
#deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/debian wheezy main
#deb-src http://ftp.osuosl.org/pub/mariadb/repo/5.5/debian wheezy main
#" >> /etc/apt/sources.list

echo "
# MariaDB 10.0 repository list - created 2015-01-15 05:03 UTC
# http://mariadb.org/mariadb/repositories/
deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/debian wheezy main
deb-src http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/debian wheezy main
" >> /etc/apt/sources.list

add-apt-repository 'deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/debian wheezy main'

apt-get update
apt-get -y install mariadb-server

echo "**********************************************"
echo "CONFIGURANDO BASE DE DATOS MariaDB"
echo
echo -e "Introduzca la contraseña de administrador de la base de datos: \c"
read -s pass
echo
passw2p=$PW;

echo "CREATE database web2pydb;
CREATE USER 'web2pyuser'@'localhost' IDENTIFIED BY '$passw2p';
GRANT ALL PRIVILEGES ON *.* TO 'web2pyuser'@'localhost';
flush PRIVILEGES;
" > dbconf.sql

mysql -uroot -p"$pass" -e "source ./dbconf.sql"

rm dbconf.sql

echo "
mysql://web2pyuser:$passw2p@localhost/karakolas
" > /home/www-data/web2py/applications/karakolas/private/ticket_storage.txt
chown -R www-data:www-data /home/www-data/web2py/applications/karakolas/private/ticket_storage.txt

echo "
# -*- coding: utf-8 -*-
# (C) Copyright (C) 2012, 2013 Pablo Angulo
# This file is part of karakolas <karakolas.org>.

# karakolas is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as 
# published by the Free Software Foundation, either version 3 of the 
# License, or (at your option) any later version.

# karakolas is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU Affero General Public 
# License along with karakolas.  If not, see 
# <http://www.gnu.org/licenses/>.

#########################################################################


##### Intrucciones #####
#Reemplaza la linea que define la variable db por la conexión a tu base de datos
#Más abajo tienes varios ejemplos
#Cuando termines, guarda el archivo en el mismo directorio, pero con el nombre
#10_connection_string.py en vez de 10_connection_string.py-EDITME

#Poner igual a false para produccion
desarrollo = False

#sqlite
#db = DAL('sqlite://storage.sqlite',pool_size=1,check_reserved=['mysql','sqlite', 'postgres'])

#mariadb (o mysql)
db = DAL('mysql://web2pyuser:$passw2p@localhost/web2pydb', migrate=migrate, lazy_tables=(not migrate))
#db = DAL('mysql://username:password@localhost/your_database', migrate=(desarrollo or migrate), lazy_tables=(not desarrollo and not migrate))

#postgresql
#db = DAL('postgres://username:password@localhost/mydb', migrate=migrate, lazy_tables=(not migrate))

# More options
#http://web2py.com/books/default/chapter/29/06/the-database-abstraction-layer
" > /home/www-data/web2py/applications/karakolas/models/10_connection_string.py

chown -R www-data:www-data /home/www-data/web2py/applications/karakolas/models/10_connection_string.py

# Reiniciando los servicios uWSGI y Nginx
service uwsgi restart && service nginx restart

