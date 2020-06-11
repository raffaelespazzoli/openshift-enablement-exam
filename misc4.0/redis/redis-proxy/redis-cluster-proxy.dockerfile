FROM ubi8
VOLUME /tmp-build
ENV workspace /tmp-build
COPY . $workspace
RUN cd $workspace && make install