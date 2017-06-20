# vim:set ft=dockerfile:
FROM postgres:alpine

# Uncomment the following command if you are in China, or preffer other mirror
# RUN echo -e 'https://mirror.tuna.tsinghua.edu.cn/alpine/v3.5/main/' > /etc/apk/repositories

# Uncomment the following 4 commands if you have bad internet connection
# and first download the files into data directory
# COPY data/postgresql-9.6.3.tar.bz2 ./postgresql.tar.bz2
# COPY data/zhparser.zip /zhparser.zip
# COPY data/scws-1.2.3.tar.bz2 /scws-1.2.3.tar.bz2
# RUN tar xjf scws-1.2.3.tar.bz2


RUN set -ex \
	\
	&& apk add --no-cache --virtual .fetch-deps \
		ca-certificates \
		openssl \
		tar \
	&& wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
  && wget -O zhparser.zip "https://github.com/amutu/zhparser/archive/master.zip" \
	&& wget -O postgresql.tar.bz2 "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2" \
	&& echo "$PG_SHA256 *postgresql.tar.bz2" | sha256sum -c - \
	&& mkdir -p /usr/src/postgresql \
	&& tar \
		--extract \
		--file postgresql.tar.bz2 \
		--directory /usr/src/postgresql \
		--strip-components 1 \
	&& rm postgresql.tar.bz2 \
	\
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
  && cd scws-1.2.3 \
  && ./configure \
  && make install \
  && cd / \
  && unzip zhparser.zip \
  && cd /zhparser-master \
  && SCWS_HOME=/usr/local make && make install \
  # pg_trgm is recommend but not required.
  && echo -e "CREATE EXTENSION pg_trgm; \n\
CREATE EXTENSION zhparser; \n\
CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser); \n\
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;" \
> /docker-entrypoint-initdb.d/init-zhparser.sql \
    && apk del .build-deps .fetch-deps \
	&& rm -rf \
		/usr/src/postgresql \
		/pg_jieba-master \
		/pg_jieba-master.zip \
	&& find /usr/local -name '*.a' -delete
