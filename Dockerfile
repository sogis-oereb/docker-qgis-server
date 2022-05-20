FROM phusion/baseimage:focal-1.1.0

LABEL maintainer="Amt fuer Geoinformation Kanton Solothurn <agi@bd.so.ch>"

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#Fonts
RUN apt-get update && apt-get install -y fontconfig unzip ttf-dejavu ttf-bitstream-vera fonts-liberation ttf-ubuntu-font-family && apt-get clean && rm -rf /var/lib/apt/lists/*

# Additional user fonts
COPY fonts/ /usr/share/fonts/truetype/
RUN fc-cache -f && fc-list | sort

#Headless X Server
RUN apt-get update && apt-get install -y xvfb && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/service/xvfb
ADD xvfb-run.sh /etc/service/xvfb/run
RUN chmod +x /etc/service/xvfb/run

#QGIS Server
RUN apt update && apt install -y gnupg wget software-properties-common ca-certificates && \
    wget -qO - https://qgis.org/downloads/qgis-2021.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    add-apt-repository "deb https://qgis.org/ubuntu-ltr $(lsb_release -c -s) main" && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y apache2 libapache2-mod-fcgid qgis-server && \
    apt clean all && \
    rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite && \
    a2enmod cgid && \
    a2enmod headers

# Configure logrotate for Apache (use apache2ctl instead of invoke-rc)
RUN sed -i -e 's|invoke-rc\.d\ apache2|/usr/sbin/apache2ctl|g' -e 's|reload|-k\ restart|g' /etc/logrotate.d/apache2

# Writeable dir for qgis_mapserv.log and qgis-auth.db
RUN mkdir /var/log/qgis && chown www-data:www-data /var/log/qgis
RUN mkdir /var/lib/qgis && chown www-data:www-data /var/lib/qgis
ARG URL_PREFIX=/qgis
ARG QGIS_SERVER_LOG_LEVEL=2
#ARG QGIS_FCGI_MIN_PROCESSES=1
#ARG QGIS_FCGI_MAX_PROCESSES=2
ARG QGIS_FCGI_CONNECTTIMEOUT=20
ARG QGIS_FCGI_IOTIMEOUT=90
ADD conf/qgis-server.conf /etc/apache2/sites-enabled/qgis-server.conf
RUN sed -i "s!@URL_PREFIX@!$URL_PREFIX!g;\
            s!@QGIS_SERVER_LOG_LEVEL@!$QGIS_SERVER_LOG_LEVEL!g;\
            s!@QGIS_FCGI_CONNECTTIMEOUT@!$QGIS_FCGI_CONNECTTIMEOUT!g;\
            s!@QGIS_FCGI_IOTIMEOUT@!$QGIS_FCGI_IOTIMEOUT!g;" \
    /etc/apache2/sites-enabled/qgis-server.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf

RUN mkdir /etc/service/apache2
ADD apache2-run.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

RUN mkdir /etc/service/dockerlog
ADD dockerlog-run.sh /etc/service/dockerlog/run
RUN chmod +x /etc/service/dockerlog/run

EXPOSE 80

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
