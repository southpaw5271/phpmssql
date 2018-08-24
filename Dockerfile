#Download base image ubuntu 16.04

FROM ubuntu:16.04

# Update Ubuntu Software repository
RUN apt-get -y update

#Install curl, apt https, make, python pip, and git
RUN apt-get install -y --no-install-recommends curl apt-transport-https apt-utils make python-pip git

#Add Microsoft repos using curl
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2017.list | tee /etc/apt/sources.list.d/mssql-server-2017.list
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list	
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/mssql-tools.list

#Install ODBC SQL drivers and mssql-tools
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql17 mssql-tools
ENV PATH="/opt/mssql-tools/bin:${PATH}"

#Install php and apache2
RUN apt-get -y --no-install-recommends install php7.0 libapache2-mod-php7.0 mcrypt php7.0-mcrypt php-mbstring php-pear php7.0-dev apache2 unixodbc-dev

#Add mssql-tools to ~/.bashrc and ~/.bash_profile
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

#Install sql drivers for php
RUN pecl install sqlsrv pdo_sqlsrv
RUN echo "extension= pdo_sqlsrv.so" >> /etc/php/7.0/apache2/php.ini
RUN echo "extension= sqlsrv.so" >> /etc/php/7.0/apache2/php.ini
RUN echo "extension = pdo_sqlsrv.so" >> /etc/php/7.0/cli/conf.d/20-pdo_sqlsrv.ini
RUN echo "extension = sqlsrv.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`

#Cleanup old or not needed .deb files because apt-get is too lazy to do it itself
RUN apt-get clean && apt-get autoclean

###### This is where you can map a local directory to the docker's default apache site directory.
#Mount system /docker/webapp/html to /var/www/html
#ADD /your/local/path /var/www/html

#Reload modules and list them
RUN service apache2 restart
RUN apachectl -M
RUN tail /etc/php/7.0/apache2/php.ini

#Expose port 80 and start the apache2 service in the foreground
EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
