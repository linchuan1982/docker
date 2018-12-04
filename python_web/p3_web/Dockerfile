FROM python:3.6.7-slim-stretch
COPY ./web_server /web_server
WORKDIR /web_server
RUN echo "==> Install..."                               &&\
    apt-get update -qq                                  &&\
    apt-get -y install -qq --no-install-recommends default-libmysqlclient-dev gcc python3-dev > /dev/null &&\
    pip install --no-cache-dir -r "requirements.txt"    &&\
    echo "==> Clean up..."                              &&\   
    apt-get remove -y --auto-remove gcc                 &&\
    apt-get clean                                       &&\   
    rm -rf /var/lib/apt/lists/*
