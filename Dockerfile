FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        borgbackup \
        cron \
        tini \
        curl \
        ca-certificates \
        git \
        jq \
        mariadb-backup \
        openssh-client \
        python3-pip \
        && \
        rm -rf /var/cache/apt /var/lib/apt/lists

RUN pip3 install docker

# download docker cli binary
ENV DOCKERVERSION=18.06.3-ce

COPY checksums.txt .

RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && sha1sum -c checksums.txt \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

# copy scripts
COPY backup.py restore.sh init.sh start-container.sh /backupscripts/

RUN ln -s /backupscripts/backup.py /usr/local/bin/backup && \
    ln -s /backupscripts/restore.sh /usr/local/bin/restore && \
    ln -s /backupscripts/init.sh /usr/local/bin/init-backup && \
    mkfifo /var/log/cron.fifo && \
    chmod a+x /backupscripts/*.sh && \
    chmod a+x /backupscripts/*.py && \
    echo "59 2 * * * /backupscripts/backup.py >/var/log/cron.fifo 2>/var/log/cron.fifo" | crontab -

ENV BORG_BASE_DIR=/borgconfig

VOLUME /borgconfig

ENTRYPOINT ["/usr/bin/tini", "-e", "143", "--"]

CMD ["/backupscripts/start-container.sh"]
