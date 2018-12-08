# Dockerfile for sybase server

# docker build -t sybase .

FROM centos:7

# Adding resources

## SAP ASE Developer Edition 
# http://d1cuw2q49dpd0p.cloudfront.net/ASE16/Linux16SP03/ASE_Suite.linuxamd64.tgz

ARG ASE_URL="http://d1cuw2q49dpd0p.cloudfront.net/ASE16/Linux16SP03/ASE_Suite.linuxamd64.tgz"
ARG ASE_PAGESIZE="4k"

RUN set -x \
 && curl -OLS "$ASE_URL" \
 && mkdir -p /opt/tmp/ASE_Suite/ \
 && tar xfz ASE_Suite.linuxamd64.tgz -C /opt/tmp/ASE_Suite/ \
 && rm -rf ASE_Suite.linuxamd64.tgz

# Installing Sybase RPMs
RUN yum install libaio glibc unzip -y && \
    curl -OLS https://github.com/nguoianphu/docker-sybase/raw/master/assets/gtk2-2.24.28-8.el7.x86_64.rpm && \
    mv gtk*.rpm /opt/tmp && \
    rpm -ivh --nodeps /opt/tmp/gtk2-2.24.28-8.el7.x86_64.rpm

COPY assets/* /opt/tmp/

# set page size
RUN sed "s/^sqlsrv\.server_page_size.*/sqlsrv.server_page_size: $ASE_PAGESIZE/g" -i /opt/tmp/sybase-ase.rs && \
    grep "server_page_size" /opt/tmp/sybase-ase.rs

# Setting kernel.shmmax and 
RUN set -x \
 && cp /opt/tmp/sysctl.conf /etc/ \
 && true || /sbin/sysctl -p

#RUN set -x \
# && rpm -ivh --nodeps /opt/tmp/libaio-0.3.109-13.el7.x86_64.rpm \
# && rpm -ivh --nodeps /opt/tmp/gtk2-2.24.28-8.el7.x86_64.rpm \
# && rpm -Uvh --oldpackage --nodeps /opt/tmp/glibc-2.17-105.el7.i686.rpm


# Install Sybase
RUN set -x && \
  ls -l /opt/tmp && \
  /opt/tmp/ASE_Suite/setup.bin -f /opt/tmp/sybase-response.txt \
    -i silent \
    -DAGREE_TO_SAP_LICENSE=true \
    -DRUN_SILENT=true


# Copy resource file
RUN cp /opt/tmp/sybase-ase.rs /opt/sybase/ASE-16_0/sybase-ase.rs

# Build ASE server
RUN source /opt/sybase/SYBASE.sh \
 && /opt/sybase/ASE-16_0/bin/srvbuildres -r /opt/sybase/ASE-16_0/sybase-ase.rs

# Change the Sybase interface
# Set the Sybase startup script in entrypoint.sh

RUN mv /opt/sybase/interfaces /opt/sybase/interfaces.backup \
 && cp /opt/tmp/interfaces /opt/sybase/ \
 && cp /opt/tmp/sybase-entrypoint.sh /usr/local/bin/ \
 && chmod +x /usr/local/bin/sybase-entrypoint.sh \
 && ln -s /usr/local/bin/sybase-entrypoint.sh /sybase-entrypoint.sh
 
# MY FIX FOR DE
#RUN sed "s/^PE.*/PE=DE/g" -i /opt/sybase/ASE-16_0/sysam/MYSYBASE.properties

# Setup the ENV
# https://docs.docker.com/engine/reference/builder/#run
# RUN ["/bin/bash", "-c", "source /opt/sybase/SYBASE.sh"]

ENTRYPOINT ["/sybase-entrypoint.sh"]

# CMD []

EXPOSE 5000

# Remove tmp
RUN find /opt/tmp/ -type f | xargs -L1 rm -f

# Share the Sybase data directory
#VOLUME ["/opt/sybase/data"]

# When run it
# docker run -d -p 8000:5000 -p 8001:5001 --name my-sybase sybase
