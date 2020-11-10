# For valid combinations, check the following repo:
# https://gitlab.com/nvidia/container-images/cuda/tree/master/dist
# To enable cuda, use "--build-arg USE_CUDA=true" during image build process
# BUILD COMMAND docker build --network host --build-arg USE_CUDA=true -t erwinqi/pcl:v1 .
ARG USE_CUDA
ARG CUDA_VERSION="9.2"
ARG UBUNTU_DISTRO="16.04"
ARG BASE_CUDA_IMAGE=${USE_CUDA:+"nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_DISTRO}"}
ARG BASE_IMAGE=${BASE_CUDA_IMAGE:-"ubuntu:${UBUNTU_DISTRO}"}

FROM ${BASE_IMAGE}

ARG VTK_VERSION=6
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8

#Modifications for poor Internet condition in China
RUN rm /etc/apt/sources.list.d/cuda.list /etc/apt/sources.list.d/nvidia-ml.list && \
 	sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
	export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7891 && \
	apt-get update && \ 
	apt-get install -y \
      	cmake \
      	g++ \
      	clang \
      	wget \
      	git \
      	libboost-date-time-dev \
      	libboost-filesystem-dev \
      	libboost-iostreams-dev \
      	libeigen3-dev \
      	libblas-dev \
      	libflann-dev \
      	libglew-dev \
      	libgtest-dev \
      	libopenni-dev \
      	libopenni2-dev \
      	libproj-dev \
      	libqhull-dev \
      	libqt5opengl5-dev \
      	libusb-1.0-0-dev \
      	libvtk${VTK_VERSION}-dev \
      	libvtk${VTK_VERSION}-qt-dev \
      	qtbase5-dev \
      	software-properties-common && \ 
  	rm -rf /var/lib/apt/lists/*

# Eigen patch (https://eigen.tuxfamily.org/bz/show_bug.cgi?id=1462) to fix issue metioned
# in https://github.com/PointCloudLibrary/pcl/issues/3729 is available in Eigen 3.3.7
# Not needed from 20.04 since it is the default version from apt
RUN if [ `pkg-config --modversion eigen3 | cut -d. -f3` -lt 7 ]; then \
	export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7891 && \
	wget -qO- https://gitlab.com/libeigen/eigen/-/archive/3.3.7/eigen-3.3.7.tar.gz | tar xz && \
	apt-get install -y libblas-dev && \
	cd eigen-3.3.7 && \
	mkdir build && \
	cd build && \
	cmake .. && \
	make install && \
	cd ../.. && \
	rm -rf eigen-3.3.7/ && \
	rm -f eigen-3.3.7.tar.gz ; \
    fi

# To avoid CUDA build errors on CUDA 9.2+ GCC 7 is required
RUN if [ `gcc -dumpversion | cut -d. -f1` -lt 7 ]; then \
	export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7891 && \
	add-apt-repository ppa:ubuntu-toolchain-r/test && \
	apt-get update && \
	apt-get install g++-7 -y && \
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7 && \
	update-alternatives --config gcc ; \
    fi

# Compile PCL
RUN export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7891 && \
	cd /opt && \
	git clone https://github.com/PointCloudLibrary/pcl.git pcl-trunk && \
	ln -s /opt/pcl-trunk /opt/pcl && \
	cd /opt/pcl && git checkout pcl-1.11.1 && \
	mkdir -p /opt/pcl-trunk/release && \
	cd /opt/pcl/release && cmake -DCMAKE_BUILD_TYPE=None -DBUILD_GPU=ON -DBUILD_apps=ON -DBUILD_examples=ON .. && \
	cd /opt/pcl/release && make -j3 && \
	cd /opt/pcl/release && make install && \
	cd /opt/pcl/release && make clean && \
	ln -s /usr/local/include/pcl-1.11/pcl/ /usr/local/include/pcl && \
	ln -s /usr/include/eigen3/Eigen/ /usr/include/Eigen
	
