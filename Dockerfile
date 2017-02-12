FROM alpine:3.4
MAINTAINER dev@jpillora.com
# prepare go env
ENV GOPATH /go
ENV NAME cloud-torrent
ENV PACKAGE github.com/jpillora/$NAME
ENV PACKAGE_DIR $GOPATH/src/$PACKAGE
ENV GOLANG_VERSION 1.7.5
ENV GOLANG_SRC_URL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
ENV GOLANG_SRC_SHA256 4e834513a2079f8cbbd357502cccaac9507fd00a1efe672375798858ff291815
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
# https://golang.org/issue/14851
COPY docker-golang.patch /no-pic.patch
# in one step (to prevent creating superfluous layers):
# 1. fetch and install temporary build programs,
# 2. build cloud-torrent alpine binary
# 3. remove build programs
RUN set -ex \
    && apk update \
	&& apk add ca-certificates \
	&& apk add --no-cache --virtual .build-deps \
		bash \
		gcc \
		musl-dev \
		openssl \
		git \
		go \
	&& export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
	&& wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
	&& echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz \
	&& cd /usr/local/go/src \
	&& patch -p2 -i /no-pic.patch \
	&& ./make.bash \
	&& mkdir -p $PACKAGE_DIR \
	&& git clone https://$PACKAGE.git $PACKAGE_DIR \
	&& cd $PACKAGE_DIR \
	&& go build -ldflags "-X main.VERSION=$(git describe --abbrev=0 --tags)" -o /usr/local/bin/$NAME \
	&& apk del .build-deps \
	&& rm -rf /no-pic.patch $GOPATH /usr/local/go
#run!
ENTRYPOINT ["cloud-torrent"]
