FROM ghcr.io/intelligence-ai/schemahub:v0.0.2 as builder
COPY configuration.json /app/configuration.json
COPY .cache /app/schemas
RUN intelligence-schemahub-index /app/configuration.json /app/index

FROM scratch
COPY --from=builder /usr/share/schemahub/static /usr/share/schemahub/static
COPY --from=builder /usr/bin/intelligence-schemahub-serve \
  /usr/bin/intelligence-schemahub-serve
COPY --from=builder /app/configuration.json /app/configuration.json
COPY --from=builder /app/index /app/index
