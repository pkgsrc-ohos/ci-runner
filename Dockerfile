FROM ghcr.io/hqzing/dockerharmony:latest

COPY build.sh ./

RUN ./build.sh && rm build.sh

CMD ["/bin/sh"]
