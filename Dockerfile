# syntax=docker/dockerfile:1
FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
# Install relax dependencies
RUN apt-get update  && apt-get install -y \
    wget \
    git \
    python2 \
    build-essential \
    libnetcdf-dev \
    libnetcdff-dev \
    gfortran-10
# Install MKL libraries
RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    echo "deb https://apt.repos.intel.com/mkl all main" > /etc/apt/sources.list.d/intel-mkl.list && \
    apt-get update && \
    apt-get install -y intel-mkl-64bit-2018.2-046

COPY . /relax
WORKDIR /relax

RUN chmod -R 777 /relax/bootstrap.sh
RUN /relax/bootstrap.sh

CMD ["/bin/bash"]