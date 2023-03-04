# syntax=docker/dockerfile:1

FROM elixir:1.14-otp-24-alpine AS build
ENV MIX_ENV=prod VERSION=2.5.1
WORKDIR /opt/pleroma
RUN apk add --no-cache git build-base cmake sudo file-dev
RUN git clone -b stable https://git.pleroma.social/pleroma/pleroma /opt/pleroma \
  && git checkout v$VERSION \
  && rm -rf /opt/pleroma/.git
RUN mix local.hex --force \
  && mix local.rebar --force
RUN mix deps.get
RUN mix compile

FROM elixir:1.14-otp-24-alpine
LABEL version=2.5.1
RUN addgroup -g 1000 pleroma \
  && adduser -S -s /bin/false -h /opt/pleroma -H -G pleroma -u 100 pleroma \
  && mkdir -p /opt/pleroma \
  && chown -R pleroma:pleroma /opt/pleroma
ENV MIX_ENV=prod
WORKDIR /opt/pleroma
# To put generated config
RUN mkdir -p /config \
  && chown -R pleroma:pleroma /config
# postgresql-client is for pg_isready
RUN apk add --no-cache git sudo file-dev postgresql-client \
  # Optional deps
  && apk add --no-cache ffmpeg imagemagick exiftool
USER pleroma
COPY --from=build --chown=pleroma:pleroma /opt/pleroma /opt/pleroma
RUN mix local.hex --force \
  && mix local.rebar --force
COPY --chown=pleroma:pleroma ./docker-entrypoint.sh /opt/pleroma/docker-entrypoint.sh
COPY --chown=pleroma:pleroma ./gen.sh /opt/pleroma/gen.sh
CMD ["./docker-entrypoint.sh"]
