# vim:set ft=dockerfile:
FROM postgres:alpine as builder

ARG CN_MIRROR=1

RUN if [ $CN_MIRROR = 1 ] ; then OS_VER=$(grep main /etc/apk/repositories | sed 's#/#\n#g' | grep "v[0-9]\.[0-9]") \
  && echo "using mirrors for $OS_VER" \
  && echo https://mirrors.ustc.edu.cn/alpine/$OS_VER/main/ > /etc/apk/repositories; fi

# Uncomment the following command if you are in China, or preffer other mirror
# RUN echo -e 'https://mirror.tuna.tsinghua.edu.cn/alpine/v3.5/main/' > /etc/apk/repositories

RUN apk update
RUN apk add ca-certificates openssl tar 
RUN apk add gcc g++ libc-dev make postgresql-dev libstdc++
RUN wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf -
RUN wget -O zhparser.zip "https://github.com/amutu/zhparser/archive/master.zip"
# RUN git clone --depth 1 https://github.com/amutu/zhparser 

RUN cd /scws-1.2.3 \
  && ./configure \
  && make install \
  # remake to temp dir
  && ./configure --prefix=/scws-1.2.3/usr/local \
  && make install \
  && tar zcf /scws.tar.gz ./usr \
  && cd / \
  && unzip zhparser.zip \
  && cd /zhparser-master \
  && SCWS_HOME=/usr/local make \
  && make install > install.sh \
  && find /usr/local -name '*zhparser*' -o -name 'dict.utf8.xdb' -o -name 'rules.utf8.ini' | xargs tar zcf /zhparser.tar.gz
  # pg_trgm is recommend but not required.

FROM postgres:alpine
ARG CN_MIRROR=1

COPY --from=builder /scws.tar.gz /
COPY --from=builder /zhparser.tar.gz /
RUN tar zxf /scws.tar.gz \
  && tar zxf /zhparser.tar.gz \
  && rm /*.tar.gz

RUN echo -e "CREATE EXTENSION pg_trgm; \n\
CREATE EXTENSION zhparser; \n\
CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser); \n\
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;" > /docker-entrypoint-initdb.d/init-zhparser.sql

