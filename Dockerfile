FROM ruby:2.7.1-alpine

ENV DEPS 'bash build-base tree'

RUN apk add --update $DEPS \
  && rm -rf /var/cache/apk/* \
  && gem install bundler

ENV APP_HOME /app
ENV PWD $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ADD stenohttp2.gemspec stenohttp2.gemspec

RUN bundle update --bundler
RUN bundle install --jobs 2 --retry 4

ADD lib lib
ADD spec spec
ADD bin bin
ADD keys keys
ADD public public
ADD sorbet sorbet

#EXPOSE 4567
