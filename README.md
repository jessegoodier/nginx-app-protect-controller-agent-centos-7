This is just a test with NGINX App Protect running in a centos 7 container with controller agent.

documentation on controller agent:
<https://github.com/nginxinc/docker-nginx-controller>

## Usage

### build (use your api key)

docker build --build-arg CONTROLLER_URL=https://labcontroller.nginx.rocks:8443/1.4 --build-arg API_KEY='25f2d7a9b767117d7e68ca8b3fab1c7f' --tag=nginx-app-protect-with-controller-agent .

### run

docker run --rm -dit --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name=nginx-ctrl-nap-test --hostname=nginx-ctrl-nap-test nginx-app-protect-with-controller-agent
