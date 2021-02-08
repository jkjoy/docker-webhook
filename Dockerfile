FROM        golang:1.15.8-alpine3.13 AS BUILD_IMAGE
RUN         apk add --update --no-cache -t build-deps curl gcc libc-dev libgcc
WORKDIR     /go/src/github.com/adnanh/webhook
COPY        webhook.version .
RUN         curl -#L -o webhook.tar.gz https://api.github.com/repos/adnanh/webhook/tarball/$(cat webhook.version) && \
            tar -xzf webhook.tar.gz --strip 1 &&  \
            go get -d && \
            go build -o /usr/local/bin/webhook

FROM        alpine:3.13.1
RUN         apk add --update --no-cache curl tini tzdata
COPY        --from=BUILD_IMAGE /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR     /config
EXPOSE      9000
ENTRYPOINT  ["/sbin/tini", "--", "/usr/local/bin/webhook"]
CMD         ["-verbose", "-hotreload", "-hooks=hooks.yml"]