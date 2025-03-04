# base image can be opensuse/leap, etc
ARG base_image
FROM ${base_image}

# lkp install generates hosts/$HOSTNAME during create_host_config. Here it requires
# user to pass hostname arg to specify a consistent name instead of the container
# hostname when building the image.
ARG hostname=lkp-docker
ENV HOSTNAME=${hostname}

WORKDIR /lkp/lkp-tests

COPY . ./

RUN zypper refresh && \
    zypper update -y && \
    zypper install -y \
    # cpupower installs turbostat
    cpupower \
    make \
    # procps installs vmstat, sysctl, etc to partially persistent commonly used dependencies
    procps \
    perf \
    stress-ng \
    hostname && \
    make install && \
    lkp install

ENTRYPOINT ["bash", "-c", "sleep infinity"]
