#!/bin/bash

PASSWORD_POSTGRES='admin'
ODOO_USER="odoo"
ODOO_PASSWORD="odoo"
ODOO_HOME="/opt/$ODOO_USER"
ODOO_HOME_SERVER="$ODOO_HOME/server"
ODOO_CONFIG="$ODOO_USER-server"

#--------------------------------------------------
echo "ACTUALIZACION DEL SISTEMA"
sudo apt-get update
sudo apt-get dist-upgrade -y
#--------------------------------------------------

#--------------------------------------------------
echo "INSTALACION Y CONFIGURACION DE POSTGRESQL"
sudo apt-get install postgresql -y
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.3/main/postgresql.conf
sudo sed -i s/"local   all             postgres                                peer"/"local    all             postgres                                trust"/g /etc/postgresql/9.3/main/pg_hba.conf
sudo /etc/init.d/postgresql restart
sudo su - postgres -c "createuser -s $ODOO_USER" 2> /dev/null || true
psql -U postgres -c "alter role $ODOO_USER with password '$ODOO_PASSWORD';"
psql -U postgres -c "alter role postgres with password '$PASSWORD_POSTGRES';"
sudo sed -i s/"local    all             postgres                                trust"/"local   all             postgres                                md5 "/g /etc/postgresql/9.3/main/pg_hba.conf
sudo sed -i s/"local   all             all                                     peer"/"local   all             $ODOO_USER                                    md5"/g /etc/postgresql/9.3/main/pg_hba.conf
sudo /etc/init.d/postgresql restart
#--------------------------------------------------

#--------------------------------------------------
echo "INSTALACION DE LIBRERIAS"
sudo apt-get install openssh-server graphviz ghostscript postgresql-client python-dateutil python-feedparser python-matplotlib python-ldap python-libxslt1 \
python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz \
python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-imaging gcc python-dev mc bzr python-setuptools python-babel python-reportlab-accel \
python-zsi python-openssl python-egenix-mxdatetime python-jinja2 python-unittest2 python-mock python-docutils lptools make python-psutil python-paramiko poppler-utils \
python-pdftools antiword python-decorator python-requests python-pypdf python-passlib bzrtools python-libxml2 python-gdata python-numpy python-hippocanvas python-profiler \
postgresql-client-common git-core aptitude python-pil wkhtmltopdf python-pip -y

sudo pip install httplib2
sudo apt-get update
#--------------------------------------------------

#--------------------------------------------------
echo "INSTALAR ODOO"
sudo adduser --system --quiet --shell=/bin/bash --home=$ODOO_HOME --gecos 'ODOO' --group $ODOO_USER
sudo mkdir /var/log/$ODOO_USER
sudo chown $ODOO_USER:$ODOO_USER /var/log/$ODOO_USER
cd $ODOO_HOME
sudo wget http://nightly.odoo.com/9.0/nightly/src/odoo_9.0.20151015.tar.gz
tar_odoo=$(ls)
sudo su $ODOO_USER -c "tar xvf $tar_odoo"
for v in $(ls); do
        if [ $v != $tar_odoo ]; then
                sudo su $ODOO_USER -c "mv $v $ODOO_HOME_SERVER"
                break
        fi
done
sudo rm $tar_odoo
sudo su $ODOO_USER -c "chmod -R 775 $ODOO_HOME/*"

echo "CREAR ARCHIVO DE REGISTRO"
sudo su root -c "echo '[options]' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'db_host=False' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'db_port=False' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'db_user=$ODOO_USER' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'db_password=$ODOO_PASSWORD' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'logfile=/var/log/$ODOO_USER/$ODOO_CONFIG.log' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'addons_path=$ODOO_HOME_SERVER/openerp/addons' >> /etc/$ODOO_CONFIG.conf"
sudo chown $ODOO_USER:$ODOO_USER /etc/$ODOO_CONFIG.conf
sudo chmod 640 /etc/$ODOO_CONFIG.conf
#--------------------------------------------------

#--------------------------------------------------
echo "AUTOMATIZAR EL ARRANQUE Y STOP DEL SERVICIO DE ODOO"
echo -e "* Create file odoo-server"
echo '#!/bin/sh' >> ~/$ODOO_CONFIG
echo '### BEGIN INIT INFO' >> ~/$ODOO_CONFIG
echo "# Provides: $ODOO_CONFIG" >> ~/$ODOO_CONFIG
echo '# Required-Start: $remote_fs $syslog' >> ~/$ODOO_CONFIG
echo '# Required-Stop: $remote_fs $syslog' >> ~/$ODOO_CONFIG
echo '# Should-Start: $network' >> ~/$ODOO_CONFIG
echo '# Should-Stop: $network' >> ~/$ODOO_CONFIG
echo '# Default-Start: 2 3 4 5' >> ~/$ODOO_CONFIG
echo '# Default-Stop: 0 1 6' >> ~/$ODOO_CONFIG
echo '# Short-Description: Enterprise Business Applications' >> ~/$ODOO_CONFIG
echo '# Description: ODOO Business Applications' >> ~/$ODOO_CONFIG
echo '### END INIT INFO' >> ~/$ODOO_CONFIG
echo 'PATH=/bin:/sbin:/usr/bin' >> ~/$ODOO_CONFIG
echo "DAEMON=$ODOO_HOME_SERVER/openerp-server" >> ~/$ODOO_CONFIG
echo "NAME=$ODOO_CONFIG" >> ~/$ODOO_CONFIG
echo "DESC=$ODOO_CONFIG" >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo '# Specify the user name (Default: odoo).' >> ~/$ODOO_CONFIG
echo "USER=$ODOO_USER" >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/$ODOO_CONFIG
echo "CONFIGFILE=\"/etc/$ODOO_CONFIG.conf\"" >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo '# pidfile' >> ~/$ODOO_CONFIG
echo 'PIDFILE=/var/run/$NAME.pid' >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo '# Additional options that are passed to the Daemon.' >> ~/$ODOO_CONFIG
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> ~/$ODOO_CONFIG
echo '[ -x $DAEMON ] || exit 0' >> ~/$ODOO_CONFIG
echo '[ -f $CONFIGFILE ] || exit 0' >> ~/$ODOO_CONFIG
echo 'checkpid() {' >> ~/$ODOO_CONFIG
echo '[ -f $PIDFILE ] || return 1' >> ~/$ODOO_CONFIG
echo 'pid=`cat $PIDFILE`' >> ~/$ODOO_CONFIG
echo '[ -d /proc/$pid ] && return 0' >> ~/$ODOO_CONFIG
echo 'return 1' >> ~/$ODOO_CONFIG
echo '}' >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo 'case "${1}" in' >> ~/$ODOO_CONFIG
echo 'start)' >> ~/$ODOO_CONFIG
echo 'echo -n "Starting ${DESC}: "' >> ~/$ODOO_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$ODOO_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$ODOO_CONFIG
echo 'echo "${NAME}."' >> ~/$ODOO_CONFIG
echo ';;' >> ~/$ODOO_CONFIG
echo 'stop)' >> ~/$ODOO_CONFIG
echo 'echo -n "Stopping ${DESC}: "' >> ~/$ODOO_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIG
echo '--oknodo' >> ~/$ODOO_CONFIG
echo 'echo "${NAME}."' >> ~/$ODOO_CONFIG
echo ';;' >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo 'restart|force-reload)' >> ~/$ODOO_CONFIG
echo 'echo -n "Restarting ${DESC}: "' >> ~/$ODOO_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIG
echo '--oknodo' >> ~/$ODOO_CONFIG
echo 'sleep 1' >> ~/$ODOO_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$ODOO_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$ODOO_CONFIG
echo 'echo "${NAME}."' >> ~/$ODOO_CONFIG
echo ';;' >> ~/$ODOO_CONFIG
echo '*)' >> ~/$ODOO_CONFIG
echo 'N=/etc/init.d/${NAME}' >> ~/$ODOO_CONFIG
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> ~/$ODOO_CONFIG
echo 'exit 1' >> ~/$ODOO_CONFIG
echo ';;' >> ~/$ODOO_CONFIG
echo '' >> ~/$ODOO_CONFIG
echo 'esac' >> ~/$ODOO_CONFIG
echo 'exit 0' >> ~/$ODOO_CONFIG

sudo mv ~/$ODOO_CONFIG /etc/init.d/
sudo chmod 755 /etc/init.d/$ODOO_CONFIG
sudo chown root: /etc/init.d/$ODOO_CONFIG
sudo update-rc.d $ODOO_CONFIG defaults
#--------------------------------------------------

echo "Instalación del SERVICIO ODOO terminado, ingresar por el puerto 8069"
