FROM registry.access.redhat.com/rhel7

USER root
RUN yum install -y nc && yum clean all

ENV HOST=localhost
ENV PORT=9999

COPY *.sh /

EXPOSE 9999

RUN useradd -u 1001 -r -g 0 -s /sbin/nologin -c "Default Application User" default
RUN chown 1001:0 /*.sh ; chmod +x /*.sh

USER 1001

CMD ["/run.sh"]