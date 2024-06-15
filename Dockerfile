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
RUN wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/2f3a5785-1c41-4f65-a2f9-ddf9e0db3ea0/l_onemkl_p_2024.1.0.695.sh && \
    sh ./l_onemkl_p_2024.1.0.695.sh -a --silent --cli --eula accept

COPY . /relax
WORKDIR /relax

RUN chmod -R 777 /relax/bootstrap.sh
RUN /relax/bootstrap.sh

ENV PATH="/relax/build/:${PATH}"

CMD ["/bin/bash"]