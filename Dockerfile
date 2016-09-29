FROM ruby:2.3.0-slim

MAINTAINER Niko Vähäsarja <deram@iki.fi>


RUN apt-get update && apt-get install -qq -y --fix-missing --no-install-recommends \
	build-essential \
	git \
	imagemagick \
	libpq-dev \
	librrd4 \
	librrd-dev \
	nodejs \
	rrdtool \
    && rm -rf /var/lib/apt/lists/*



RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/jessie-backports.list
RUN apt-get update && apt-get -t jessie-backports install -qq -y --fix-missing --no-install-recommends \
	inkscape \
    && rm -rf /var/lib/apt/lists/*

ENV INSTALL_PATH /isk
WORKDIR $INSTALL_PATH

RUN gem install bundler
COPY Gemfile* ./
RUN bundle install

