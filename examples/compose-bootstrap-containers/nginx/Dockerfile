FROM public.ecr.aws/docker/library/bash:5.0-alpine3.22

WORKDIR /root

COPY nginx /root/nginx
COPY main.sh /root/main.sh

ENTRYPOINT ["/root/main.sh"]