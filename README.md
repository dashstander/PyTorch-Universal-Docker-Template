# The Universal PyTorch Source-Build Docker Template

## Preamble
As of the time of writing, tremendous academic effort has gone into the design and implementation of 
efficient neural networks to cope with the ever-increasing amount of data on ever-smaller and more efficient devices.
Yet, in practice, most researchers are unaware of even the most basic acceleration techniques.

Especially in academia, many do not even use Automatic Mixed Precision (AMP), 
even though it can reduce memory requirements to 1/4 and increase speeds by x4~5.
This is the case even though AMP can be enabled without much hassle using the 
PyTorch Lightning or HuggingFace Accelerate libraries.

Even novices who have only just dipped their toes into the murky waters of deep learning 
know that more compute is a key ingredient for success.
No matter how brilliant the researcher, 
outperforming a rival with x10 more compute is no mean feat.

This template was created with the aim of enabling researchers and engineers without much knowledge of 
GPUs, CUDA, Docker, etc. to squeeze every last drop of performance from their GPUs 
__*using the same hardware and neural networks*.__ 

If you are among those who could previously only wish for greater resources, this project may be of great utility.
Using a source build of PyTorch with the latest version of CUDA, when combined with AMP, 
can be expected to improve training times by x10. 

I sincerely hope that my project will be of service to researchers and engineers in both academia and industry.
Users who find my work beneficial are more than welcome to show their appreciation by starring this repository.


## Warning
__*Before using this template, first check whether you are actually using your GPU*__

In most scenarios, slow training is caused by an inefficient ETL (Extract, Transform, Load) pipeline.
Training is slow because the data is not getting to the GPU(s) fast enough, not because the GPU has slow compute.
First run `watch nvidia-smi` to check whether GPU utilization is high enough.
If GPU utilization is low or peaks sporadically, design an efficient ETL pipeline before using this template.
Otherwise, faster compute will not help very much as it will not be the bottleneck.

See https://www.tensorflow.org/guide/data_performance for a guide on designing an efficient ETL pipeline.


## Introduction
Template repository to build PyTorch __*from source*__ on __*any*__ version of PyTorch/CUDA/cuDNN.

PyTorch built from source is much faster (as much as x4 times on some benchmarks) 
than PyTorch installed from `pip`/`conda` but building from source is a 
difficult and bug-prone process.

This repository is a highly modular template to build 
any version of PyTorch from source on any version of CUDA.
It provides an easy-to-use Dockerfile which can be integrated 
into any Linux-based image or project.

For researchers unfamiliar with Docker, 
the generated wheel files can be extracted 
to install PyTorch on their local environments.

Windows users may also use this project via WSL. See instructions below.

A `Makefile` is provided both as an interface for easy use and as 
a tutorial for building custom images.

The speed gains from this template come from the following:
1. Using the latest version of CUDA and associated libraries (cuDNN, etc.).
2. Using a source build made especially for the target machine with the latest software customizations
instead of a build that must be compatible with different hardware and software environments.
3. Using the latest version of PyTorch and subsidiary libraries. 
Many users do not update their PyTorch
version because of compatibility issues with their environment.

Combined with techniques such as AMP and cuDNN benchmarking, 
it may be possible to increase the computational throughput
dramatically (e.g., x10) while using the same hardware.


## Quickstart
__*Users are free to customize the `train` stage of the `Dockerfile` as they please. 
However, do not change the `build` stages unless absolutely necessary.*__

This project is a template, and users are expected to customize it to fit their needs.

The code is assumed to be running on a Linux host with 
the necessary NVIDIA Drivers and a recent version of Docker pre-installed.
If this is not the case, install these first.

To build a training image, first edit the Dockerfile `train` stage to include 
desired packages from `apt`/`conda`/`pip`. 

Then, visit https://developer.nvidia.com/cuda-gpus to find the
Compute Capability (CC) of the target GPU device.

Finally, run `make all CC=TARGET_CC(s)`.

Examples: (1) `make all CC="8.6"` for RTX 3090, 
(2) `make all CC="7.5;8.6"` (no whitespace between CCs) 
for both RTX 2080Ti and RTX 3090 
(building for many GPU CCs will increase build time).

This will result in an image, `pytorch_source:train`, which can be used for training.

Note that CCs for devices not available during the build can be used to build the image.

For example, if the image must be used on an RTX 2080Ti machine but the user only has an RTX 3090, 
the user can set `CC="7.5"` to enable the image to operate on the RTX 2080Ti GPU.

See https://pytorch.org/docs/stable/cpp_extension.html 
for an in-depth guide on how to set `TORCH_CUDA_ARCH_LIST`, 
which is specified by `CC` in the `Makefile`.

Even if you do not wish to use Docker directly in your project,
you may still find this template useful.

**_The wheel files generated by the build can be used in any Python environment with no dependency on Docker._**

This project can thus be used to generate custom wheel files, 
improving both training and inference speeds dramatically, 
for any desired environment (`conda`, `pip`, etc.).

### Makefile Explanation
The `Makefile` is designed to make using this package simple and modular.

The first image to be created is `pytorch_source:build_install`, 
which contains all packages necessary for the build.

The second image is `pytorch_source:build_torch-v1.9.1` (by default), 
which contains the wheels for PyTorch, TorchVision, TorchText, and TorchAudio
with settings for PyTorch 1.9.1 on Ubuntu 20.04 LTS with Python 3.8, CUDA 11.3.1 and cuDNN 8.

The second image exists to cache the results of the build process.

If you do not wish to use Docker and would like to only extract 
the `.whl` wheel files for a pip install on your environment,
the generated wheel files can be found in the `/tmp/dist` directory.

Saving the build results also allows for more convenient version switching in case
different PyTorch versions (different CUDA version, different library version, etc.) are needed.

The final image is `pytorch_source:train`, which is the image to be used for actual training.

It relies on the previous stages only for the build artifacts (wheels, etc.) and nothing else.

This makes it very simple to create different training images optimized for different environments and GPU devices.

Because PyTorch has already been built, 
the training image only needs to download the 
remaining `apt`/`conda`/`pip` packages. 
Moreover, caching is implemented to speed up even this process.

### Timezone Settings
International users may find this section helpful.

The `train` image has its timezone set by the `TZ` variable using the `tzdata` package.
The default timezone is `Asia/Seoul` but this can be changed by specifying the `TZ` variable when calling `make`.
Use [IANA](https://www.iana.org/time-zones) timezone names to specify the desired timezone.

Example: `make all CC="8.6" TZ=America/Los_Angeles` to use LA time on the training image.

NOTE: Only the training image has timezone settings. 
The installation and build images do not use timezone information.

In addition, the training image has `apt` and `pip` installation URLs updated for Korean users.
If you wish to speed up your installs, please find URLs optimized for your location, 
though the installation caches may make this unnecessary.

## Specific PyTorch Version
To change the version of PyTorch,
set the `PYTORCH_VERSION_TAG`, `TORCHVISION_VERSION_TAG`, 
`TORCHTEXT_VERSION_TAG`, and `TORCHAUDIO_VERSION_TAG` variables
to matching versions.

The `*_TAG` variables must be GitHub tags or branch names of those repositories.
Visit the GitHub repositories of each library to find the appropriate tags.

__*PyTorch subsidiary libraries only work with matching versions of PyTorch.*__

Example: To build on an RTX 3090 GPU with PyTorch 1.9.1, use the following command:

`make all CC="8.6" 
PYTORCH_VERSION_TAG=v1.9.1 
TORCHVISION_VERSION_TAG=v0.10.1 
TORCHTEXT_VERSION_TAG=v0.10.1
TORCHAUDIO_VERSION_TAG=v0.9.1`.

The resulting image, `pytorch_source:train`, can be used 
for training with PyTorch 1.9.1 on GPUs with Compute Capability 8.6.

## Multiple Training Images
To use multiple training images on the same host, 
give a different name to `TRAIN_NAME`, 
which has a default value of `train`.

New training images can be created without having to rebuild PyTorch
if the same build image is used for different training images.
Creating new training images takes only a few minutes at most.

This is useful for the following use cases.
1. Allowing different users, who have different UID/GIDs, 
to use separate training images.
2. Using different versions of the final training image with 
different library installations and configurations.

For example, if `pytorch_source:build_torch-v1.9.1` has already been built,
Alice and Bob would use the following commands to create separate images.

Alice:
`make build-train 
CC="8.6"
TORCH_NAME=build_torch-v1.9.1
PYTORCH_VERSION_TAG=v1.9.1
TORCHVISION_VERSION_TAG=v0.10.1
TORCHTEXT_VERSION_TAG=v0.10.1
TORCHAUDIO_VERSION_TAG=v0.9.1
TRAIN_NAME=train_alice`

Bob:
`make build-train 
CC="8.6"
TORCH_NAME=build_torch-v1.9.1
PYTORCH_VERSION_TAG=v1.9.1
TORCHVISION_VERSION_TAG=v0.10.1
TORCHTEXT_VERSION_TAG=v0.10.1
TORCHAUDIO_VERSION_TAG=v0.9.1
TRAIN_NAME=train_bob` 

This way, Alice's image would have her UID/GID while Bob's image would have his UID/GID.
This procedure is necessary because training images have their users set during build.
Also, different users may install different libraries in their training images.
Their environment variables and other settings may also be different.

### Word of Caution
When using build images such as `pytorch_source:build_torch-v1.9.1` as a build cache 
for creating new training images, the user must re-specify all build arguments 
(variables specified by ARG and ENV using --build-arg) of all previous layers.

Otherwise, the default values for these arguments will be given to the Dockerfile
and a cache miss will occur because of the different input values.

This will both waste time rebuilding previous layers and, more importantly,
cause inconsistency in the training images due to environment mismatch.

The `BUILDKIT_INLINE_CACHE` must also be given to an image to use it as a cache later. See 
https://docs.docker.com/engine/reference/commandline/build/#specifying-external-cache-sources
for more information.

## Advanced Usage
The `Makefile` provides the `*-full` commands for advanced usage.

`make all-full CC=YOUR_GPU_CC TRAIN_NAME=train_cu102` will create 
`pytorch_source:build_torch-v1.9.1-ubuntu18.04-cuda10.2-cudnn8-py3.9` 
and `pytorch_source:train_cu102` by default.

These images can be used for training/deployment on CUDA 10 devices such as the GTX 1080Ti.

Also, the `*-clean` commands are provided to check for cache reliance on previous builds.


### Specific CUDA Version
Set `CUDA_VERSION`, `CUDNN_VERSION`, and `MAGMA_VERSION` to change CUDA versions.
`PYTHON_VERSION` may also be changed if necessary.

This will create a build image that can be used as a cache 
to create training images with the `build-train` command.

Also, the extensive use of caching in the project means that 
the second build is much faster than the first build.
This may be advantageous if many images must be created for multiple PyTorch/CUDA versions.

### Specific Linux Distro
CentOS and UBI images can be created with only minor edits to the `Dockerfile`.
Read the `Dockerfile` for full instructions.

Set `LINUX_DISTRO` and `DISTRO_VERSION` arguments afterwards.

### Windows
Windows users may use template by updating to Windows 11 and installing 
Windows Subsystem for Linux (WSL).
WSL on Windows 11 gives a similar experience to using native Linux.

This project has been tested on WSL on Windows 11 
with the WSL CUDA driver and Docker Desktop for Windows.


## Known Issues & TODOs
1. Entering a container by `ssh` will remove all variables set by `ENV`. 
This is because `sshd` starts a new environment, wiping out all previous variables.
Using `docker`/`docker-compose` to start containers is strongly recommended.
Use `ssh` only for network connections with containers 
(e.g., allowing the user to view Tensorboard or Jupyter on their local system).

2. Building on CUDA 11.4.x is not available as of October 2021 because `magma-cuda114`
has not been released on the `pytorch` anaconda channel yet.
Users may attempt building with older versions of `magma-cuda` or try the version available on `conda-forge`.
A source build of `magma` would be welcomed as a pull request.

3. CentOS and UBI images have not been implemented yet.
As they require only simple modifications, 
pull requests implementing them would be very much welcome.
