FROM debian:bullseye-slim

LABEL mantainer=fabio

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Rome

SHELL ["/bin/bash", "-xeo", "pipefail", "-c"]

RUN apt update && \
	apt upgrade -y && \
	apt install -y sudo nano ca-certificates curl wget systemd systemd-sysv \
		git tzdata htop tree iputils-ping net-tools && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && rm $(ls | grep -v systemd-tmpfiles-setup)

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp* \
	/lib/systemd/system/autovt@.service \
	/lib/systemd/system/console-getty.service \
	/lib/systemd/system/container-getty@.service \
	/lib/systemd/system/getty-pre.target \
	/lib/systemd/system/getty@.service \
	/lib/systemd/system/getty-static.service \
	/lib/systemd/system/getty.target \
	/lib/systemd/system/serial-getty@.service

RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
	sh get-docker.sh && \
	rm -f get-docker.sh && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN addgroup --gid 1000 debian && \
	useradd -m -s /bin/bash -g debian -G sudo,root,docker -u 1000 debian && \
	echo "debian:debian" | chpasswd && \
	echo "root:root" | chpasswd && \
	echo "debian ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
	dpkg-reconfigure --frontend=noninteractive tzdata && \
	systemctl enable docker

COPY --chown=debian:debian .bashrc /home/debian/.bashrc
COPY --chown=root:root .bashrc /root/.bashrc
COPY --chown=root:root daemon.json /etc/docker/daemon.json
COPY --chown=root:root override.conf /etc/systemd/system/docker.service.d/override.conf

VOLUME [ "/var/lib/docker", "/home/debian" ]

EXPOSE 2375

WORKDIR /home/debian

CMD ["/lib/systemd/systemd"]