FROM ros:indigo
#FROM ros:indigo-desktop-full
MAINTAINER Eric Dortmans (eric.dortmans AT gmail.com)

# Arguments
ARG user
ARG uid
ARG home
ARG workspace
ARG shell

# prevent debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

# install support packages
RUN apt-get update && apt-get install -y \
    zsh screen tree sudo ssh synaptic \
    build-essential tree wget curl \
    libncurses5-dev qtdeclarative5-dev \
#   python-rosdep python-rosinstall-generator python-wstool python-rosinstall  \
    && rm -rf /var/lib/apt/lists/*

# remove Gazebo 2 (only for indigo-desktop-full)
#RUN apt-get remove -y gazebo2 \
#    && rm /etc/ros/rosdep/sources.list.d/20-default.list \
#    && rosdep init && rosdep update \

# install Gazebo 7
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu trusty main" > /etc/apt/sources.list.d/gazebo-latest.list
RUN wget --quiet http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -
RUN apt-get update && apt-get install -y \
    gazebo7 libgazebo7-dev ros-$ROS_DISTRO-gazebo7-ros-pkgs ros-$ROS_DISTRO-gazebo7-ros-control \
    && wget https://raw.githubusercontent.com/osrf/osrf-rosdep/master/gazebo7/00-gazebo7.list -O /etc/ros/rosdep/sources.list.d/00-gazebo7.list \
    && rosdep update \
    && rm -rf /var/lib/apt/lists/*


#
# build Simatch
# TODO
#

# Clone user into docker image 
RUN \
  echo "${user}:x:${uid}:${uid}:${user},,,:${home}:${shell}" >> /etc/passwd && \
  echo "${user}:x:${uid}:" >> /etc/group && \
  echo "${user} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${user}" && \
  chmod 0440 "/etc/sudoers.d/${user}"


#
# GPU support
# http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration
#

# Intel GPU support
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*
# add user to video group
#RUN usermod -a -G video ${user}
RUN gpasswd -a ${user} video

# Nvidia GPU support
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV PATH /usr/local/nvidia/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

# Make SSH available
EXPOSE 22

# Mount the user's home directory
VOLUME "${home}"

# Switch to user
USER "${user}"
# to prevent Fontconfig warning: ignoring C.UTF-8: not a valid language tag
ENV LC_ALL=C
# for sharing Xauthority
ENV QT_X11_NO_MITSHM=1
ENV CATKIN_TOPLEVEL_WS="${workspace}/devel"
# Switch to the workspace
WORKDIR ${workspace}
