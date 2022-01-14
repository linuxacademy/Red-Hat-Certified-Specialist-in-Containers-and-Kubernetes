#!/bin/bash

#setup new cert
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /opt/registry/certs/domain.key -x509 -days 365 -out /opt/registry/certs/domain.crt -addext 'subjectAltName = DNS:localhost, DNS:sec-registry' -subj '/C=US/ST=Washington/L=Seattle/O=ACG/OU=Podman/CN=localhost'

#copy cert to /etc/pki
/usr/bin/cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
/usr/bin/update-ca-trust

#start the registry container on port 5000
podman run --name myregistry -p 5000:5000 -v /opt/registry/data:/var/lib/registry:z -v /opt/registry/auth:/auth:z -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v /opt/registry/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key -e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true -d docker.io/library/registry:latest

#start an insecure registry on port 5001
podman run --name myregistry-2 -p 5001:5000 -d docker.io/library/registry:latest
