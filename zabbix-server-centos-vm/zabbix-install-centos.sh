
#Modify Sudoers file to not require tty for shell script execution on CentOS
# sudo sed -i '/Defaults[[:space:]]\+requiretty/s/^/#/' /etc/sudoers


#check root permissions
if [ "${UID}" -ne 0 ]; 
then 
     log "Script executed without root permissions" 
     echo "You must be root to run this program." >&2 
     exit 3 
fi 


#Check zabbix server ip address
IP=`ifconfig|sed -n 2p|awk '{print $2}'|cut -d ":" -f2`

#Env
yum -y install gcc gcc-c++ autoconf mysql-server mysql mysql-devel httpd php php-mysql php-gd php-bcmath php-xml php-pear php-xmlrpc php-mbstring php-bcmath php-snmp net-snmp-devel net-snmp net-snmp-utils OpenIPMI-devel curl-devel java-devel openldap-devel openldap wget unixODBC unixODBC-devel mysql-connector-odbc

#Install and config 
wget http://ufpr.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/2.4.0/zabbix-2.4.0.tar.gz

if [ $? -eq 0 ];then
tar zxvf zabbix-2.4.0.tar.gz
fi

useradd zabbix
cd zabbix-2.4.0

/etc/init.d/mysqld start

mysql << EOF
create database if not exists zabbix character set utf8;
grant all on zabbix.* to zabbix@localhost identified by 'zabbixpwd';
quit
EOF


mysql -uzabbix -pzabbixpwd zabbix < ./database/mysql/schema.sql
mysql -uzabbix -pzabbixpwd zabbix < ./database/mysql/images.sql
mysql -uzabbix -pzabbixpwd zabbix < ./database/mysql/data.sql


#Compiled
./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix --enable-server --enable-proxy --enable-agent --with-mysql=/usr/bin/mysql_config --with-net-snmp --with-libcurl --with-openipmi --with-unixodbc --with-ldap --enable-java && \
make && \
make install

#Service Configuration
cat >> /etc/services << "EOF"
zabbix-agent 10050/tcp Zabbix Agent
zabbix-agent 10050/udp Zabbix Agent
zabbix-trapper 10051/tcp Zabbix Trapper
zabbix-trapper 10051/udp Zabbix Trapper
EOF

#Install the startup script
\cp misc/init.d/fedora/core/zabbix* /etc/init.d/
chmod 755 /etc/init.d/zabbix*

sed -i 's#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g' /etc/init.d/zabbix_server
sed -i 's#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g' /etc/init.d/zabbix_agentd
sed -i 's#DBUser=root#DBUser=zabbix#g' /etc/zabbix/zabbix_server.conf
sed -i '102a\DBPassword=zabbixpwd' /etc/zabbix/zabbix_server.conf
sed -i "s/Server\=127.0.0.1/Server\=127.0.0.1,"$IP"/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive\=127.0.0.1/ServerActive\="$IP":10051/g" /etc/zabbix/zabbix_agentd.conf


#Start Zabbix Server
/etc/init.d/zabbix_server start

# Start Zabbix Agentd
/etc/init.d/zabbix_agentd start

#Configuration WEB
\cp -r frontends/php/* /var/www/html/
/etc/init.d/httpd start

#modify php.ini
sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#g' /etc/php.ini 
sed -i 's#max_execution_time = 30#max_execution_time = 300#g' /etc/php.ini 
sed -i 's#post_max_size = 8M#post_max_size = 32M#g' /etc/php.ini 
sed -i 's#max_input_time = 60#max_input_time = 300#g' /etc/php.ini 
sed -i 's#memory_limit = 128M#memory_limit = 512M#g' /etc/php.ini 
sed -i 's#;mbstring.func_overload = 0#ambstring.func_overload = 2#g' /etc/php.ini

/etc/init.d/httpd restart

touch /var/www/html/conf/zabbix.conf.php

cat > /var/www/html/conf/zabbix.conf.php << "EOF"
<?php
// Zabbix GUI configuration file
global $DB;

$DB["TYPE"]    = 'MYSQL';
$DB["SERVER"]   = 'localhost';
$DB["PORT"]    = '0';
$DB["DATABASE"]   = 'zabbix';
$DB["USER"]    = 'zabbix';
$DB["PASSWORD"]   = 'zabbixpwd';
// SCHEMA is relevant only for IBM_DB2 database
$DB["SCHEMA"]   = '';

$ZBX_SERVER    = 'localhost';
$ZBX_SERVER_PORT  = '10051';
$ZBX_SERVER_NAME  = '';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF




chkconfig --add zabbix_server && chkconfig --add zabbix_agentd && chkconfig zabbix_server on && chkconfig zabbix_agentd on
