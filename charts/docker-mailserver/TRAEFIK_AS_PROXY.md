# Running behind Traefik as reverse proxy

Setup according to the [official guide](https://docker-mailserver.github.io/docker-mailserver/edge/examples/tutorials/mailserver-behind-proxy/) with traefik.

### `values.yaml`
```yaml
service:
  type: ClusterIP
  behind_proxy: true
  proxy_trusted_networks: "10.42.0.0/16"
```

Using the following [TCP Route](https://doc.traefik.io/traefik/routing/routers/#configuring-tcp-routers).

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: smtp
  namespace: mail
spec:
  entryPoints:
    - smtp
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mail-docker-mailserver
          namespace: mail
          port: 25
          proxyProtocol:
            version: 1
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: smtps
  namespace: mail
spec:
  entryPoints:
    - smtps
  tls:
    passthrough: true
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mail-docker-mailserver
          namespace: mail
          port: 465
          proxyProtocol:
            version: 1
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: imaps
  namespace: mail
spec:
  entryPoints:
    - imaps
  tls:
    passthrough: true
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mail-docker-mailserver
          namespace: mail
          port: 10993
          proxyProtocol:
            version: 2
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: submission
  namespace: mail
spec:
  entryPoints:
    - submission
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mail-docker-mailserver
          namespace: mail
          port: 587
          proxyProtocol:
            version: 1

```