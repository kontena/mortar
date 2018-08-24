FROM ruby:2.5-alpine as build

ADD . /src

RUN apk --update add git && \
    cd /src ; gem build kontena-mortar.gemspec

FROM ruby:2.5-alpine

COPY --from=build /src/*.gem /tmp/

RUN gem install /tmp/*.gem && \
    rm -f /tmp/*.gem

ENTRYPOINT [ "/usr/local/bundle/bin/mortar" ]