FROM ubuntu:20.04

ARG ZEPHYR_SDK_VERSION=0.14.1
ARG ZEPHYR_VERSION=3.0.0
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate -P /tmp"
ARG HOSTTYPE="x86_64"

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get -y install --no-install-recommends \
	git \
	ninja-build \
	gperf \
	ccache \
	dfu-util \
	device-tree-compiler \
	wget \
	python3-dev \
	python3-pip \
	python3-setuptools \
	python3-tk \
	python3-wheel \
	xz-utils \
	file \
	make \
	gcc \
	gcc-multilib \
	g++-multilib \
	libsdl2-dev \
	locales \
	gosu \
	sudo

# Add the Kitware APT repository to your sources list
RUN wget ${WGET_ARGS} https://apt.kitware.com/kitware-archive.sh && \
	bash /tmp/kitware-archive.sh

# Install cmake
RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get -y install --no-install-recommends cmake

# Install Zephyr Python packages
RUN wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/zephyr/archive/refs/tags/zephyr-v${ZEPHYR_VERSION}.tar.gz
RUN	tar xf /tmp/zephyr-v${ZEPHYR_VERSION}.tar.gz -C /tmp && \
	pip3 install -r /tmp/zephyr-zephyr-v${ZEPHYR_VERSION}/scripts/requirements.txt

# Install Zephyr SDK
RUN mkdir -p /opt/toolchains && \
	cd /opt/toolchains && \
	wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${HOSTTYPE}.tar.gz && \
	tar xf /tmp/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${HOSTTYPE}.tar.gz && \
	zephyr-sdk-${ZEPHYR_SDK_VERSION}/setup.sh -t all -h -c

ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZEPHYR_SDK_VERSION}

# Clean up stale packages
RUN apt-get clean -y && \
	apt-get autoremove --purge -y && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Initialise system locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ADD 'entrypoint.sh' '/opt/'
ENTRYPOINT ["/opt/entrypoint.sh"]
