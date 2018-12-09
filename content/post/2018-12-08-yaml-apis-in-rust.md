---
title: Yaml APIs in rust for k8s
subtitle: How to build secure config management for kubernetes
date: 2018-12-08
tags: ["shipcat", "rust"]
categories: ["software"]
---

At [babylon health](https://www.babylonhealth.com/) we have a ton of microservices running on kubernetes that are, in turn, controlled by **hundreds of thousands of lines** of `yaml`.

So for our own sanity, we built [`shipcat`](https://github.com/Babylonpartners/shipcat) - a standardisation tool powered by [rust-lang](https://www.rust-lang.org/) and [serde](https://serde.rs/) - to control the declarative format and lifecycle of every microservice.

<!--more-->

..but first, a bit about the problem:

## Kubernetes API

Deploying services to kubernetes is no easy task. The abstraction might be _nice_ to an ops person, but it's a significant mental overhead for hundreds of engineers to have to understand. Try telling every engineer that they all need to hand craft their `yaml` for whatever they need of:

- `ConfigMap`
- `Secrets`
- `Deployment`
- `ReplicaSet`
- `Pod`
- `Service`
- `HorizontalPodAutoscaler`
- `ServiceAccount`
- `Role`
- `RoleBinding`
- `Ingress`

and you'll quickly realize that this does not scale. Not because your engineers can't handle it, but because if your engineers need to understand everything; you've not abstracted anything.

Not to mention that your platform would have no internal if everyone wrote these.

## Helm
One of the main attempts kubernetes has seen in this space is `helm`. A (primarily) client side templating system that lets you abstract away much of the above into `charts` (a collection of `yaml` go-templates) ready to be filled in with `helm values`; the more concise `yaml` that developers write directly.

Simplistic usage of `helm` would involve having a `chart` in a folder:

```aconf
.
└── base
    ├── Chart.yaml
    ├── templates
    │   ├── cronjobs.yaml
    │   ├── deploys.yaml
    │   ├── _helpers.tpl
    │   ├── hpa.yaml
    │   ├── NOTES.txt
    │   ├── rbac.yaml
    │   ├── secrets.yaml
    │   ├── serviceaccount.yaml
    │   └── service.yaml
    └── values.yaml
```

and calling it withyour substitute `values.yaml`:

```sh
helm template charts/base myapp -f myvalues.yaml | kubectl apply -lapp=myapp --prune -f -
```

which will garbage collect older kube resources with the `myapp` label, and start any necessary rolling upgrades in kubernetes.

### Drawbacks
Helm offers very little sanity what a `values.yaml` can contain. Here are things you can put in a helm values file that `helm` will be okay with:

- `Deployment` ports not matching `Service` ports (unreachable service)
- resource requests exceeding largest node (cannot schedule nor vertically auto scale)
- resource requests > resource limits (illogical)
- out of date secrets (generally causing crashes)
- missing health checks / `readinessProbe` (broken services can rollout)
- images and versions that does not exist (fails to install/upgrade)
- unmounted configmaps / badly mounted configmaps (annoying to debug until deployment works)

And that's just the low hanging fruit.

You'll need a bunch of security for ServiceAccounts, and some awkward lifecycle hacks into your templates like checksums of other pre-templated parts of the charts into other templates to make sure deployments trigger when secrets change:

```yaml
annotations:
  checksum/config: {{ include (print $.Template.BasePath "/cm.yaml") . | sha256sum }}
  checksum/secrets: {{ include (print $.Template.BasePath "/sec.yaml") . | sha256sum }}
```

Long story short, you have to be **really careful with helm**.

## Main idea: `shipcat`
What if if we could take the general idea that developers just write simplified _yaml manifests_ for their app and we just provide a bunch of security checking and validation on top of that? That's not hard to do, and by actually defining the structs in a tool, we can do tons of cross-referencing validation, as well as versioning our platform.

It also allows us to solve the secret problem. The tool can fetch the secrets from [vault](https://www.hashicorp.com/products/vault/) at deploy and validation time.

## Shipcat Manifest

```yaml
name: webapp
image: clux/webapp-rs
version: 0.2.0
env:
  DATABASE_URL: IN_VAULT
resources:
  requests:
    cpu: 100m
    memory: 100Mi
  limits:
    cpu: 300m
    memory: 300Mi
replicaCount: 2
health:
  uri: /health
httpPort: 8000
regions:
- minikube
metadata:
  contacts:
  - name: "Eirik"
    slack: "@clux"
  team: Doves
  repo: https://github.com/clux/webapp-rs
```
