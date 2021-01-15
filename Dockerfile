FROM mcr.microsoft.com/azure-cli:2.9.1

ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION

WORKDIR /usr/src

COPY untag.sh .
RUN chmod +x untag.sh

ENTRYPOINT ["bash", "/usr/src/untag.sh"]
