FROM centos

ENV TUNNEL_PORT 5555 \
    TUNNEL_DEV_NAME istio-mesh-tun

USER root
    
RUN yum install -y socat iproute
    
ADD tunnel.sh /tunnel.sh

EXPOSE 5555/udp

ENTRYPOINT ["/tunnel.sh"]    