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

Deploying services to kubernetes is no easy task. The abstraction might be _nice_ once you've wrapped your head around it, but it's a significant mental overhead for hundreds of engineers to have to understand. Try telling every engineer that they all need to hand craft their `yaml` for whatever they need of:

- `ConfigMap`
- `Secrets`
- `Deployment` / `ReplicaSet` / `Pod`
- `Service`
- `HorizontalPodAutoscaler`
- `ServiceAccount`
- `Role`
- `RoleBinding`
- `Ingress`

and you'll quickly realize that this does not scale. Not because your engineers can't handle it, but because if your engineers need to understand everything; you've not abstracted anything.

Not to mention that your platform would have no internal consistency if everyone handcrafted these.

## Helm
One of the main attempts kubernetes has seen in this space is `helm`. A (primarily) client side templating system that lets you abstract away much of the above into `charts` (a collection of `yaml` go templates) ready to be filled in with `helm values`; the more concise `yaml` that developers write directly.

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
Even though you can avoid a lot of the common errors by re-using charts across apps, there's still very little sanity on what helm values can contain. Here are some values you can pass to a helm chart that will be accepted:

- misspelled optional values (silently ignored)
- resource requests exceeding largest node (cannot schedule nor vertically auto scale)
- resource requests > resource limits (illogical)
- out of date secrets (generally causing crashes)
- missing health checks / `readinessProbe` (broken services can rollout)
- images and versions that does not exist (fails to install/upgrade)

And that's once you've gotten over how frurstrating it can be to write helm templates in the first place.

But missing validation is only one annoyance. The other is that this is a really _accidental abstraction_: these files now effectively describe your service, but you have no useful logic around it (nor validation on how it should be), and you do not have a process to evolve these manifests along with your charts easily once they are in the wild.

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
