# base image can be redhat/ubi8 etc.
ARG base_image
FROM ${base_image}

# lkp install generates hosts/$HOSTNAME during create_host_config. Here it requires
# user to pass hostname arg to specify a consistent name instead of the container
# hostname when building the image.
ARG hostname=lkp-docker
ENV HOSTNAME=${hostname}

WORKDIR /lkp/lkp-tests

COPY . ./

# UBI8 repos do not have some packages, hence we have to download from CentOS Vault
RUN cp ./docker/redhat/CentOS-8-Vault.repo /etc/yum.repos.d/ && \
    dnf config-manager --set-disabled ubi-8-*

# Force ignore error when running `dnf upgrade -y`
# Error: Problem: The operation would result in removing the following protected packages: redhat-release
RUN (dnf upgrade -y || true) && \
    dnf install -y \
    # kernel-tools installs turbostat
    kernel-tools \
    make \
    # procps installs vmstat, sysctl, etc to partially persistent commonly used dependencies
    procps \
    perf \
    # python3 required by libnuma
    python3 \
    hostname && \
    make install && \
    lkp install

ENTRYPOINT ["bash", "-c", "sleep infinity"]
