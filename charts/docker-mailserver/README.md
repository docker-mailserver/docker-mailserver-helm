# docker-mailserver Heml Chart

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

## Getting Started

Setting up docker-mailserver requires generating a number of configuration [files](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/optional-config/). To make this easier, docker-mailserver includes a `setup` command that can generate these files.

To get started, first add the helm repo and install docker-mailserver:

```console
helm repo add docker-mailserver https://docker-mailserver.github.io/docker-mailserver-helm

helm upgrade --install docker-mailserver docker-mailserver/docker-mailserver --namespace mail --create-namespace
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

Its is also possible to use ConfigMaps to mount configuration files in the container. This is done by adding to  the `configFiles` key in a custom `values.yaml` file. For more information please see the [documentation](./values.yaml#L425) in values.yaml

### Secrets

Secrets can also be used to mount configuration files in the container. For example, dkim keys could be stored in a secret as opposed to a file in the `mail-config` volume. Once again, for more information please see the [documentation](./values.yaml#L600) in values.yaml

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

If you are running on a bare-metal Kubernetes cluster, you will have to expose ports to the internet to receive and send emails. In addition, you need to make sure that `docker-mailserver`` receives the correct client IP address so that spam filtering works.

This can get a bit complicated, as explained in the `docker-mailserver` [documentation](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#exposing-your-mail-server-to-the-outside-world).

One approach to preserving the client IP address is to use the PROXY protocol, which is explained in the [documentation](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/kubernetes/#proxy-port-to-service-via-proxy-protocol).

The Helm chart supports the use of the proxy protocol via the `proxyProtocol` key. To enable it set the `proxyProtocol.enable` key to true. You will also want to set the `trustedNetworks` key.

```yaml
proxyProtocol:
  enabled: true
  # List of sources (in CIDR format, space-separated) to permit PROXY protocol from
  trustedNetworks: "10.0.0.0/8 192.168.0.0/16 172.16.0.0/16"
```

Enabling the PROXY protocol will create an additional port for each protocol (by adding 10,000 to the standard port value) that is configured to understand the PROXY protocol. Thus:

| Protocol    |  Port   |  PROXY Port |
| ----------  | ------- | ----------- |
| submissions |   465   |    10465    |
| submission  |   587   |    10587    |
| imap        |   143   |    10143    |
| imaps       |   993   |    10993    |
| pop3        |   110   |    10110    |
| pop3s       |   995   |    10995    |

If you do not enable the PROXY protocol and your mail server is not exposed using a load-balancer service with an external traffic policy in "Local" mode, then all incoming mail traffic will look like it comes from a local Kubernetes cluster IP.

## Persistence

By default, the Chart creates four PersistentVolumeClaims. These are defined under the `persistence` key:

| PVC Name    |  Default Size  | Mount            |  Description                         |
| ----------  | ------- | ----------------------- | -------------------------------------|
| mail-config |   1Mi   | /tmp/docker-mailserver  | Stores generated [configuration](https://docker-mailserver.github.io/docker-mailserver/latest/faq/#what-about-the-docker-datadmsconfig-directory) files |
| mail-data   |   10Gi  | /var/mail               | Stores emails                        |
| mail-state  |   1Gi   | /var/mail-state         | Stores [state](https://docker-mailserver.github.io/docker-mailserver/latest/faq/#what-about-the-docker-datadmsmail-state-directory) for mail services       |
| mail-log    |   1Gi   | /var/log/mail           | Stores log files                     |

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
$helm plugin install https://github.com/lrills/helm-unittest
$helm unittest helm-chart/docker-mailserver
```
