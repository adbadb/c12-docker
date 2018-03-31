FROM       azul/zulu-openjdk-centos
MAINTAINER Alex Breyman <a@breyman.ru>

VOLUME ["/data"]
ENTRYPOINT ["/bin/cassandra-docker"]

# Install Java, Install packages (sshd + supervisord + monitoring tools + cassandra)
RUN yum install -y wget tar openssh-server openssh-clients supervisor sysstat sudo which openssl hostname
RUN yum clean all

# Configure SSH server
RUN mkdir -p /var/run/sshd && chmod -rx /var/run/sshd && \
	ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key && \
	sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
	sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
	sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config 

# Configure supervisord
ADD src/supervisord.conf /etc/supervisord.conf
RUN mkdir -p /var/log/supervisor

# Deploy startup script
ADD src/start.sh /usr/local/bin/start

# Necessary since cassandra is trying to override the system limitations
# See https://groups.google.com/forum/#!msg/docker-dev/8TM_jLGpRKU/dewIQhcs7oAJ
RUN rm -f /etc/security/limits.d/cassandra.conf


# Download and unpack Cassandra 1.2 dist
COPY install-cassandra-tarball.sh /
RUN /bin/sh /install-cassandra-tarball.sh

# create a cassandra user:group & chown
# Note: this UID/GID is hard-coded in main.go
RUN groupadd -g 1337 cassandra && \
    useradd -u 1337 -g cassandra -s /bin/sh -d /data cassandra && \
    chown -R cassandra:cassandra /data

# the source configuration (templates) need to be in /src/conf
# so the entry point can find them
COPY conf /src/conf

# install the entrypoint
# building it is just: go build
COPY cassandra-docker/cassandra-docker /bin/

# create symlinks for common commands (for docker exec)
RUN ln -s /bin/cassandra-docker /bin/cassandra && \
    ln -s /bin/cassandra-docker /bin/cqlsh     && \
    ln -s /bin/cassandra-docker /bin/nodetool  && \
    ln -s /bin/cassandra-docker /bin/cassandra-stress

# Storage Port, JMX, Thrift, CQL Native, OpsCenter Agent
# Left out: SSL
EXPOSE 7000 7199 9042 9160 
EXPOSE 22 8012
USER root
CMD start
