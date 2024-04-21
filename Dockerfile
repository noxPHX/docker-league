FROM debian:bullseye

ENV LANG=C.UTF-8
ENV TZ Europe/Amsterdam

ENV USER nocks
ENV HOME /home/$USER

RUN groupadd -g 1000 $USER && \
    useradd -r -u 1000 -g 1000 --create-home --home-dir $HOME $USER

RUN apt-get update && apt-get -y install \
    wget \
    curl \
    gnupg \
    tzdata \
    dirmngr \
    ca-certificates \
    apt-transport-https \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN usermod -aG audio $USER

RUN apt-get update && apt-get -y install \
    pulseaudio \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

COPY pulseaudio.client.conf /etc/pulse/client.conf

ENV PULSE_SERVER unix:/tmp/pulseaudio.socket
ENV PULSE_COOKIE /tmp/pulseaudio.cookie

# Add 32-bit architecture
RUN dpkg --add-architecture i386

RUN echo "deb https://dl.winehq.org/wine-builds/debian/ bullseye main " | tee /etc/apt/sources.list.d/winehq.list && \
    wget -q -nc https://dl.winehq.org/wine-builds/winehq.key -O- | apt-key add - && \
    echo "deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_11/ ./ " | tee /etc/apt/sources.list.d/wine-obs.list && \
    wget -q https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_11/Release.key -O- | apt-key add - && \
    apt-get update && apt-get -y install \
    winehq-staging \
    --install-recommends && \
    rm -rf /var/lib/apt/lists/*

# CPU drivers
RUN sed -i "s/main/main contrib non-free/g" /etc/apt/sources.list && \
    apt-get update && apt-get -y install \
    libdrm2 \
    libegl1-mesa \
    libdrm-intel1 \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libdrm-nouveau2

# AMD drivers
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    libdrm-amdgpu1 \
    libdrm-radeon1 \
    firmware-linux \
    firmware-linux-nonfree \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-radeon

# Vulkan & OpenCL packages
RUN apt-get -y install \
    mesa-utils \
    libvulkan1 \
    vulkan-tools \
    mesa-va-drivers \
    mesa-opencl-icd \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    vulkan-validationlayers

# Lutris dependencies
RUN apt-get update && apt-get -y install \
    git \
    unzip \
    libc6 \
    p7zip \
    psmisc \
    python3 \
    pciutils \
    libgcc1 \
    fluidsynth \
    cabextract \
    python3-gi \
    python3-pip \
    python3-pil \
    python3-yaml \
    python3-lxml \
    python3-dbus \
    python3-evdev \
    python3-cairo \
    python3-distro \
    gir1.2-gtk-3.0 \
    python3-requests \
    python3-protobuf \
    python3-gi-cairo \
    gir1.2-notify-0.7 \
    x11-xserver-utils \
    xdg-desktop-portal \
    gir1.2-webkit2-4.0 \
    fluid-soundfont-gs \
    python3-setproctitle \
    libgirepository1.0-dev \
    gir1.2-gnomedesktop-3.0 \
    libcanberra-gtk3-module

# Games dependencies
RUN apt-get update && apt-get -y install \
    xterm \
    zenity \
    winbind \
    dbus-x11 \
    nautilus \
    winetricks \
    firefox-esr && \
    rm -rf /var/lib/apt/lists/*

# Suppress GTK warnings about accessibility because there's no dbus (known bug)
ENV NO_AT_BRIDGE 1

# Some games needs some env vars to be set
ENV LOGNAME $USER
ENV USERNAME $USER
ENV TERM xterm
ENV DESKTOP_SESSION gnome

# Append the user to the correct groups
RUN usermod -aG video,render,kvm,106 $USER

WORKDIR $HOME

# Directory where games & scripts should be saved to separate home and other volumes
# Also ensure that permissions are correct
RUN mkdir /games /scripts && \
    chown -R $USER:$USER /games /scripts $HOME

# Switch user
USER $USER

# Retreive Lutris
RUN git clone https://github.com/lutris/lutris.git /tmp/lutris

RUN mkdir -p /tmp/user/100
ENV XDG_RUNTIME_DIR=/tmp/user/100

ENTRYPOINT [ "/tmp/lutris/bin/lutris" ]
