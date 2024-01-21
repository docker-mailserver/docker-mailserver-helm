## Contents

- [Contents](#contents)
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Create Configuration Files](#create-configuration-files)
- [Values YAML](#values-yaml)
    - [Minimal Configuration](#minimal-configuration)
    - [Environmental Variables](#environmental-variables)
    - [Ports](#ports)
- [Development](#development)
  - [Testing](#testing)

(Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go))

## Introduction
This chart deploys [Docker
Mailserver](https://github.com/docker-mailserver/docker-mailserver) into a
Kubernetes cluster. 

docker-mailserver is a production-ready, fullstack mail server that supports SMTP, IMAP, LDAP, Anti-spam, Anti-virus, etc.). Just as importantly, it is designed to be simple to install and configure.

## Prerequisites
- [Helm](https://helm.sh)
- A [Kubernetes](https://kubernetes.io/releases/) cluster with persistent storage and access to email [ports](https://docker-mailserver.github.io/docker-mailserver/latest/config/security/understanding-the-ports/#overview-of-email-ports)
- A custom domain name (for example, example.com)
- Correctly configured [DNS](https://docker-mailserver.github.io/docker-mailserver/latest/usage/#minimal-dns-setup)

## Getting Started
Setting up docker-mailserver requires generating a number of configuration (files)[https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/optional-config/]. To make this easier, docker-mailserver includes a `setup` command that will generate these files.

To get started, first install docker-mailserver:

```console
helm upgrade --install docker-mailserver docker-mailserver --namespace mail --create-namespace
```

Next open a command prompt to the running container and create an email account.

```console
kubectl exec -it --namespace mail deploy/docker-mailserver -- bash

setup email add user@example.com password
```

This will create a new `postfix-accounts.cf` file:

```console
cat /tmp/docker-mailserver/postfix-accounts.cf
```

## Create Configuration Files
Assuming you still have a command prompt open in the running container, run the setup command to see additional configuration options:

```console
setup
```console

As you run various setup commands, additional files will be generated. At a minimum you will want to run:

```console
setup dovecot-master add user@example.com password
setup config dkim keysize 2048 domain 'example.com'
```

Configuration files are stored inside the container at `/tmp/docker-mailserver` which by default is mapped to a Kubernetes volume. You may of course add additional configuration files to the volume as needed.

For extensive configuration documentation, please refer to [configuration](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/).

## Values YAML
In addition to the configuration files generated above, the `values.yaml` file contains a number of knobs for customizing the docker-mailserver installation.

By default, the Chart enables `rspamd` and disables `opendkim`, `dmarc`, `policyd-spf` and `clamav`. This is the setup [recommended] (https://docker-mailserver.github.io/docker-mailserver/latest/config/best-practices/dkim_dmarc_spf/) by the docker-mailserver project.

It also provides a secondary mechanism for adding config files and secrets via the `configFiles` and `secrets` keys.

Once you have created your own values.yaml files, then redeploy the chart like this:

```console
helm upgrade docker-mailserver docker-mailserver --namespace mail --values <path_to_values.yaml>
```

You can also override individual configuration setting with `helm upgrade --set`, specifying each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```console
$ helm upgrade docker-mailserver docker-mailserver --namespace mail --set pod.dockermailserver.image="your/image:1.0.0"
```

### Minimal Configuration
There are various settings in `values.yaml` that you must override.

| Parameter                         | Description                                         | Default          |
| --------------------------------- | --------------------------------------------------- | ---------------- | 
| deployment.env.[OVERRIDE_HOSTNAME](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/#override_hostname) | The hostname to be presented on SMTP banners        | mail.example.com |
| certificate                       | Name of a Kubernetes secret that stores TLS certificate for mail domain | |

### Environmental Variables
There are **many** environment variables which allow you to customize the behaviour of docker-mailserver. The function of each variable is described at https://github.com/docker-mailserver/docker-mailserver#environment-variables

Every variable can be set using `values.yaml`, but note that docker-mailserver expects any true/false values to be set as binary numbers (1/0), rather than boolean (true/false). BadThings(tm) will happen if you try to pass an environment variable as "true" when [`start-mailserver.sh`](https://github.com/docker-mailserver/docker-mailserver/blob/master/target/start-mailserver.sh) is expecting a 1 or a 0!

### Certificate
You will need to setup a TLS certificate for your email domain. The easiest way to do this is use (cert-manager)[https://cert-manager.io/].

Once you acquire a certificate, you will need to store it in a TLS secret in the docker-mailserver namespace. Once you have done that, update the values.yaml file like this:

```yaml
certificate: my-certificate-secret
```
The chart will then automatically copy the certificate and private key to the `/tmp/dms/custom-certs` director in the container and set correctly set the `SSL_CERT_PATH` and `SSL_KEY_PATH` environment variables.

### Ports
If you are running a bare-metal Kubernetes cluster, you will need to expose ports to the internet to receive and send emails. In addition, you need to make sure that docker-mailserver receives the correct client IP address so that spam filtering works.

This can get a bit complicated, as explained in the docker-mailserver (documentation)[https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#exposing-your-mail-server-to-the-outside-world]. 

One approach is to use the PROXY protocol, which is also explained in the (documentation)[https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#proxy-port-to-service-via-proxy-protocol].

The Helm chart supports the use of the proxy protocol via the `proxy_protocol` key. To enable it set the `enable` key to true. You will also want to set the `trustedNetworks` key.

```yaml
proxy_protocol:
  enabled: true
  # List of sources (in CIDR format, space-separated) to permit PROXY protocol from
  trustedNetworks: "10.0.0.0/8 192.168.0.0/16 172.16.0.0/16"
```

Enabling the PROXY protocol will create a new port for each protocol by adding 10,000 to the standard port value. Thus:

| Protocol    |  Port   |  PROXY Port |
| ----------  | ------- | ----------- |
| submissions |   465   |    10465    |
| submission  |   587   |    10587    |
| imap        |   143   |    10143    |
| imaps       |   993   |    10993    |
| pop3        |   110   |    10110    |
| pop3s       |   995   |    10995    |

Note thes ports are NOT exposed outside of the Kubernetes cluster.

## Chart Values
The following table lists the configurable parameters of the docker-mailserver chart and their default values.

| Parameter        | Description                                              | Default                       |
|------------------|----------------------------------------------------------|-------------------------------|
| `image.name`                                      | The name of the container image to use                                                                                                                                               | `mailserver/docker-mailserver`                       |
| `image.tag`                                       | The image tag to use (You may prefer "latest" over "v6.1.0", for example)                                                                                                            | `release-v6.1.0`                                     |
| `demoMode.enabled`                                | Start the container with a demo "user@example.com" user (password is "password")                                                                                                     | `true`                                               |
| `haproxy.enabled`                                 | Support HAProxy PROXY protocol on SMTP, IMAP(S), and POP3(S) connections. Provides real source IP instead of load balancer IP                                                        | `false`                                              |
| `haproxy.trustedNetworks`                         | The IPs (*in space-separated CIDR format*) from which to trust inbound HAProxy-enabled connections                                                                                   | `"10.0.0.0/8 192.168.0.0/16 172.16.0.0/16"`          |
| `spfTestsDisabled`                                | Disable all SPF-related spam checks (*if source IP of inbound connections is a problem, and you're not using haproxy*)                                                               | `false`                                              |
| `domains`                                         | List of domains to be served                                                                                                                                                         | `[]`                                                 |
| `livenessTests.enabled`                           | Whether to execute liveness tests by running (arbitrary) commands in the docker-mailserver container. Useful to detect component failure (*i.e., clamd dies due to memory pressure*) | `true`                                               |
| `livenessTests.enabled`                           | Array of commands to execute in sequence, to determine container health. A non-zero exit of any command is considered a failure                                                      | `[ "clamscan /tmp/docker-mailserver/TrustedHosts" ]` |
| `pod.dockermailserver.hostNetwork`                | Whether the pod should be connected to the "host" network (a primitive solution to ingress NAT problem)                                                                              | `false`                                              |                                              |
| `pod.dockermailserver.hostPID`                    | Not really sure. TBD.                                                                                                                                                                | `None`                                               |                                           |
| `pod.dockermailserver.securityContext.privileged` | Whether to run this pod in "privileged" mode.                                                                                                                                        | `false`                                              |
| `service.type`                                    | What scope the service should be exposed in  (*LoadBalancer/NodePort/ClusterIP*)                                                                                                     | `NodePort`                                           |
| `service.loadBalancer.publicIp`                   | The public IP to assign to the service (*if LoadBalancer*) scope selected above                                                                                                      | `None`                                               |
| `service.loadBalancer.allowedIps`                 | The IPs allowed to access the sevice, in CIDR format (*if LoadBalancer*) scope selected above                                                                                        | `[ "0.0.0.0/0" ]`                                    |
| `service.nodeport.smtp`                           | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's SMTP port (25)                                                              | `30025`                                              |
| `service.nodeport.pop3`                           | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's POP3 port (110)                                                             | `30110`                                              |
| `service.nodeport.imap`                           | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's IMAP port (143)                                                             | `30143`                                              |
| `service.nodeport.smtps`                          | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's SMTPS port (465)                                                            | `30465`                                              |
| `service.nodeport.submission`                     | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's submission (*SMTP-over-TLS*) port (587)                                     | `30587`                                              |
| `service.nodeport.imaps`                          | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's IMAPS port (993)                                                            | `30993`                                              |
| `service.nodeport.pop3s`                          | The port exposed on the node the container is running on, which will be forwarded to docker-mailserver's IMAPS port (993)                                                            | `30995`                                              |
| `deployment.replicas`                             | How many instances of the container to deploy (*only 1 supported currently*)                                                                                                         | `1`                                                  |
| `resource.requests.cpu`                           | Initial share of CPU requested for dockermailserver                                                                                                                                  | `1`                                                  |
| `resource.requests.memory`                        | Initial share of RAM requested dockermailserver (*Initial testing showed clamd would fail due to memory pressure with less than 1.5GB                                               | `1536Mi`                                             |
| `resource.limits.cpu`                             | Maximum share of CPU available dockermailserver                                                                                                                                     | `2`                                                  |
| `resource.limits.memory`                          | Maximum share of RAM available dockermailserverv                                                                                                                                    | `2048Mi`                                             |
| `persistence.size`                                | How much space to provision for persistent storage                                                                                                                                   | `10Gi`                                               |
| `persistence.annotations`                         | Annotations to add to the persistent storage (*for example, to support [k8s-snapshots](https://github.com/miracle2k/k8s-snapshots)*)                                                 | `{}`                                                 |
| `ssl.issuer.name`                                 | The name of the cert-manager issuer expected to issue certs                                                                                                                          | `letsencrypt-staging`                                |
| `ssl.issuer.kind`                                 | Whether the issuer is namespaced (`Issuer`) on cluster-wide (`ClusterIssuer`)                                                                                                        | `ClusterIssuer`                                      |
| `ssl.dnsname`                                     | DNS domain used for DNS01 validation                                                                                                                                                 | `example.com`                                        |
| `ssl.dns01provider`                               | The cert-manager DNS01 provider (*more details [coming](https://github.com/funkypenguin/docker-mailserver/issues/6)*)                                                                | `cloudflare`                                         |
| `runtimeClassName`                                | Optionally, set the pod's [runtimeClass](https://kubernetes.io/docs/concepts/containers/runtime-class/)                                                                              | `""`                                                 |
| `priorityClassName`                               | Optionally, set the pod's [priorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)                                                          | `""`                                                 |

#### HA Proxy-Ingress Configuration

| Parameter                                       | Description                                                                                                                                       | Default                                   |
|-------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| `haproxy.deploy_chart`                  | Whether to deploy the HAProxy Ingress Controller (recomended)                                                                                     | `true`                                    |
| `haproxy.controller.kind`               | Whether your controller is a `DaemonSet` or a `Deployment`                                                                                        | `Deployment`                              |
| `haproxy.enableStaticPorts`             | Whether to enable ports 80 and 443 in addition to the TCP ports we're using below                                                                 | `false`                                   |
| `haproxy.tcp.25`                        | How to forward inbound TCP connections on port 25. Use syntax `<namespace>/<service name>:<target port>[<optional proxy protocol>]`               | `default/docker-mailserver:25::PROXY-V1`  |
| `haproxy.tcp.110`                       | How to forward inbound TCP connections on port 110. Use syntax described above.                                                                   | `default/docker-mailserver:25::PROXY-V1`  |
| `haproxy.tcp.143`                       | How to forward inbound TCP connections on port 143. Use syntax described above.                                                                   | `default/docker-mailserver:143::PROXY-V1` |
| `haproxy.tcp.465`                       | How to forward inbound TCP connections on port 465. Use syntax described above. PROXY protocol unsupported.                                       | `default/docker-mailserver:465`           |
| `haproxy.tcp.587`                       | How to forward inbound TCP connections on port 587. Use syntax described above. PROXY protocol unsupported.                                       | `default/docker-mailserver:587`           |
| `haproxy.tcp.993`                       | How to forward inbound TCP connections on port 993. Use syntax described above.                                                                   | `default/docker-mailserver:993::PROXY-V1` |
| `haproxy.tcp.995`                       | How to forward inbound TCP connections on port 995. Use syntax described above.                                                                   | `default/docker-mailserver:995::PROXY-V1` |
| `haproxy.service.externalTrafficPolicy` | Used to preserve source IP per [this doc](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-loadbalancer) | `Local`                                   |


#### postfix exporter metrics
* use dashboard :  https://grafana.com/grafana/dashboards/10013-postfix/

| Parameter                               | Description                                                                                   | Default                                                            |
|-----------------------------------------|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| `metrics.enabled`                       | enable postfix exporter metrics for prometheus                                                | `false`                                                            |
| `metrics.resource.requests.memory`      | Initial share of RAM for metrics sidecar                                                      | `256Mi`                                                            |
| `metrics.resource.limits.memory`        | Maximum share of RAM for metrics sidecar                                                      | `null`                                                             |
| `metrics.resource.limits.cpu`           | Maximum share of CPU available for metrics                                                    | `null`                                                             |
| `metrics.resource.requests.cpu`         | Iniyial share of CPU available per-pod                                                        | `null`                                                             |
| `metrics.image.name`                    | The name of the container image to use                                                        | `blackflysolutions/postfix-exporter@sha256`                       |
| `metrics.image.tag`                     | The image tag. If use named tag, then remove @sha256 from name, else put sha256 signed value  | `7ed7c0534112aff5b44757ae84a206bf659171631edfc325c3c1638d78e74f73` |
| `metrics.image.pullPolicy`              | pullPolicy                                                                                    | `IfNotPresent`                                                     |
| `metrics.serviceMonitor.enabled`        | generate serviceMonitor for metrics                                                           | `false`                                                            |
| `metrics.serviceMonitor.scrapeInterval` | default scrape interval                                                                       | `15s`                                                              |


## Development

### Testing

[Unit tests](https://github.com/lrills/helm-unittest) are created for every chart template. Tests are applied to confirm expected behaviour and interaction between various configurations
(ie haproxy mode and demo mode)

In addition to tests above, a "snapshot" test is created for each manifest file. This permits a final test per-manifest, which confirms that the generated manifest
matches exactly the previous snapshot. If a template change is made, or legit value in values.yaml changes (i.e., the app version) this snapshot test will fail.

If you're comfortable with the changes to the saved snapshot, then regenerate the snapshots, by running the following from the root of the repo

```console
$ helm plugin install https://github.com/lrills/helm-unittest
$ helm unittest helm-chart/docker-mailserver
```
