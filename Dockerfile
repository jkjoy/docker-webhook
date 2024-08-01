# Build stage (using golang image)
FROM --platform=linux/amd64 golang:1.20.1-alpine3.17 as build_image

# Install necessary packages
RUN apk update && apk add --no-cache curl gcc libc-dev build-base

WORKDIR /go/src/github.com/adnanh/webhook

# Copy required files and build the application
COPY webhook.version .
RUN curl -#L -o webhook.tar.gz https://api.github.com/repos/adnanh/webhook/tarball/$(cat webhook.version) && \
    tar -xzf webhook.tar.gz --strip 1 && \
    go get -d && \
    go build -ldflags="-s -w" -o /usr/local/bin/webhook

# Final stage (using ubuntu image)
FROM --platform=linux/amd64 ubuntu:22.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl jq tini tzdata lynx && \
    rm -rf /var/lib/apt/lists/*

# Copy the built application from build stage
COPY --from=build_image /usr/local/bin/webhook /usr/local/bin/webhook

# Set the working directory
WORKDIR /config

# Expose the application port
EXPOSE 9000

# Define the entry point and default command
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/webhook"]
CMD ["-verbose", "-hotreload", "-hooks=hooks.yml"]
