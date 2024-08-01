FROM        golang:1.20.1-alpine3.17 AS BUILD_IMAGE
RUN         apt update && apt upgrade -y  && apt install -y curl && apt install -y gcc && apt install -y libc-dev && apt install build-essential -y
WORKDIR     /go/src/github.com/adnanh/webhook
COPY        webhook.version .
RUN         curl -#L -o webhook.tar.gz https://api.github.com/repos/adnanh/webhook/tarball/$(cat webhook.version) && \
            tar -xzf webhook.tar.gz --strip 1 &&  \
            go get -d && \
            go build -ldflags="-s -w" -o /usr/local/bin/webhook

FROM        ubuntu:23.10
RUN         apt update && apt upgrade -y && apt install curl jq tini tzdata lynx -y
COPY        --from=BUILD_IMAGE /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR     /config
EXPOSE      9000
ENTRYPOINT  ["/bin/tini", "--", "/usr/local/bin/webhook"]
CMD         ["-verbose", "-hotreload", "-hooks=hooks.yml"]
