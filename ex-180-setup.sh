#!/bin/bash

#temp pass for setup, will be reset to match platform password
htpasswd -bBc /opt/registry/auth/htpasswd cloud_user badpass


#setup new cert
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /opt/registry/certs/domain.key -x509 -days 365 -out /opt/registry/certs/domain.crt -addext 'subjectAltName = DNS:localhost, DNS:registry-1' -subj '/C=US/ST=Washington/L=Seattle/O=ACG/OU=Podman/CN=localhost'

#copy cert to /etc/pki
/usr/bin/cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
/usr/bin/update-ca-trust

#start the registry container on port 5000
podman run --name myregistry -p 5000:5000 -v /opt/registry/data:/var/lib/registry:z -v /opt/registry/auth:/auth:z -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v /opt/registry/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key -e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true -d docker.io/library/registry:latest

#start an insecure registry on port 5001
podman run --name myregistry-2 -p 5001:5000 -d docker.io/library/registry:latest

#add alias to localhost in /etc/hosts file
sed -ie '1s/$/ registry-1 registry-2/' /etc/hosts

#create some directories and files in cloud_user home
mkdir -p /home/cloud_user/{web,docker,files}
echo 'If you are seeing this using curl then the Objective is complete!!!' > /home/cloud_user/web/index.html
wget https://github.com/linuxacademy/Red-Hat-Certified-Specialist-in-Containers-and-Kubernetes/raw/main/llama_cart.tar -P /home/cloud_user/files
wget https://github.com/linuxacademy/Red-Hat-Certified-Specialist-in-Containers-and-Kubernetes/raw/main/nginx_conf.zip -P /home/cloud_user/files
wget -O /home/cloud_user/docker/Dockerfile https://github.com/linuxacademy/Red-Hat-Certified-Specialist-in-Containers-and-Kubernetes/raw/main/Dockerfile_exam_lab
chown -R cloud_user:cloud_user /home/cloud_user/docker /home/cloud_user/files

#break SElinux for directory used in task 2
chcon -R -u unconfined_u -r object_r -t user_home_t /home/cloud_user/web

#login and push some starting images
echo badpass | podman login -u cloud_user --password-stdin registry-1:5000
podman pull docker.io/library/nginx
podman run -d --name=temp -p 8080:80 docker.io/library/nginx
podman exec temp bash -c "apt-get update && apt-get install -y vim"
podman exec temp bash -c "echo 'Replace Me' > /usr/share/nginx/html/index.html"
podman stop temp
podman commit temp registry-1:5000/nginx:useme
podman push nginx registry-1:5000/nginx:latest
podman push registry-1:5000/nginx:useme registry-1:5000/nginx:useme
podman stop temp
podman rm temp
podman pull docker.io/library/mysql
podman tag mysql registry-2:5001/llama-web-db:v1
podman push --tls-verify=false registry-2:5001/llama-web-db:v1 registry-2:5001/llama-web-db:v1
podman rmi nginx mysql registry-1:5000/nginx:useme registry-2:5001/llama-web-db:v1 
podman logout registry-1:5000

#create a pod for a task
su - cloud_user -c 'podman pod create --name=task-2 -p 8081:80'
