# syntax=docker/dockerfile:1

FROM ubuntu:24.04

ENV PATH=/opt/ata-flowgraphs:$PATH

# pinned versions
ARG UHD_SHA=61d75739ec5c3422720275abfc574b12a33eecf7
ARG GNURADIO_SHA=f6de6f56c87a40e38fa50b68e5daf9583aebcaed
ARG VOLK_TAG=v3.1.2
ARG GR_SATELLITES_TAG=v5.6.0
ARG GR_DSLWP_SHA=94c0869e927fc6a401937fc45edcceaa93e4a2ad
ARG ATA_FLOWGRAPHS_SHA=cd9db383ca2742c0ea72a41b5cdfeb3c2f77fc49
ARG INSPECTRUM_SHA=c6f4ecf6f74ea4dd33742feadff6e63f492b6e45
ARG LIQUID_DSP_TAG=v1.6.0
ARG ATA_UTILS_SHA=3be7d6fc71516df37e72521b5941b9048a67fe19

ARG DEBIAN_FRONTEND=noninteractive

ARG CFLAGS="-march=cascadelake -O3"
ARG CXXFLAGS=$CFLAGS

# install debian packages

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y \
    build-essential cmake autotools-dev autoconf git wget \
    python3-pip python3-venv python3-numpy python3-matplotlib python3-scipy jupyter \
    cppzmq-dev dh-python gir1.2-gtk-3.0 gir1.2-pango-1.0 libasound2-dev \
    libboost-date-time-dev libboost-dev libboost-program-options-dev libboost-regex-dev \
    libboost-filesystem-dev libboost-system-dev libboost-test-dev libboost-thread-dev \
    libcppunit-dev libfftw3-dev libfontconfig-dev libgmp-dev libgsl-dev libgsm1-dev libjack-jackd2-dev \
    libpulse-dev libqt5opengl5-dev libqt5svg5-dev libqwt-qt5-dev libsdl1.2-dev libsndfile1-dev \
    libspdlog-dev libthrift-dev libunwind-dev libxi-dev libxrender-dev ninja-build pkg-config \
    portaudio19-dev pybind11-dev python3-click python3-click-plugins python3-dev python3-gi \
    python3-gi-cairo python3-jsonschema python3-lxml python3-mako python3-numpy python3-opengl \
    python3-packaging python3-pygccxml python3-pyqt5 python3-schema python3-scipy python3-thrift \
    python3-yaml python3-zmq qt5-qmake qtbase5-dev qttools5-dev thrift-compiler xauth xmlto \
    xterm openbox tigervnc-standalone-server \
    && mkdir /build

# build and install Volk

RUN cd /build \
    && git clone --recursive https://github.com/gnuradio/volk \
    && mkdir volk/build \
    && cd volk/build \
    && git switch --detach $VOLK_TAG \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# build and install UHD

RUN cd /build \
    && git clone https://github.com/daniestevez/uhd \
    && mkdir uhd/host/build \
    && cd uhd/host/build \
    && git switch --detach $UHD_SHA \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# build and install GNU Radio

RUN cd /build \
    && git clone https://github.com/daniestevez/gnuradio \
    && mkdir gnuradio/build \
    && cd gnuradio/build \
    && git switch --detach $GNURADIO_SHA \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# build and install gr-satellites

RUN cd /build \
    && git clone https://github.com/daniestevez/gr-satellites \
    && mkdir gr-satellites/build \
    && cd gr-satellites/build \
    && git switch --detach $GR_SATELLITES_TAG \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# build and install gr-dslwp

RUN cd /build \
    && git clone https://github.com/daniestevez/gr-dslwp \
    && mkdir gr-dslwp/build \
    && cd gr-dslwp/build \
    && git switch --detach $GR_DSLWP_SHA \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# build and install liquid-dsp

RUN cd /build \
    && git clone https://github.com/jgaeddert/liquid-dsp \
    && cd liquid-dsp \
    && git switch --detach $LIQUID_DSP_TAG \
    && ./bootstrap.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install

# build and install inspectrum

RUN cd /build \
    && git clone https://github.com/miek/inspectrum \
    && mkdir inspectrum/build \
    && cd inspectrum/build \
    && git switch --detach $INSPECTRUM_SHA \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# install ATA python libs

RUN cd /build \
    && git clone https://github.com/SETIatHCRO/ATA-Utils \
    && cd ATA-Utils/pythonLibs \
    && git switch --detach $ATA_UTILS_SHA \
    && pip3 install --break-system-packages .

# install python packages

RUN pip3 install --break-system-packages astropy==6.1.5 spiceypy==2.3.0 

RUN ldconfig

# install ata-flowgraphs

RUN cd /opt \
    && git clone https://github.com/daniestevez/ata-flowgraphs \
    && cd ata-flowgraphs \
    && make

# clean build directory

RUN rm -rf /build

USER ubuntu
WORKDIR /home/ubuntu
