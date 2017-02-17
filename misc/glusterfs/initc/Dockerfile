FROM registry.access.redhat.com/rhgs3/rhgs-server-rhel7

COPY annotate-pod /usr/bin

RUN yum clean all && \
    yum-config-manager --enable "rhel-7-server-rpms" "rhel-7-server-ose-3.3-rpms" "rhel-7-server-optional-rpms" "rhel-7-server-extras-rpms" && \
    INSTALL_PKGS="atomic-openshift-clients" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    chmod a+x /usr/bin/annotate-pod