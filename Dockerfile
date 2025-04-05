FROM alpine:3.16

RUN apk add --no-cache bash curl jq python3 py-pip
RUN pip3 install python-tss-sdk

COPY ss_wrapper.py /ss_wrapper.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
