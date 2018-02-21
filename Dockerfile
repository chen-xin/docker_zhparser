# vim:set ft=dockerfile:
FROM postgres:alpine

ARG CN_MIRROR=0

RUN if [ $CN_MIRROR = 1 ] ; then OS_VER=$(grep main /etc/apk/repositories | sed 's#/#\n#g' | grep "v[0-9]\.[0-9]") \
  && echo "using mirrors for $OS_VER" \
  && echo https://mirrors.ustc.edu.cn/alpine/$OS_VER/main/ > /etc/apk/repositories; fi

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
	\
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
    postgresql-dev \
  && cd /scws-1.2.3 \
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
		/zhparser-master \
		/zhparser.zip \
    /scws-1.2.3 \
	&& find /usr/local -name '*.a' -delete
