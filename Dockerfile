FROM ruby:alpine

RUN apk add make gcc libc-dev
RUN gem install ronn

ENTRYPOINT ["/usr/local/bundle/bin/ronn"]
