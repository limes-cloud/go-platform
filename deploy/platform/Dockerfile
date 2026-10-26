FROM alpine:3.20

ARG BINARY
ARG APP_DIR

RUN apk add --no-cache ca-certificates curl tzdata \
    && addgroup -S app \
    && adduser -S -G app app

WORKDIR /app

COPY dist/${BINARY} /app/${BINARY}
COPY assets/${APP_DIR}/ /app/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /app/${BINARY} /usr/local/bin/entrypoint.sh \
    && mkdir -p /app/conf /app/config /app/tmp/runtime \
    && chown -R app:app /app

ENV APP_BINARY=${BINARY} \
    TZ=Asia/Shanghai \
    GOLANG_PROTOBUF_REGISTRATION_CONFLICT=warn

USER app

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
