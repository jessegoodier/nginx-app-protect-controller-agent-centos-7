# This is for demo purposes only
FROM centos:7.4.1708


#multi-service container
#https://github.com/docker-library/docs/tree/master/centos#systemd-integration
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
  systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;
#VOLUME [ "/sys/fs/cgroup" ]

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
#  && rm -rf /etc/ssl/nginx
RUN systemctl enable nginx

# Forward request logs to Docker log collector
#RUN ln -sf /dev/stdout /var/log/nginx/access.log \
#    && ln -sf /dev/stderr /var/log/nginx/error.log

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

# Install Controller Agent
RUN yum -y install sudo
RUN curl -k -sS -L ${CONTROLLER_URL}/install/controller/ > install.sh 
RUN sed -i 's/^assume_yes=""/assume_yes="-y"/' /install.sh 
RUN sed -i 's/err_exit /echo \"there was an error\"\n#err_exit/g' /install.sh 
RUN sed -i 's/controller-agent start/controller-agent enable/' /install.sh
RUN API_KEY=${API_KEY} sh ./install.sh -y

# Forward request logs to Docker log collector
#RUN ln -sf /dev/stdout /var/log/nginx-controller/agent.log \
#  && ln -sf /dev/stderr /var/log/nginx/error.log 
copy deploy_cas.sh cas.tar.gz postinst /
RUN ./deploy_cas.sh
RUN sh postinst


RUN rm /etc/nginx/conf.d/default.conf
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/log-default.json /etc/nginx/ 

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/sbin/init"]
