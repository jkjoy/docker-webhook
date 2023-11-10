FROM        golang:1.20.1-alpine3.17 AS BUILD_IMAGE
RUN         apk add --update --no-cache -t build-deps curl gcc libc-dev libgcc
WORKDIR     /go/src/github.com/adnanh/webhook
COPY        webhook.version .
RUN         curl -#L -o webhook.tar.gz https://api.github.com/repos/adnanh/webhook/tarball/$(cat webhook.version) && \
            tar -xzf webhook.tar.gz --strip 1 &&  \
            go get -d && \
            go build -ldflags="-s -w" -o /usr/local/bin/webhook

FROM        alpine:3.17.2
RUN         apk add --update --no-cache curl jq tini tzdata ca-certificates wget lynx && \
            wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
            wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk && \
            wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-dev-2.35-r1.apk  && \
            wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-bin-2.35-r1.apk && \
            wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-i18n-2.35-r1.apk && \
            apk add  glibc-2.35-r1.apk glibc-bin-2.35-r1.apk glibc-i18n-2.35-r1.apk glibc-dev-2.35-r1.apk && \
            /usr/glibc-compat/bin/localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 && \
            export PATH=/usr/glibc-compat/bin:$PATH && \
            localedef -i en_US -f UTF-8 en_US.UTF-8 && \
            export LANG=en_US.UTF-8
COPY        --from=BUILD_IMAGE /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR     /config
EXPOSE      9000
ENTRYPOINT  ["/sbin/tini", "--", "/usr/local/bin/webhook"]
CMD         ["-verbose", "-hotreload", "-hooks=hooks.yml"]
