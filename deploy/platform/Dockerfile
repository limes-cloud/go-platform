FROM alpine:3.20

ARG BINARY
ARG APP_DIR=""
ARG APP_WORKDIR=/go/build

RUN apk add --no-cache ca-certificates curl tzdata \
    && addgroup -S app \
    && adduser -S -G app app

WORKDIR ${APP_WORKDIR}

COPY dist/${BINARY} ${APP_WORKDIR}/${BINARY}
COPY assets /tmp/platform-assets

RUN chmod 0755 "${APP_WORKDIR}/${BINARY}" \
    && if [ -n "${APP_DIR}" ] && [ -d "/tmp/platform-assets/${APP_DIR}" ]; then \
         cp -R "/tmp/platform-assets/${APP_DIR}/." "${APP_WORKDIR}/"; \
       fi \
    && rm -rf /tmp/platform-assets \
    && mkdir -p "${APP_WORKDIR}/conf" "${APP_WORKDIR}/config" "${APP_WORKDIR}/tmp/runtime" \
    && chown -R app:app "${APP_WORKDIR}"

ENV APP_BINARY=${BINARY} \
    APP_WORKDIR=${APP_WORKDIR} \
    TZ=Asia/Shanghai \
    GOLANG_PROTOBUF_REGISTRATION_CONFLICT=warn

USER app

CMD ./${APP_BINARY}
