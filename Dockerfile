FROM ghcr.io/hqzing/docker-mini-openharmony:latest

COPY build.sh ./

RUN ./build.sh && rm build.sh

CMD ["/bin/sh"]
