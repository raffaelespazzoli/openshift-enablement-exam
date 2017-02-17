FROM docker.io/ceph/daemon

RUN apt-get clean && \
    apt-get update -y && \
    apt-get install -y software-properties-common &&\
    echo "deb http://download.ceph.com/calamari/1.3.1/ubuntu/trusty/ trusty main" > /etc/apt/sources.list.d/calamari.list && \
    wget --quiet -O - http://download.ceph.com/keys/release.asc | apt-key add - && \
    add-apt-repository ppa:saltstack/salt2014-7 && \
    apt-get update && sudo apt-get install -y apache2 libapache2-mod-wsgi libcairo2 supervisor python-cairo libpq5 postgresql git && \
    apt-get install -y make pbuilder python-mock python-configobj python-support cdbs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN #git clone https://github.com/python-diamond/Diamond && \
    git clone https://github.com/ceph/Diamond && \
    cd Diamond && \
    make builddeb && \
    sudo dpkg -i build/diamond_*_all.deb && \
    apt-get clean && \
    apt-get update -y && \
    apt-get install -y salt-minion calamari-clients && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



#RUN apt-get clean && \
#    apt-get update -y && \
#    apt-get install -y python-dev && \
#    wget https://bootstrap.pypa.io/get-pip.py && \
#    python ./get-pip.py && \
#    pip install diamond && \
#    apt-get install -y salt-minion calamari-clients && \
#    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /
COPY calamari.conf /etc/salt/minion.d/
COPY diamond.conf /etc/diamond/

EXPOSE 80
