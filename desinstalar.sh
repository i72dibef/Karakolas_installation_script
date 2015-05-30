#!/bin/bash
clear
echo 'Se va a proceder a desinstalar karakolas (y paquetes asociados) de su sistema'

touch /tofpr 2> /dev/null
# Comprobando si el usuario tiene permisos
if [ "$?" != "0" ]; then
	echo "Debes ejecutar este script como root (administrador) o con sudo"
	exit 1
fi
rm /tofpr

echo
echo '***** ATENCIÓN: se van a eliminar paquetes que pueden ser usados por otros servicios del sistema'
echo
echo 'Si no está seguro/a acerca de los paquetes que se van a eliminar, no continúe'
echo
echo '     >> También podrá eliminarlos manualmente más tarde'
echo
echo

rm -rf /home/www-data/web2py/applications/karakolas

# Eliminando Web2py
echo -e "Desea eliminar Web2py? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	rm /etc/nginx/conf.d/web2py/gzip_static.conf
	rm /etc/nginx/conf.d/web2py/gzip.conf
	rm -rf /home/www-data/web2py
	rm -rf etc/nginx/sites-available/web2py
fi

# Eliminando uWSGI
echo -e "Desea eliminar uWSGI? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	pip uninstall uwsgi
	rm -rf /etc/uwsgi
	rm -rf /var/log/uwsgi
	rm /etc/default/uwsgi
	rm /etc/init.d/uwsgi
	
fi

# Eliminando Nginx
echo
echo -e "Desea eliminar el servidor web Nginx? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	apt-get -y purge nginx
fi

# Eliminando otros paquetes
echo
echo "Se van a eliminar los siguientes paquetes:"
echo "xlutils latex-xcolor texlive-latex-extra texlive-fonts-recommended python-setuptools python-dev python-pip"
echo -e "Desea eliminarlos? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	pip uninstall xlutils
	apt-get -y purge latex-xcolor texlive-latex-extra texlive-fonts-recommended python-setuptools python-dev python-pip
fi

# Eliminando Unzip
echo
echo -e "Desea eliminar Unzip? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	apt-get -y purge unzip
fi

# Eliminando Wipe
echo
echo -e "Desea eliminar Wipe? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	apt-get -y purge wipe
fi

# Eliminando MariaDB
echo
echo -e "Desea eliminar el gestor de bases de datos MariaDB? Sí[s] | No[n]: \c"
read opc
if [ "$opc" = "s" ] || [ "$opc" = "S" ]; then
	echo -e "Introduzca la contraseña de administrador de la base de datos: \c"
	read -s pass
	echo
	echo "DROP database web2pydb;
	DROP USER 'web2pyuser'@'localhost';
	" > dbconf.sql
	mysql -uroot -p"$pass" -e "source ./dbconf.sql"
	rm dbconf.sql

	apt-get -y purge mariadb-*
	sed -i '/mariadb/d' /etc/apt/sources.list
	sed -i '/MariaDB/d' /etc/apt/sources.list
fi

apt-get -y autoremove

#apt-get -y purge latex-xcolor texlive-latex-extra texlive-fonts-recommended
#apt-get -y purge python-numpy python-setuptools python-dev python-pip
#apt-get -y purge mercurial
#apt-get -y purge unzip
#apt-get -y purge wipe
#apt-get -y purge build-essential
#apt-get -y purge mariadb-*
#sed -i '/mariadb/d' /etc/apt/sources.list
#sed -i '/MariaDB/d' /etc/apt/sources.list
#apt-get -y autoremove

#ppa-purge 'deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/debian wheezy main'
