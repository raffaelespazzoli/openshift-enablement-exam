FROM centos

ENV TUNNEL_PORT 5555 \
    TUNNEL_DEV_NAME istio-mesh-tun

USER root
    
RUN curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo && \
    curl -Lo ./epel-release-latest-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \ 
    yum install -y ./epel-release-latest-7.noarch.rpm && \
    yum install -y socat iproute wireguard-tools
    
ADD tunnel.sh /tunnel.sh

EXPOSE 5555/udp

ENTRYPOINT ["/tunnel.sh"]    