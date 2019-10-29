FROM ubuntu:18.04 as intermediate
RUN apt-get update
RUN apt-get -y install git
COPY github_key .
RUN mkdir /root/.ssh/
RUN cat ./github_key > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN git clone git@github.com:alleuro/catalog.alleuro.com.git /var/www/html




#Download base image ubuntu 18.04

FROM ubuntu:18.04

COPY --from=intermediate /var/www/html /var/www/html


# Update Ubuntu Software repository
RUN apt-get -y update

#Install curl, apt https, make, python pip, and git
RUN apt-get install -y curl apt-transport-https apt-utils make python-pip git gnupg

#Add Microsoft repos using curl
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

#Install ODBC SQL drivers and mssql-tools




RUN apt-get update
RUN ACCEPT_EULA=Y apt-get -y install msodbcsql17
# optional: for unixODBC development headers
RUN apt-get -y install unixodbc-dev




# Install tzdata in non interactive session
RUN export DEBIAN_FRONTEND=noninteractive

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN apt-get install -y tzdata
RUN dpkg-reconfigure --frontend noninteractive tzdata




#Install php and apache2
RUN apt-get -y --no-install-recommends install php7.2 libapache2-mod-php7.2 mcrypt php7.2-mbstring php-pear php7.2-dev php7.2-curl apache2



#Install sql drivers for php
RUN pecl install sqlsrv pdo_sqlsrv
RUN echo "extension= pdo_sqlsrv.so" >> /etc/php/7.2/apache2/php.ini
RUN echo "extension= sqlsrv.so" >> /etc/php/7.2/apache2/php.ini
RUN echo "extension = pdo_sqlsrv.so" >> /etc/php/7.2/cli/conf.d/20-pdo_sqlsrv.ini
RUN echo "extension = sqlsrv.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`

#Cleanup old or not needed .deb files because apt-get is too lazy to do it itself
RUN apt-get clean && apt-get autoclean

###### This is where you can map a local directory to the docker's default apache site directory.
#Mount system /docker/webapp/html to /var/www/html
#ADD /your/local/path /var/www/html

#Reload modules and list them
RUN service apache2 restart
RUN apachectl -M
RUN tail /etc/php/7.2/apache2/php.ini


#Expose port 80 and start the apache2 service in the foreground
EXPOSE 80 443
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
