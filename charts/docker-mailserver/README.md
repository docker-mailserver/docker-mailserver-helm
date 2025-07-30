# docker-mailserver Helm Chart

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
  - [Volume](#volume)
  - [ConfigMaps](#configmaps)
  - [Secrets](#secrets)
- [Values YAML](#values-yaml)
  - [Environment Variables](#environment-variables)
  - [Minimal Configuration](#minimal-configuration)
  - [Certificate](#certificate)
- [Ports](#ports)
- [Persistence](#persistence)
  - [Backing Storage](#backing-storage)
    - [Generic / All](#generic--all)
    - [NFS](#nfs)
- [Upgrading to Version 3.0.0](#upgrading-to-version-3)
- [Development](#development)
  - [Testing](#testing)

(Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go))

## Introduction

This chart deploys [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver) into a
Kubernetes cluster. docker-mailserver is a production-ready, fullstack mail server that supports SMTP, IMAP, LDAP, Anti-spam, Anti-virus, etc.). Just as importantly, it is designed to be simple to install and configure.

!!WARNING!! - Version 3.0.0 is not backwards compatible with previous versions. Please refer to the [upgrade](#upgrading-to-version-3) section for more information.

## Prerequisites

- [Helm](https://helm.sh)
- A [Kubernetes](https://kubernetes.io/releases/) cluster with persistent storage and access to email [ports](https://docker-mailserver.github.io/docker-mailserver/latest/config/security/understanding-the-ports/#overview-of-email-ports)
- A custom domain name (for example, example.com)
- Correctly configured [DNS](https://docker-mailserver.github.io/docker-mailserver/latest/usage/#minimal-dns-setup)
- [Cert Manager](https://cert-manager.io/docs/) or a similar tool to create and renew TLS certificates

## Getting Started

Setting up docker-mailserver requires generating a number of configuration [files](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/optional-config/). To make this easier, docker-mailserver includes a `setup` command that can generate these files.

To get started, first configure the firewall on your cluster to allow connections to ports 25 (imap), 465 (submissions), 587 (submission) and 993 (imaps) from any IP address.

If you have a LoadBalancer service routing traffic to your ingress controller, configure it to pass through the mail ports. 

Then, configure your ingress controller (or Gateway) to [pass through the email ports](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#using-the-proxy-protocol).

Next, manually create a TLS Certificate, setting `metadata.name` and `spec.secretName` to the same value.  Also set the fully-qualified domain name for your mail server in `spec.dnsNames` and `spec.issuerRef.name` to the name of an Issuer or ClusterIssuer, and `spec.issuerRef.kind` to `Issuer` or `ClusterIssuer`.
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate

metadata:
  name: mail-tls-certificate-rsa

spec:
  secretName: mail-tls-certificate-rsa
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  dnsNames: [mail.example.com]
  issuerRef:
    name: letsencrypt-production
    kind: Issuer
```
```console
kubectl apply -f certificate.yaml --namespace mail
```

Then add the helm repo:
```console
helm repo add docker-mailserver https://docker-mailserver.github.io/docker-mailserver-helm
```

Create a Helm values file. See the comments in [values.yaml](https://github.com/docker-mailserver/docker-mailserver-helm/blob/master/charts/docker-mailserver/values.yaml) to understand all the options, or create a minimal file like this (where `mail-tls-certificate-rsa` is the name of the certificate you previously created and `example.com` is the name of your domain):
```yaml
## Specify the name of a TLS secret that contains a certificate and private key for your email domain.
## See https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets
certificate: mail-tls-certificate-rsa

deployment:
  env:
    OVERRIDE_HOSTNAME: example.com       # You must OVERRIDE this!
```
If you're using the HAProxy ingress controller, configure it to send PROXY Protocol to the docker-mailserver ports, by appending this to your values file:
```yaml
service:
  annotations:
    haproxy.org/send-proxy-protocol: proxy-v2
```

Then install docker-mailserver using the values file:

```console
helm upgrade --install docker-mailserver docker-mailserver/docker-mailserver --namespace mail --create-namespace -f values.yaml
```

Next open a command prompt to the running container.

```console
kubectl exec -it --namespace mail deploy/docker-mailserver -- bash
```

And now create a new account for Postfix and Dovecot.

```console
kubectl exec -it --namespace mail deploy/docker-mailserver -- bash

setup email add user@example.com password
```

Alternatively you can do it one step like this:

```console
$kubectl exec -it --namespace mail deploy/docker-mailserver -- setup email add user@example.com password
```

Account information will be saved in a file `postfix-accounts.cf` in the container path:

```console
cat /tmp/docker-mailserver/postfix-accounts.cf
```

This path is [mapped](#persistence) to a Kubernetes Volume.

Optionally (but reccomended), create a [`NetworkPolicy`](https://kubernetes.io/docs/concepts/services-networking/network-policies/) that only allows appropriate pods to connect to the DMS pod.

## Configuration

Assuming you still have a command prompt [open](#getting-started) in the running container, run the setup command to see additional configuration options:

```console
setup
```

As you run various setup commands, additional files will be generated. At a minimum you will want to run:

```console
setup email add user@example.com password
setup config dkim keysize 2048 domain 'example.com'
```

These paths are stored to the container path `/tmp/docker-mailserver` which is [mapped](#persistence) to a Kubernetes Volume.

### Volume

Configuration files are stored on a Kubernetes [volume](#persistence) mounted at `/tmp/docker-mailserver` in the container. The PVC is named `mail-config`. You can of course add additional configuration files to the volume as needed.

### ConfigMaps

Its is also possible to use ConfigMaps to mount configuration files in the container. This is done by adding to  the `configFiles` key in a custom `values.yaml` file. For more information please see the [documentation](./values.yaml#L453) in values.yaml

### Secrets

Secrets can also be used to mount configuration files in the container. For example, dkim keys could be stored in a secret as opposed to a file in the `mail-config` volume. Once again, for more information please see the [documentation](./values.yaml#L610) in values.yaml

## Values YAML

In addition to the configuration files generated above, the `values.yaml` file contains a number of knobs for customizing the docker-mailserver installation. Please refer to the extensive comments in [values.yaml](./values.yaml) for additional information.

### Environment Variables

Included in the knobs are **many** environment variables which allow you to customize the behaviour of `docker-mailserver`. These environment variables are documented in the `docker-mailserver's` [configuration](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/) page. Note that `docker-mailserver` expects any true/false values to be set as numbers (1/0) rather than boolean values (true/false).

By default, the Chart enables `rspamd` and disables `opendkim`, `dmarc`, `policyd-spf` and `clamav`. This is the setup [recommended](https://docker-mailserver.github.io/docker-mailserver/latest/config/best-practices/dkim_dmarc_spf/) by the `docker-mailserver` project.

Once you have created your own values.yaml files, then redeploy the chart like this:

```console
helm upgrade docker-mailserver docker-mailserver --namespace mail --values <path_to_values.yaml>
```

You can also override individual configuration setting with `helm upgrade --set`, specifying each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```console
$helm upgrade docker-mailserver docker-mailserver --namespace mail --set pod.dockermailserver.image="your/image:1.0.0"
```

### Minimal Configuration

There are various settings in `values.yaml` that you must override.

| Parameter                            | Description                          | Default          |
| ------------------------------------ | ------------------------------------ | ---------------- |
| deployment.env.[OVERRIDE_HOSTNAME](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/#override_hostname) | The hostname to be presented on SMTP banners        | mail.example.com |
| `certificate`              | Name of a Kubernetes secret that stores TLS certificate for your mail domain |    |

### Certificate

You will need to setup a TLS certificate for your email domain. The easiest way to do this is use [cert-manager](https://cert-manager.io/).

Once you acquire a certificate, you will need to store it in a TLS secret in the docker-mailserver namespace. Once you have done that, update the values.yaml file like this:

```yaml
certificate: my-certificate-secret
```

The chart will then automatically copy the certificate and private key to the `/tmp/dms/custom-certs` director in the container and correctly set the `SSL_CERT_PATH` and `SSL_KEY_PATH` environment variables.

## Ports

If you are running on a bare-metal Kubernetes cluster, you will have to expose ports to the internet to receive and send emails. In addition, you need to make sure that `docker-mailserver` receives the correct client IP address so that spam filtering works.

This can get a bit complicated, as explained in the `docker-mailserver` [documentation][dms-docs::k8s::network-config].

One approach to preserving the client IP address is to [use the PROXY protocol][dms-docs::k8s::proxy-protocol].

The Helm chart supports the use of the proxy protocol via the `proxyProtocol` key. By default `proxyProtocol.enable` is true, and `trustedNetworks` is set to the private IP network ranges, as are typically used inside a cluster.

```yaml
proxyProtocol:
  enabled: true
  # List of sources (in CIDR format, space-separated) to permit PROXY protocol from
  trustedNetworks: "10.0.0.0/8 192.168.0.0/16 172.16.0.0/12"
```

Additionally, you will need to enable `proxyProtocol` for your loadbalancer.
- If you are using a cloud service they will most likely have documentation on how to do this for their loadbalancer.
- If you are using k3s then this is [currently impossible][k3s-klipperlb-pp] with the default components.

For security, you should narrow `trustedNetworks` to the actual range of IP addresses used by your ingress controller pods, and be certain to exclude any IP ranges gatewayed from IPv6 to v4 or vice versa.
Also note that any compromised container in the cluster could use the PROXY protocol to evade some security measures, so set a `NetworkPolicy` that only allows the appropriate pods to connect to the DMS pod.

Enabling the PROXY protocol will create an additional port for each protocol (by adding 10,000 to the standard port value) that is configured to understand the PROXY protocol. Thus:

| Protocol    | Regular Port | PROXY Protocol Port |
| ----------  |--------------|---------------------|
| smtp        | 25           | 12525               |
| submissions | 465          | 10465               |
| submission  | 587          | 10587               |
| imap        | 143          | 10143               |
| imaps       | 993          | 10993               |
| pop3        | 110          | 10110               |
| pop3s       | 995          | 10995               |

If you do not enable the PROXY protocol and your mail server is not exposed using a load-balancer service with an external traffic policy in "Local" mode, then all incoming mail traffic will look like it comes from a local Kubernetes cluster IP.

[dms-docs::k8s::network-config]: https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#exposing-your-mail-server-to-the-outside-world
[dms-docs::k8s::proxy-protocol]: https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#proxy-port-to-service-via-proxy-protocol
[k3s-klipperlb-pp]: https://github.com/docker-mailserver/docker-mailserver-helm/issues/176#issuecomment-3097915161

## Persistence

Docker-mailserver assumes there are [four](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/optional-config/#volumes) mounted volumes:

* mail-config
* mail-data
* mail-state
* mail-log

Therefore the chart requests four PersistentVolumeClaims under the `persistent_volume_claims` key. Each PVC can be set to an existing claim by setting the `persistent_volume_claims.<volume_name>.existing_claim` key or a new claims. To disable creation of a PVC, set `persistent_volume_claims.<volume_name>.enabled` to false. The default PVCs have the following characteristics:

| PVC Name    |  Default Size  | Mount            |  Description                         |
| ----------  | ------- | ----------------------- | -------------------------------------|
| mail-config |   1Mi   | /tmp/docker-mailserver  | Stores generated [configuration](https://docker-mailserver.github.io/docker-mailserver/latest/faq/#what-about-the-docker-datadmsconfig-directory) files |
| mail-data   |   10Gi  | /var/mail               | Stores emails                        |
| mail-state  |   1Gi   | /var/mail-state         | Stores [state](https://docker-mailserver.github.io/docker-mailserver/latest/faq/#what-about-the-docker-datadmsmail-state-directory) for mail services       |
| mail-log    |   1Gi   | /var/log/mail           | Stores log files                     |

The PVCs are mounted to `volumeMounts` via the `persistence` key. Each `volumeMount` must specify a volume name and mount path. It is also possbile to set a subpath via the `subPath` key.

Certain PV storage types may recommend or require additional external configuration. For more information, see the [Backing Storage](#backing-storage) section.

Extra volumes and volume mounts may be added using the `extraVolumes` and `extraVolumeMounts` keys.

### Backing Storage

This section contains configuration tweaks and quirks related to various PersistentVolume types. This section has been verified as of May 10, 2025. 

Common CSI driver-backed storage providers (such as various block storage providers) have not currently been tested while writing this section, but generic recommendations may still apply. 

#### Generic / All

The DMS container image used inside this chart currently does not forcibly harden the permissions of the recommended persistent volume mounts. It does change ownership for directories where different services need it. 

For any posix-backed storage it is recommended to adjust the Unix octal permissions of `0755` (u:rwx, g:rx, o:rx) if they are not already. Additionally, the primary file ACL for the directory should be set to `u::rwx,g::rx,o:rx` if subPaths are going to be used to map multiple volume mounts to a single PersistentVolume.

The DMS chart is currently not tested for replication, high availability. If subPaths are being used to merge multiple volume mount points to one PersistentVolume, this may potentially break being able to run with high availaility should it be actively tested in the future.

#### NFS

Docker Mailserver (the container) currently assumes that local posix-based storage (e.g. local or hostPath fs drivers) is used, and doesn't fully work with standard writable NFS shares (tested against NFS 4.2). Using fsGroup in the pod's securityContext won't help in this case as the container's root nor any other user seems to get it applied as a supplementary group. 

The current alternative is to apply the `no_root_squash` flag to any backing NFS shares, as well as ensure root ownership initially. If you do not know the caveats of [using the no_root_squash flag](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/4/html/security_guide/s2-server-nfs-noroot) and/or cannot properly mitigate the potential risk from using it, **consider not using NFS shares as backing storage at this time**. 

The reason `no_root_squash` is currently required is due to how DMS does initial fs setup. The container currently utilizes a lot of post-init directory creation and ownership changing done as root. 

DMS does not use techniques such as permissive initial directory creation that is locked down after various service users have made their respectively-owned subdirectories.

Quirks from the generic section also apply to NFS-backed PersistentVolumes.

## Upgrading to Version 5
Version 5.0 upgrades docker-mailserver to version 15. This version of the chart *does* include backwards incompatible changes

### PersistentVolumeClaims

Previously by default the Chart created four persistent volume claims and then mounted them to the container. This made it difficult for users that want to use just one Volume. Therefore the `persistence` key was spit into two keys:

* `persistent_volume_claims`
* `persistence`

This separate the creation of PVCs from mounting their associated volumes. If you previously overrode the creation of PVCs or their mount paths you will need to update your custom `values.yaml` file.

## Upgrading to Version 4
Version 4.0 upgrades docker-mailserver to version 14. There are no backwards incompatible changes in the chart.

## Upgrading to Version 3

Version 3.0 is not backwards compatible with previous versions. The biggest changes include:

- Usage of four PersistentVolumeClaims (PVCs) instead of one
- Usage of a PVC to store configuration files
- Rearrangement of keys in `values.yaml`
- Removal of RainLoop and HaProxy
- Removal of Cert Manager
- Enable rspamd by default

### PersistentVolumeClaims

Previously the Chart created a single PVC to store emails, logs and the state of various `docker-mailserver` components. Now the Chart creates four PVCs, as described in the [persistence](#persistence) section. One of the PVCs is `mail-config` which is used to store configuration files.

The addition of the `mail-config` PVC removes the requirement to use the `setup.sh` script and its dependency on Docker or Podman. Instead, you can directly deploy the chart to a Kubernetes cluster. For more information see the [configuration files](#configuration) section.

To upgrade you will need to copy data from the existing PersistentVolume (PV) to one of the new PVs:

| Original PV        | Path       | New PV     | Path  |
| -----------------  | -----------| -----------|-------|
| docker-mailserver  | mail-data  | mail-data  | /     |
| docker-mailserver  | mail-state | mail-state | /     |
| docker-mailserver  | mail-log   | mail-log   | /     |

### Rearrangement of keys

The location of a number of keys has changed in the chart. Please see `values.yaml` for the changed locations.

### Rspamd

The Chart now enables Rpsamd by default as recommened by the `docker-mailserver` documentation. You can disable this change by setting the environment variable `ENABLE_RSPAMD` to 0 and setting `ENABLE_OPENDKIM`, `ENABLE_OPENDMARC` and `ENABLE_POLICYD_SPF` to 1.

If you keep this change, you will need to generate new DKIM signing keys (see the [configuration](#configuration) section for more information). In addition, you may wish to enable the Rspamd ingress (see `rspamd.ingress.enabled`)

### TLS

Support for creating a TLS certificate using `cert-manager` has been removed. Instead, create a secret that contains a certificate *before* installing the chart and reference it via the `certificate` key. Of course you can use `cert-manager` to create this secret - it is just not part of this chart anymore.

### Proxy

Support for installing HaProxy with the Chart has been removed. Instead, generic support for the Proxy protocol has been [added](#proxy).

## Development

### Testing

[Unit tests](https://github.com/lrills/helm-unittest) are created for every chart template. Tests are applied to confirm expected behaviour and interaction between various configurations.

In addition to tests above, a "snapshot" test is created for each manifest file. This permits a final test per-manifest, which confirms that the generated manifest matches exactly the previous snapshot. If a template change is made, or legit value in values.yaml changes (i.e., the app version) this snapshot test will fail.

If you're comfortable with the changes to the saved snapshot, then regenerate the snapshots, by running the following from the root of the repo

```console
helm plugin install https://github.com/helm-unittest/helm-unittest.git
helm unittest -u charts/docker-mailserver
```
