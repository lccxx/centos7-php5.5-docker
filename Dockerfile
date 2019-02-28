FROM centos

RUN set -ex; \
echo "1. set timezone to CST"; \
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
echo "2. close firewall (no need, docker image have no firewall)"; \
echo "3, config yum"; \
yum -y install epel-release yum-utils; \
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm; \
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm; \
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org; \
rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm; \
echo "4. update"; \
yum clean all; yum makecache; yum install -y epel-release; yum -y update; \
echo "5. update linux kernel (no need, docker latest centos image is latest kernel)"; \
echo "6. Nginx & PHP"; \
yum install -y nginx php55 php55-php-cli php55-php-fpm php55-php-mysqlnd \
    php55-php-zip php55-php-devel php55-php-gd php55-php-mcrypt \
    php55-php-mbstring php55-php-curl php55-php-xml php55-php-pear \
    php55-php-bcmath php55-php-json php55-php-common php55-php-opcache \
    php55-php-mysql php55-php-odbc php55-php-pecl-memcached \
    php55-php-pecl-redis; \
echo "7. config php & nginx"; \
sed -i 's/daemonize = yes/daemonize = no/g' /opt/remi/php55/root/etc/php-fpm.conf; \
sed -i 's/user = apache/user = nginx/g' /opt/remi/php55/root/etc/php-fpm.d/www.conf; \
sed -i 's/group = apache/group = nginx/g' /opt/remi/php55/root/etc/php-fpm.d/www.conf; \
sed -i 's/listen = 127.0.0.1\:9000/listen = \/tmp\/php-fpm.sock/g' /opt/remi/php55/root/etc/php-fpm.d/www.conf; \
sed -i 's/listen.allowed_clients = /;listen.allowed_clients = /g' /opt/remi/php55/root/etc/php-fpm.d/www.conf; \
sed -i 's/worker_processes  1;/worker_processes  auto;\ndaemon off;/' /etc/nginx/nginx.conf; \
sed -i 's/#tcp_nopush/client_max_body_size 2048M;\n\t#tcp_nopush/' /etc/nginx/nginx.conf; \
chown -R nginx:nginx /opt/remi/php55/root/var; \
mkdir /srv/public; \
echo 'server { listen 0.0.0.0:80; \
  set $root /srv/public; root $root; index index.html index.htm index.php; \
  location ~ \.php$ { include fastcgi_params; \
    fastcgi_param SCRIPT_FILENAME $root$fastcgi_script_name; \
    fastcgi_pass unix:/tmp/php-fpm.sock; } \
  location ~ \.sh$ { return 404; } \
  location ^~ /Dockerfile { return 404; } }' > /etc/nginx/conf.d/default.conf; \
echo "8. start nginx and php service"; \
yum install -y wget gcc; \
mkdir /tmp/build; cd /tmp/build; \
wget https://cr.yp.to/daemontools/daemontools-0.76.tar.gz; \
tar -xf daemontools-0.76.tar.gz; cd admin/daemontools-0.76; \
sed -i 's/gcc/gcc -include \/usr\/include\/errno.h/g' src/conf-cc; \
./package/install; \
cp command/* /usr/bin/; \
mkdir /etc/service; \
mkdir /srv/service_nginx; \
mkdir /srv/service_php-fpm; \
ln -s /opt/remi/php55/root/sbin/php-fpm /usr/bin; \
echo -e '#!/bin/bash\n\nexec nginx >> /var/log/nginx/run.log 2>&1' > /srv/service_nginx/run; \
chmod +x /srv/service_nginx/run; \
echo -e '#!/bin/bash\n\nexec setuidgid nginx php-fpm >> /var/log/php-fpm_run.log 2>&1' > /srv/service_php-fpm/run; \
chmod +x /srv/service_php-fpm/run; \
ln -s /srv/service_nginx /etc/service/nginx; \
ln -s /srv/service_php-fpm /etc/service/php-fpm; \
rm -rf /tmp/build; \
yum remove -y wget gcc; \
yum autoremove -y;
