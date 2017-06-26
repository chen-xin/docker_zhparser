# Azurewind's PostgreSQL image with Chinese full text search
# build: docker build --force-rm -t chenxinaz/zhparser .
# run: docker run --name PostgreSQLcnFt -p 5432:5432 chenxinaz/zhparser
# run interactive: winpty docker run -it --name PostgreSQLcnFt -p 5432:5432 chenxinaz/zhparser --entrypoint bash chenxinaz/zhparser

FROM postgres

# set source to china mirrors
# --deplicted--..do not add "\" at end of line, in case that will merge
# all lines to one and cause error running "apt-get update"
# RUN echo "deb http://ftp2.cn.debian.org/debian/ jessie main non-free contrib \n\
# deb http://ftp2.cn.debian.org/debian/ jessie-updates main non-free contrib \n\
# deb http://ftp2.cn.debian.org/debian/ jessie-backports main non-free contrib \n\
# deb http://ftp2.cn.debian.org/debian-security/ jessie/updates main non-free contrib \n\
# deb-src http://ftp2.cn.debian.org/debian/ jessie main non-free contrib \n\
# deb-src http://ftp2.cn.debian.org/debian/ jessie-updates main non-free contrib \n\
# deb-src http://ftp2.cn.debian.org/debian/ jessie-backports main non-free contrib \n\
# deb-src http://ftp2.cn.debian.org/debian-security/ jessie/updates main non-free contrib" > /etc/apt/sources.list

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      gcc \
      make \
      libc-dev \
      postgresql-server-dev-9.6 \
      wget \
      unzip \
      ca-certificates \
      openssl \
	&& rm -rf /var/lib/apt/lists/* \
  && wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
  && wget -O zhparser.zip "https://github.com/amutu/zhparser/archive/master.zip" \
  && unzip zhparser.zip \
  && cd scws-1.2.3 \
  && ./configure \
  && make install \
  && cd /zhparser-master \
  && SCWS_HOME=/usr/local make && make install \
  # pg_trgm is recommend but not required.
  && echo "CREATE EXTENSION pg_trgm; \n\
CREATE EXTENSION zhparser; \n\
CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser); \n\
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;" \
> /docker-entrypoint-initdb.d/init-zhparser.sql \
  && apt-get purge -y gcc make libc-dev postgresql-server-dev-9.6 \
  && apt-get autoremove -y \
  && rm -rf \
    /zhparser-master \
    /zhparser.zip \
    /scws-1.2.3
