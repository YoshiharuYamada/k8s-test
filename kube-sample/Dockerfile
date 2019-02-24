FROM k8s.gcr.io/pause:3.1 AS pause
FROM node:10.15.1-slim AS node-10
FROM ruby:2.6.1 AS build

ENV RAILS_ENV production
ENV NODE_ENV production
ENV RAILS_LOG_TO_STDOUT true

COPY --from=node-10 /usr/local /usr/local
COPY --from=node-10 /opt /opt
COPY . /app
WORKDIR /app

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && bundle install --quiet --without development test \
  && yarn install --no-progress \
  && export SECRET_KEY_BASE=`bundle exec rake secret` \
  && bundle exec rake tmp:create \
  && bundle exec rails webpacker:compile \
  && bundle exec rails tmp:clear \
  && rm -rf app/javascript \
  && rm -rf node_modules \
  && rm -rf ~/.bundle \
  && rm -rf ~/.cache

FROM ruby:2.6.1

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends locales task-japanese \
  && rm -rf /var/lib/apt/lists/* \
  && echo 'ja_JP.UTF-8 UTF-8' > /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=ja_JP.UTF-8 \
  && cp -p /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && groupadd -r app && useradd -r -m -g app app
ENV LANG ja_JP.UTF-8

USER app
COPY --from=pause /pause /usr/local/bin/pause
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=app:app /app /app
WORKDIR /app

ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT true
