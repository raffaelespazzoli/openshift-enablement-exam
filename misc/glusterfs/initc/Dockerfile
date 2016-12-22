FROM registry.access.redhat.com/openshift3/ose

COPY annotate-pod /usr/bin

RUN chmod a+x /usr/bin/annotate-pod

CMD ["bash","/usr/bin/annotate-pod"]