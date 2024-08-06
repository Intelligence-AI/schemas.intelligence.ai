FROM ghcr.io/intelligence-ai/schemahub:v0.0.5 AS builder
COPY configuration.json /app/configuration.json
COPY vendor /app/vendor
RUN intelligence-schemahub-index /app/configuration.json /app/index

FROM scratch
COPY --from=builder /usr/share/schemahub/static /usr/share/schemahub/static
COPY --from=builder /usr/bin/intelligence-schemahub-serve \
  /usr/bin/intelligence-schemahub-serve
COPY --from=builder /app/configuration.json /app/configuration.json
COPY --from=builder /app/index /app/index

# Linker
COPY --from=builder /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=builder /etc/ld.so.cache /etc/ld.so.cache
# Based on an ldd(1) output on Debian Bookworm
COPY --from=builder /lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/
