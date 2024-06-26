# 可选 ghcr.io/wyx2685/xrayr:latest
FROM ghcr.io/wyx2685/xrayr:latest
WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
COPY /config/ /etc/XrayR/
RUN apk --update --no-cache add ca-certificates \
    && chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
