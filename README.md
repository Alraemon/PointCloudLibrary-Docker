# PointCloudLibrary-Docker
Dockerfile used for building PointCloudLibrary(PCL) developing environment.

## Built with Ubuntu 16.04 & CUDA 9.2 & PCL 1.11.1

build command: `docker build --build-arg USE_CUDA=true .`

## Or you can pull it from DockerHub

`docker pull erwinqi/pcl:v1.11.1`

## Notice: Some tweaks in APT source were made to fit poor network in China. You may need to reset it.
