FROM lsiobase/xenial

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="sparklyballs"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# build packages variable
ARG BUILD_DEPENDENCIES="\
	antlr3 \
	autoconf \
	autotools-dev \
	build-essential \
	gawk \
	gettext \
	git \
	gperf \
	libantlr3c-dev \
	libasound2-dev \
	libavahi-client-dev \
	libavcodec-dev \
	libavfilter-dev \
	libavformat-dev \
	libavutil-dev \
	libconfuse-dev \
	libcurl4-gnutls-dev \
	libevent-dev \
	libgcrypt11-dev \
	libgnutls-dev \
	libjson-c-dev \
	libmxml-dev \
	libplist-dev \
	libprotobuf-c-dev \
	libsodium-dev \
	libsqlite3-dev \
	libswscale-dev \
	libtool \
	libunistring-dev \
	libwebsockets-dev \
	zlib1g-dev"

# runtime packages variable
ARG RUNTIME_DEPENDENCIES="\
	avahi-daemon \
	dbus\
	ffmpeg \
	libantlr3c-antlrdbg-3.2-0 \
	libavahi-client3 \
	libconfuse0\
	libevent-2.0-5 \
	libevent-pthreads-2.0-5 \
	libmxml1 \
	libplist++3v5 \
	libprotobuf-c1 \
	libunistring0"

RUN \
 echo "**** install build packages ****" && \
 apt-get update && \
 apt-get install -y \
 	$BUILD_DEPENDENCIES && \
 echo "**** compile forked-daapd ****" && \
 mkdir -p \
	/tmp/source/forked-daapd && \
 DAAPD_VER=$(curl -sX GET "https://api.github.com/repos/ejurgensen/forked-daapd/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o \
 /tmp/source/forked.tar.gz -L \
	"https://github.com/ejurgensen/forked-daapd/archive/${DAAPD_VER}.tar.gz" && \
 tar xf /tmp/source/forked.tar.gz -C \
	/tmp/source/forked-daapd --strip-components=1 && \
 export PATH="/tmp/source:$PATH" && \
 cd /tmp/source/forked-daapd && \
 autoreconf -i -v && \
 ./configure \
	--enable-chromecast \
	--enable-itunes \
	--enable-lastfm \
	--enable-mpd \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/app \
	--sysconfdir=/etc && \
 make && \
 make install && \
 cp /etc/forked-daapd.conf /etc/forked-daapd.conf.orig && \
 echo "**** uninstall build packages ****" && \
 apt-get purge -y --auto-remove \
	$BUILD_DEPENDENCIES && \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	--no-install-recommends \
	--no-install-suggests \
	$RUNTIME_DEPENDENCIES && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3689
VOLUME /config /music
