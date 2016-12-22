FROM rhgs3/rhgs-server-rhel7

COPY annotate-pod /usr/bin

RUN yum clean all && \
    INSTALL_PKGS="atomic-openshift-clients" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    chmod a+x /usr/bin/annotate-pod