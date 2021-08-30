FROM ubuntu:20.04
ARG DEBIAN_FRONTEND="noninteractive"
# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

# Make sure the dependencies are met
RUN apt-get update \
	&& apt-get install -y tigervnc-standalone-server fluxbox xterm git net-tools python python-numpy scrot wget software-properties-common vlc avahi-daemon curl \
	&& sed -i 's/geteuid/getppid/' /usr/bin/vlc \
    && add-apt-repository ppa:obsproject/obs-studio \
	&& apt-get update \
	&& apt-get install -y obs-studio

# Build and Install Everything
RUN git config --global advice.detachedHead false \
	&& noVNC_VERSION=$(curl -s "https://api.github.com/repos/novnc/noVNC/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/') \
	&& websockify_VERSION=$(curl -s "https://api.github.com/repos/novnc/websockify/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/') \
	&& git clone --branch "${noVNC_VERSION}" --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
	&& git clone --branch "${websockify_VERSION}" --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
	&& ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
    && OBS_NDI_LATEST_RELEASE=$(curl -s https://api.github.com/repos/Palakis/obs-ndi/releases/latest) \
	&& echo "${OBS_NDI_LATEST_RELEASE}" | grep "https://github.com/Palakis/obs-ndi/releases/download/" | grep "libndi" | grep "_amd64.deb" | cut -d : -f 2,3 | tr -d "\"" | wget -O /tmp/libndi_amd64.deb -qi - \
    && echo "${OBS_NDI_LATEST_RELEASE}" | grep "https://github.com/Palakis/obs-ndi/releases/download/" | grep "obs-ndi_" | grep "_amd64.deb" | cut -d : -f 2,3 | tr -d "\"" | wget -O /tmp/obs-ndi_amd64.deb -qi - \
    && mkdir -p /config/obs-studio /root/.config/ \
	&& ln -s /config/obs-studio/ /root/.config/obs-studio \
    # install the plugins for NDI
	&& ls /tmp \
	&& dpkg -i /tmp/*.deb \
	&& rm -rf /tmp/*.deb \
	&& rm -rf /var/lib/apt/lists/* \
	# Copy various files to their respective places
	&& wget -q -O /opt/container_startup.sh https://raw.githubusercontent.com/luigi311/docker-obs-ndi/master/container_startup.sh \
	&& wget -q -O /opt/x11vnc_entrypoint.sh https://raw.githubusercontent.com/luigi311/docker-obs-ndi/master/x11vnc_entrypoint.sh \
	&& mkdir -p /opt/startup_scripts \
	&& wget -q -O /opt/startup_scripts/startup.sh https://raw.githubusercontent.com/luigi311/docker-obs-ndi/master/startup.sh \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh
	 
# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Studio\" command=\"obs\"" >> /usr/share/menu/custom-docker \
	&& echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
