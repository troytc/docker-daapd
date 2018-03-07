FROM lsiobase/alpine:3.7

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="sparklyballs"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	alsa-lib-dev \
	autoconf \
	automake \
	avahi-dev \
	bash \
	bsd-compat-headers \
	build-base \
	bzip2-dev \
	confuse-dev \
	coreutils \
	curl \
	curl-dev \
	file \
	flac-dev \
	g++ \
	gcc \
	gettext-dev \
	gnutls-dev \
	gperf \
	imlib2-dev \
	json-c-dev \
	lame-dev \
	libcurl \
	libevent-dev \
	libgcrypt-dev \
	libogg-dev \
	libplist-dev \
	libsodium-dev \
	libtheora-dev \
	libtool \
	libunistring-dev \
	libva-dev \
	libvdpau-dev \
	libvorbis-dev \
	libvpx-dev \
	libxfixes-dev \
	make \
	openjdk8-jre-base \
	perl-dev \
	protobuf-c-dev \
	rtmpdump-dev \
	sdl2-dev \
	sqlite-dev \
	taglib-dev \
	tar \
	v4l-utils-dev \
	x264-dev \
	x265-dev \
	xvidcore-dev \
	yasm opus-dev \
	zlib-dev && \
 apk add --no-cache --virtual=build-dependencies \
	--repository http://nl.alpinelinux.org/alpine/edge/testing \
	libantlr3c-dev \
	mxml-dev && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	alsa-lib \
	avahi \
	confuse \
	dbus \
	gnutls \
	json-c \
	lame \
	libbz2 \
	libcurl \
	libevent \
	libgcrypt \
	libplist \
	librtmp \
	libsodium \
	libtheora \
	libunistring \
	libva \
	libvdpau \
	libvorbis \
	libvpx \
	libxcb \
	opus \
	protobuf-c \
	sdl2 \
	sqlite \
	sqlite-libs \
	v4l-utils-libs \
	valgrind \
	x264 \
	x264-libs \
	x265 \
	xvidcore && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/testing \
	libantlr3c \
	mxml && \
 echo "**** compile ffmpeg ****" && \
 curl -o \
 /tmp/0001-libavutil-clean-up-unused-FF_SYMVER-macro.patch -L \
	"https://git.alpinelinux.org/cgit/aports/plain/main/ffmpeg/0001-libavutil-clean-up-unused-FF_SYMVER-macro.patch" && \
 mkdir -p \
	/tmp/ffmpeg-source && \
 curl -o \
 /tmp/ffmpeg.tar.xz -L \
	"http://ffmpeg.org/releases/ffmpeg-3.4.2.tar.xz" && \
 tar xf \
 /tmp/ffmpeg.tar.xz -C \
	/tmp/ffmpeg-source --strip-components=1 && \
 cd /tmp/ffmpeg-source && \
 for i in /tmp/*.patch; do patch -p1 -i $i; done && \
 ./configure \
	--prefix=/usr \
	--enable-avresample \
	--enable-avfilter \
	--enable-debug \
	--enable-gnutls \
	--enable-gpl \
	--enable-libmp3lame \
	--enable-librtmp \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libxvid \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libtheora \
	--enable-libv4l2 \
	--enable-postproc \
	--enable-pic \
	--enable-pthreads \
	--enable-shared \
	--enable-libxcb \
	--disable-stripping \
	--disable-static \
	--enable-vaapi \
	--enable-vdpau \
	--enable-libopus && \
 make && \
 gcc -o tools/qt-faststart $CFLAGS tools/qt-faststart.c && \
 make doc/ffmpeg.1 doc/ffplay.1 doc/ffserver.1 && \
 make install install-man && \
 install -D -m755 tools/qt-faststart /usr/bin/qt-faststart && \
 echo "**** make antlr wrapper and compile forked-daapd ****" && \
 mkdir -p \
	/tmp/source/forked-daapd && \
 echo \
	"#!/bin/bash" > /tmp/source/antlr3 && \
 echo \
	"exec java -cp /tmp/source/antlr-3.4-complete.jar org.antlr.Tool \"\$@\"" >> /tmp/source/antlr3 && \
 chmod a+x /tmp/source/antlr3 && \
 curl -o \
 /tmp/source/antlr-3.4-complete.jar -L \
	http://www.antlr3.org/download/antlr-3.4-complete.jar && \
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
	--build=$CBUILD \
	--enable-chromecast \
	--enable-itunes \
	--enable-lastfm \
	--enable-mpd \
	--host=$CHOST \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/app \
	--sysconfdir=/etc && \
 make && \
 make install && \
 cp /etc/forked-daapd.conf /etc/forked-daapd.conf.orig && \
 echo "**** cleanup ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3689
VOLUME /config /music
