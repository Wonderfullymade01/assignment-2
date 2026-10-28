# Lightweight Linux base image
FROM alpine:3.20

LABEL description="Dockerized Linux diagnostic CLI"

# bash is the only extra package needed; ping, df, awk, hostname and getent
# are already provided by Alpine's busybox and musl-utils
RUN apk add --no-cache bash

WORKDIR /app

# Copy only the application scripts into the image
COPY app/ /app/

# Make scripts executable and expose the CLI as the "diagnostic" command
RUN chmod +x /app/diagnostic.sh /app/health-check.sh \
    && ln -s /app/diagnostic.sh /usr/local/bin/diagnostic

# Run as a non-root user for better security
RUN adduser -D -H appuser
USER appuser

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD ["/app/health-check.sh"]

# "docker run diagnostic-tool <command>" runs "diagnostic <command>"
ENTRYPOINT ["diagnostic"]
CMD ["help"]
