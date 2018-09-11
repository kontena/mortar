FROM ruby:2.5-alpine as build

ADD . /src

RUN apk --update add git build-base && \
    cd /src ; gem build kontena-mortar.gemspec && \
    gem install *.gem

FROM ruby:2.5-alpine

COPY --from=build /usr/local/bundle /usr/local/bundle

ENTRYPOINT [ "/usr/local/bundle/bin/mortar" ]