FROM registry.access.redhat.com/rhel7

RUN yum install -y nc && yum clean all

ENV HOST=localhost
ENV PORT=9999

COPY *.sh /

EXPOSE $PORT

RUN chown 1001:0 /*.sh ; chmod +x /*.sh

USER 1001

CMD ["/run.sh"]