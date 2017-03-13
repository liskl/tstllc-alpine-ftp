FROM registry.liskl.com/tstllc/alpine-base:latest

# Dev-Ops Team
MAINTAINER dl_team_devops@tstllc.net

ARG PUREFTPD_VERSION=1.0.43

ARG URL=http://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-$PUREFTPD_VERSION.tar.gz

ENV PUBLIC_HOST               ftp.infra.tstllc.net
ENV MAX_NUM_OF_CLIENTS_PER_IP 50
ENV MAX_CLIENTS               20
ENV MIN_PASV_PORT             30000
ENV MAX_PASV_PORT             30009
ENV UID                       1000
ENV GID                       1000

LABEL io.rancher.container.pull_image="always" \
      io.rancher.scheduler.affinity:host_label="ftp=true"

RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                build-base \
                                curl \
                                tar && \
    cd /tmp && \
    curl -sSL $URL | tar xz --strip 1 && \

    ./configure --prefix=/usr \
                --sysconfdir=/etc/pureftpd \
                --without-humor \
                --with-minimal \
                --with-throttling \
                --with-puredb \
                --with-rfc2640 \
                --with-peruserlimits \
                --with-ratios \
                --with-welcomemsg && \
    make install-strip && \
    cd .. && \
    rm -rf /tmp/* && \
    apk del .build-deps && \
    mkdir /etc/pureftpd

COPY entrypoint.sh /usr/bin/entrypoint.sh

VOLUME /home/ftpuser /etc/pureftpd

EXPOSE 21 $MIN_PASV_PORT-$MAX_PASV_PORT

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

CMD /usr/sbin/pure-ftpd \
                        -P $PUBLIC_HOST \
                        -C $MAX_NUM_OF_CLIENTS_PER_IP \
                        -c $MAX_CLIENTS \
                        -p $MIN_PASV_PORT:$MAX_PASV_PORT \
                        -l puredb:/etc/pureftpd/pureftpd.pdb \
                        -E \
                        -j \
                        -R
