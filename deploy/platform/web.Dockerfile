FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S web \
    && adduser -S -G web web

WORKDIR /app

COPY web-server /app/web-server
COPY client/ /app/web/client/
COPY admin/ /app/web/admin/

RUN mkdir -p /app/conf \
    && chmod 0755 /app/web-server \
    && chown -R web:web /app

ENV TZ=Asia/Shanghai

USER web

EXPOSE 7402

ENTRYPOINT ["/app/web-server"]
