# Basic Makefile for starting projects.
# For more sophisticated settings, please use the Dockerfile directly.
# See https://developer.nvidia.com/cuda-gpus to find GPU CCs.
# Also assumes Linux shell for UID, GID.
# See https://pytorch.org/docs/stable/cpp_extension.html
# for an in-depth guide on how to set the `TORCH_CUDA_ARCH_LIST` variable,
# which is specified by `CC` in the `Makefile`.
CC                      = "5.2 6.0 6.1 7.0 7.5 8.0 8.6+PTX"
TRAIN_NAME              = train
TZ                      = Asia/Seoul
PYTORCH_VERSION_TAG     = v1.9.1
TORCHVISION_VERSION_TAG = v0.10.1
TORCHTEXT_VERSION_TAG   = v0.10.1
TORCHAUDIO_VERSION_TAG  = v0.9.1
TORCH_NAME              = build_torch-${PYTORCH_VERSION_TAG}

.PHONY: all build-install build-torch build-train
.PHONY: build-torch-full all-full build-train-clean build-train-full-clean

all: build-install build-torch build-train

build-install:
	DOCKER_BUILDKIT=1 docker build \
		--target build-install \
		--tag pytorch_source:build_install \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		- < Dockerfile

build-torch:
	DOCKER_BUILDKIT=1 docker build \
		--target train-builds \
		--cache-from=pytorch_source:build_install \
		--tag pytorch_source:${TORCH_NAME} \
		--build-arg TORCH_CUDA_ARCH_LIST=${CC} \
		--build-arg PYTORCH_VERSION_TAG=${PYTORCH_VERSION_TAG} \
		--build-arg TORCHVISION_VERSION_TAG=${TORCHVISION_VERSION_TAG} \
		--build-arg TORCHTEXT_VERSION_TAG=${TORCHTEXT_VERSION_TAG} \
		--build-arg TORCHAUDIO_VERSION_TAG=${TORCHAUDIO_VERSION_TAG} \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		- < Dockerfile

# Docker build arguments from all previous stages
# must be specified again or otherwise the default values of
# those arguments will be used as the inputs for the Dockerfile.
# This will cause a cache miss, leading to recompilation with the default arguments.
# This both wastes time and, more importantly, causes environment mismatch.
# Both the install and build images should be specified as caches.
# Otherwise, the installation process will cause a cache miss.
build-train:
	DOCKER_BUILDKIT=1 docker build \
		--target train \
		--cache-from=pytorch_source:build_install \
		--cache-from=pytorch_source:${TORCH_NAME} \
		--tag pytorch_source:${TRAIN_NAME} \
		--build-arg TORCH_CUDA_ARCH_LIST=${CC} \
		--build-arg PYTORCH_VERSION_TAG=${PYTORCH_VERSION_TAG} \
		--build-arg TORCHVISION_VERSION_TAG=${TORCHVISION_VERSION_TAG} \
		--build-arg TORCHTEXT_VERSION_TAG=${TORCHTEXT_VERSION_TAG} \
		--build-arg TORCHAUDIO_VERSION_TAG=${TORCHAUDIO_VERSION_TAG} \
		--build-arg GID="$(shell id -g)" \
		--build-arg UID="$(shell id -u)" \
		--build-arg TZ=${TZ} \
		- < Dockerfile


# The following builds are `full` builds, i.e., builds specifying all available options.
# Settings for CUDA 10 by default as an example.
LINUX_DISTRO    = ubuntu
DISTRO_VERSION  = 18.04
CUDA_VERSION    = 10.2
CUDNN_VERSION   = 8
PYTHON_VERSION  = 3.9
MAGMA_VERSION   = 102  # Magma version must match CUDA version.
TORCH_NAME_FULL = build_torch-${PYTORCH_VERSION_TAG}-${LINUX_DISTRO}${DISTRO_VERSION}-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}-py${PYTHON_VERSION}

all-full: build-torch-full build-train-full

build-torch-full:
	DOCKER_BUILDKIT=1 docker build \
		--target train-builds \
		--tag pytorch_source:${TORCH_NAME_FULL} \
		--build-arg TORCH_CUDA_ARCH_LIST=${CC} \
		--build-arg PYTORCH_VERSION_TAG=${PYTORCH_VERSION_TAG} \
		--build-arg TORCHVISION_VERSION_TAG=${TORCHVISION_VERSION_TAG} \
		--build-arg TORCHTEXT_VERSION_TAG=${TORCHTEXT_VERSION_TAG} \
		--build-arg TORCHAUDIO_VERSION_TAG=${TORCHAUDIO_VERSION_TAG} \
		--build-arg LINUX_DISTRO=${LINUX_DISTRO} \
		--build-arg DISTRO_VERSION=${DISTRO_VERSION} \
		--build-arg CUDA_VERSION=${CUDA_VERSION} \
		--build-arg CUDNN_VERSION=${CUDNN_VERSION} \
		--build-arg MAGMA_VERSION=${MAGMA_VERSION} \
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		- < Dockerfile

build-train-full:
	DOCKER_BUILDKIT=1 docker build \
		--target train \
		--tag pytorch_source:${TRAIN_NAME} \
		--cache-from=pytorch_source:${TORCH_NAME_FULL} \
		--build-arg TORCH_CUDA_ARCH_LIST=${CC} \
		--build-arg PYTORCH_VERSION_TAG=${PYTORCH_VERSION_TAG} \
		--build-arg TORCHVISION_VERSION_TAG=${TORCHVISION_VERSION_TAG} \
		--build-arg TORCHTEXT_VERSION_TAG=${TORCHTEXT_VERSION_TAG} \
		--build-arg TORCHAUDIO_VERSION_TAG=${TORCHAUDIO_VERSION_TAG} \
		--build-arg LINUX_DISTRO=${LINUX_DISTRO} \
		--build-arg DISTRO_VERSION=${DISTRO_VERSION} \
		--build-arg CUDA_VERSION=${CUDA_VERSION} \
		--build-arg CUDNN_VERSION=${CUDNN_VERSION} \
		--build-arg MAGMA_VERSION=${MAGMA_VERSION} \
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		--build-arg GID="$(shell id -g)" \
		--build-arg UID="$(shell id -u)" \
		--build-arg TZ=${TZ} \
		- < Dockerfile

# The following builds are `clean` builds, i.e., builds without using the cache.
# Their main purpose is to test whether the commands work properly without cached runs.
build-train-clean:
	DOCKER_BUILDKIT=1 docker build \
		--target train \
		--no-cache \
		--tag pytorch_source:${TRAIN_NAME} \
		--build-arg TORCH_CUDA_ARCH_LIST=${CC} \
		--build-arg PYTORCH_VERSION_TAG=${PYTORCH_VERSION_TAG} \
		--build-arg TORCHVISION_VERSION_TAG=${TORCHVISION_VERSION_TAG} \
		--build-arg TORCHTEXT_VERSION_TAG=${TORCHTEXT_VERSION_TAG} \
		--build-arg TORCHAUDIO_VERSION_TAG=${TORCHAUDIO_VERSION_TAG} \
		--build-arg GID="$(shell id -g)" \
		--build-arg UID="$(shell id -u)" \
		--build-arg TZ=${TZ} \
		- < Dockerfile

build-train-full-clean:
	DOCKER_BUILDKIT=1 docker build \
		--target train \
		--no-cache \
		--tag pytorch_source:${TRAIN_NAME} \
		--build-arg TORCH_CUDA_ARCH_LIST=${CC} \
		--build-arg PYTORCH_VERSION_TAG=${PYTORCH_VERSION_TAG} \
		--build-arg TORCHVISION_VERSION_TAG=${TORCHVISION_VERSION_TAG} \
		--build-arg TORCHTEXT_VERSION_TAG=${TORCHTEXT_VERSION_TAG} \
		--build-arg TORCHAUDIO_VERSION_TAG=${TORCHAUDIO_VERSION_TAG} \
		--build-arg LINUX_DISTRO=${LINUX_DISTRO} \
		--build-arg DISTRO_VERSION=${DISTRO_VERSION} \
		--build-arg CUDA_VERSION=${CUDA_VERSION} \
		--build-arg CUDNN_VERSION=${CUDNN_VERSION} \
		--build-arg MAGMA_VERSION=${MAGMA_VERSION} \
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		--build-arg GID="$(shell id -g)" \
		--build-arg UID="$(shell id -u)" \
		--build-arg TZ=${TZ} \
		- < Dockerfile
