FROM ubuntu:16.04
MAINTAINER Xi Liu "x@hunch.ai"

ADD deploy/sources-xenial.list /etc/apt/sources.list
RUN mkdir /root/.pip
ADD deploy/pip.conf /root/.pip/pip.conf

RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get update

RUN apt-get install -y build-essential
RUN apt-get install -y python-dev mysql-client libmysqlclient-dev
RUN apt-get install -y sox libsox-fmt-mp3 lame locales sudo
RUN apt-get install -y wget unzip vim
RUN apt-get install -y nginx
RUN apt-get install -y --no-install-recommends polipo
RUN apt-get install -y libboost-system-dev libboost-regex-dev libboost-program-options-dev libboost-filesystem-dev
RUN rm -rf /var/lib/apt/lists/*

# waveform
RUN wget 'http://cdn.zenvideo.cn/zenvideo/libs/audiowaveform_1.2.2-2xenial1_amd64.deb'
RUN dpkg -i audiowaveform_1.2.2-2xenial1_amd64.deb

RUN wget 'https://bootstrap.pypa.io/get-pip.py'
RUN python get-pip.py
RUN rm get-pip.py

# FFMPEG
RUN wget 'http://cdn.zenvideo.cn/zenvideo/libs/ffmpeg-4.0.2-64bit-static.tar.xz' -O ffmpeg-4.0.2-64bit-static.tar.xz
RUN tar Jxf ffmpeg-4.0.2-64bit-static.tar.xz -C /opt && rm -f ffmpeg-4.0.2-64bit-static.tar.xz
ENV PATH=${PATH}:/opt/ffmpeg-4.0.2-64bit-static

# JAVA
RUN wget 'http://cdn.zenvideo.cn/zenvideo/libs/jdk-8u161-linux-x64.tar.gz' -O jdk-8u161-linux-x64.tar.gz
RUN tar zxf jdk-8u161-linux-x64.tar.gz -C /opt && rm -f jdk-8u161-linux-x64.tar.gz
ENV JAVA_HOME=/opt/jdk1.8.0_161
ENV PATH=${PATH}:${JAVA_HOME}/bin

# Celery and other env
RUN mkdir -p /mnt/log/celery/
RUN mkdir -p /mnt/log/aivideo/
RUN mkdir -p /mnt/log/asynctask/
RUN mkdir -p /var/run/celery/
RUN mkdir -p /mnt/tmp/wav
RUN mkdir -p /mnt/tmp/huazi

RUN chown -R www-data:www-data /mnt/log
RUN chown -R www-data:www-data /mnt/tmp
RUN chown -R www-data:www-data /var/run/celery

ADD deploy/tts_snippet /mnt/tmp/
ADD deploy/libmsc.so /mnt/tmp/

# Install Nginx.
RUN chown -R www-data:www-data /var/lib/nginx
RUN chown -R www-data:www-data /var/log/nginx
# Define mountable directories.
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]
ADD deploy/web_server/nginx-site /etc/nginx/sites-available/default
ADD deploy/web_server/nginx-conf /etc/nginx/nginx.conf

# GUNICORN
RUN mkdir -p /mnt/run/aivideo/
RUN chown -R www-data /mnt/run/

RUN mkdir -p /mnt/aivideo/
RUN chown -R www-data /mnt/

RUN mkdir -p /mnt/log/gunicorn
RUN chown -R www-data /mnt/log/

# Install one version of requirements
ADD deploy/web_server/base_requirements.txt /tmp
RUN pip install -r /tmp/base_requirements.txt

# Xunfei related
RUN mkdir -p /mnt/tmp/lfasr/lib
RUN mkdir -p /mnt/tmp/lfasr/wav
RUN chown -R www-data /mnt/tmp/lfasr/wav
ADD deploy/lfasr.jar /mnt/tmp/lfasr/lib/lfasr.jar
ADD deploy/autosub.jar /mnt/tmp/lfasr/autosub.jar
ADD deploy/lfasr-sdk-demo.jar /mnt/tmp/lfasr/lfasr-sdk-demo.jar

# Sensor statistics
WORKDIR /opt
RUN wget http://download.sensorsdata.cn/release/logagent/logagent_20180108.tgz
RUN tar zxvf logagent_20180108.tgz
RUN rm logagent_20180108.tgz
ADD deploy/web_server/logagent.conf /opt/logagent/logagent.conf

# MP4Box
WORKDIR /root
RUN wget https://cdn.zenvideo.cn/zenvideo/libs/MP4Box
RUN chmod 755 MP4Box
RUN mv MP4Box /usr/bin/

# Code
WORKDIR /root
RUN mkdir -p /var/www
COPY aivideo /var/www/aishipin
RUN chown -R www-data:www-data /var/www
RUN pip install -r /var/www/aishipin/requirements.txt

# AiVideo Download
RUN pip install -r /var/www/aishipin/aivideo_dl/requirements.txt

# proxy
COPY deploy/web_server/shadowsocks.json /etc/shadowsocks.json

ADD deploy/web_server/start.sh /var/www/aishipin
RUN chmod +x /var/www/aishipin/start.sh

ADD deploy/web_server/crontab /etc/cron.d/aivideo
RUN chmod 0644 /etc/cron.d/aivideo

# Locale
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

WORKDIR /var/www/aishipin

# supervisor
RUN pip install supervisor
RUN echo_supervisord_conf > /etc/supervisord.conf
RUN mkdir -p /etc/supervisor.conf.d/
RUN echo '[include] \n\
files = supervisor.conf.d/*.ini' >> /etc/supervisord.conf
COPY deploy/celery_worker/celery_worker.ini /etc/supervisor.conf.d/celery_worker.ini
COPY deploy/celery_worker/patch_worker.ini /etc/supervisor.conf.d/patch_worker.ini
COPY deploy/celery_worker/celery_beat.ini /etc/supervisor.conf.d/celery_beat.ini

# celery environments
ENV MYSQL_LOCATION='rm-bp1l867aq21qq1l7h2o.mysql.rds.aliyuncs.com'

# Entry
ADD deploy/start_worker.sh /var/www/aishipin
RUN chmod +x /var/www/aishipin/start_worker.sh
