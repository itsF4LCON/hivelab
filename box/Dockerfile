FROM python:3.13-alpine AS build
WORKDIR /src
COPY gen gen
COPY challenges challenges
RUN python3 gen/build.py challenges /out

FROM alpine:3.24
COPY --from=build /out /opt/lab
COPY box /tmp/box
RUN cd /tmp/box && sh install.sh && rm -rf /tmp/box
WORKDIR /home/learner
CMD ["sleep", "infinity"]
