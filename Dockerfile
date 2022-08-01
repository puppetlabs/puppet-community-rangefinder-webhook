FROM gliderlabs/alpine
MAINTAINER Ben Ford <ben.ford@puppet.com>
WORKDIR /var/run/rangefinder
RUN apk add --no-cache ruby ruby-dev build-base busybox                                           \
        && gem install etc json bigdecimal puppet-community-rangefinder-webhook puma --no-ri --no-rdoc \
        && apk del --purge binutils isl libgomp libatomic libgcc mpfr3 mpc1 libstdc++ gcc musl-dev libc-dev g++ make fortify-headers build-base libgmpxx gmp-dev ruby-dev \
        && rm -rf `gem environment gemdir`/cache                                                  \
        && rm -rf /var/cache/apk/*                                                                \
        && rm -rf /tmp/*
CMD ["rangefinder-webhook", "--config", "/var/run/rangefinder/config.yaml"]
