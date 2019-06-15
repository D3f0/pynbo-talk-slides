FROM python:3.7

ENV ENV=prod UID=1000 USER=user PORT=8000
RUN groupadd -g ${UID} -r ${USER} \
    && useradd -u ${UID} -r -g ${USER} ${USER}

VOLUME /home/user/.local
