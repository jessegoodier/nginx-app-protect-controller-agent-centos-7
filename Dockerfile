# This is for demo purposes only
FROM centos:7.4.1708

# Download certificate and key from the customer portal (https://cs.nginx.com)
# and copy to the build context
COPY nginx-repo.* /etc/ssl/nginx/

# Install prerequisite packages
RUN yum -y install wget ca-certificates epel-release

# Add NGINX Plus repo to yum
RUN wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nginx-plus-7.repo
RUN wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/app-protect-signatures-7.repo
# Install NGINX App Protect
RUN yum -y install app-protect app-protect-attack-signatures app-protect-threat-campaigns \
    && yum clean all \
    && rm -rf /var/cache/yum 
#    && rm -rf /etc/ssl/nginx

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# NGINX Controller vars:
# e.g '1234567890'
ARG API_KEY 
ENV ENV_API_KEY=$API_KEY

# e.g https://<fqdn>:8443/1.4
ARG CONTROLLER_URL
ENV ENV_CONTROLLER_URL=$CONTROLLER_URL

# e.g True or False
ARG STORE_UUID=False
ENV ENV_STORE_UUID=$STORE_UUID

RUN yum -y install sudo

# Install Controller Agent
RUN curl -k -sS -L ${CONTROLLER_URL}/install/controller/ > install.sh \
  && sed -i 's/^assume_yes=""/assume_yes="-y"/' install.sh \
  && sh ./install.sh -y

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx-controller/agent.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log 

EXPOSE 80

STOPSIGNAL SIGTERM
COPY ./entrypoint3.sh /
ENTRYPOINT ["sh", "/entrypoint3.sh"]
