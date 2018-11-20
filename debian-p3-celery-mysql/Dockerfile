FROM python:3.6.7-slim-stretch
ADD requirements.txt /app/requirements.txt
WORKDIR /app
RUN apt-get update -qq &&\
	apt-get -y install -qq --no-install-recommends default-libmysqlclient-dev gcc python3-dev > /dev/null &&\
	pip install -r "requirements.txt" &&\
echo "==> Clean up..."  && \   
	apt-get remove -y --auto-remove gcc  && \
	apt-get clean                                  && \   
	rm -rf /var/lib/apt/lists/*
