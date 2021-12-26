---
title: Prometheus Stack Review
subtitle: Operating the stateful metrics system on kubernetes
date: 2021-12-19
tags: ["kubernetes", "observability"]
categories: ["software"]
---

As part of my work life in the past year, a chunk of my day-to-day life has consisted of maintaining a `prometheus` installation on top of a sizable kubernetes cluster. My original feeling was "this is not that bad with `kube-prometheus-stack`", but this sentiment has worsened somewhat with the realisation that more and more customizations and pieces were needed for large scale use. Half a year later (and 6 charts deep), I thought I'd collect my thoughts on the ecosystem - from an operational perspective - with a rough architecture overview post.

<!--more-->

## Disclaimer

1. Information here is based on my own learnings. Some details **might** be wrong. Please submit an [issue](https://github.com/clux/probes/issues) / [fix](https://github.com/clux/probes/edit/master/content/post/2021-12-20-prometheus-ecosystem.md) if you see anything glaring.
2. This post uses the classical open source prometheus setup with HA pairs and thanos on top. There are other promising (less mature) setups such as agent mode with remote write and cortex with grafana cloud.
3. We are following the most-standard `helm` approach and using charts directly (i.e. [avoiding direct use of jsonnet](https://github.com/prometheus-operator/kube-prometheus/))

## Architecture Overview

The TL;DR image. Open it up in a new tab, and cycle between if you want to read about specific components below.

[![prometheus ecosystem architecture diagram](/imgs/prometheus/ecosystem-miro.png)](/imgs/prometheus/ecosystem-miro.png)

TODO: add alertmanager to the diagram. relevant to operator
TODO: add extra exporters outside blue dashed line

## Part 1: kube-prometheus-stack

The blue dashed line represents a set of components that are commonly deployed together on kubernetes due to their interdependence, and these are managed together in the `[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) helm chart.

It is a [~3k LOC yaml values file](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml) with a further 71k LOC of yaml in that chart folder alone (what could go wrong), and it configures the following components:

- prometheus
- prometheus-operator
- alertmanager
- grafana
- kube-state-metrics
- node-exporter
- kubernetes specific scrapers/monitors
- monitoring mixins

24k lines here are just the absolutely massive prometheus-operator crds (that are [too big to apply now](https://github.com/prometheus-community/helm-charts/issues/1500)), but it's still an astonishing amount of yaml. Typically you'll end up with between 20-40k (excluding the crds) with a 100-500 line values file that you have to maintain <small>(you generally don't want your values file to be too large as it becomes harder and harder to keep track of the breaking changes in the stringly typed helm chart api)</small>.

### prometheus

The octopus at the base of our architecture. Prometheus scrapes the metrics endpoints of virtually every application you have, stores the data in a low-retention (a week or two) time series database that you can query. It also continually computes configured evaluation rules, and raises alerts on configured metric thresholds.

Prometheus is [over 9 years old](https://github.com/prometheus/prometheus/commit/734d28b515026ca9f429eba0a7d09954bceb6387), and has [graduate maturity in cncf](https://www.cncf.io/projects/prometheus/).

In theory, you can run it directly, tell it to scrape this-and-this and be done, but that will lead to downtime quickly. You are going to need at least two replicas for failover, and these are going to need mounted volumes to store their data. A [`StatefulSet`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) in kubernetes.

For configuration; how to scrape metrics can be tweaked through a mounted `scrape_config` (a [pretty complicated yaml DSL](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config) using `snake_case`). If you get the syntax wrong, prometheus hates your config and won't boot. `promtool` can validate it.

```yaml
relabel_configs:
- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
  action: keep
  regex: true
- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
  action: replace
  target_label: __scheme__
  regex: (https?)
- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
  action: replace
  target_label: __metrics_path__
  regex: (.+)
- source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
  action: replace
  target_label: __address__
  regex: ([^:]+)(?::\d+)?;(\d+)
  replacement: $1:$2
- action: labelmap
  regex: __meta_kubernetes_service_label_(.+)
```

This config is pretty awful to write and debug manually, so imo, you should probably avoid writing them yourself. Consider importing the [semi-standardised prometheus.io/scrape](https://github.com/prometheus-community/helm-charts/blob/970e1334813f90348b849f0a3850262a61f82797/charts/prometheus/values.yaml#L1516-L1759) ones from the main prometheus chart if you wish (they slightly clash with the root chart), but those should be it. It also needs you to inline secrets, so not great from a security perspective.

[Alerting and recording rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) are similarly configured and has same caveats (don't write them manually).

#### alertmanager

Alerting rules are generally end up getting raised through alertmanager.

This [surprisingly complicated](https://github.com/prometheus/alertmanager/blob/main/doc/arch.svg) component is responsible for notifying users when configured alerts are triggering. It contains deduplication mechanisms, a custom gossip UDP & TCP gossip protocol (that keeps breaking in HA setups - causing [duplicate alerts](https://github.com/prometheus/alertmanager/issues?q=is%3Aissue+duplicate+alerts)), and built in integrations with PagerDuty and Slack.

The slack/pagerduty integrations seem to handle deduplicating alerts themselves, so unless you are writing a custom webhook, you are probably fine. Your mileage may vary.

Alertmanager is [almost 9 years old](https://github.com/prometheus/alertmanager/commit/f86966a0e75dfa52f068d3a085753518bd4aea74), has [2 maintainers](https://github.com/prometheus/alertmanager/blob/main/MAINTAINERS.md), and is a sub-project of the prometheus org.


### prometheus-operator

A system that sits on top of prometheus, and extends the configuration with the [`monitoring.coreos.com` CRDs](https://github.com/prometheus-operator/prometheus-operator/tree/main/example/prometheus-operator-crd). This operator watches these CRDs, validates them via admission, converts them to a prometheus compatible format, and injects them into the running prometheus via a `config-reloader` sidecar on the prometheus statefulset. The main configuration CRDs are `PrometheusRule` and `ServiceMonitor` (some other monitors are also useful).

This setup avoids you taking down prometheus when you/users write new or invalid configuration or alerts. It also provides a mechanism for referencing kubernetes `Secret` objects (avoiding encryption needs on the base configuration), and it is generally considered the standard abstraction for configuring prometheus scraping.

A more debatable choice they have made, is to re-map the `scrape_config` keys to `camelCase` forcing you have to write half of your `ServiceMonitor` in `camelCase` (the keys), and the other half in `snake_case` (the values).

It is over 5 years old and still considered `beta`. It's [maintained by](https://github.com/prometheus-operator/prometheus-operator/blob/main/MAINTAINERS.md) people who are mostly disjoint from the the [prometheus maintainers](https://github.com/prometheus/prometheus/blob/main/MAINTAINERS.md). I.e. the take-away here is that it's not a first-class supported thing from prometheus, but everyone uses it.

### grafana

While prometheus does have sufficient querying functionality built in, it does not let you save these queries other than by a long-ass url, so realistically, users will want Grafana for dashboards (and that intense amount of panel customization).

The key strength of Grafana lies in how it becomes the one-stop shop for __querying & visualising anything__ when you buy into the ecosystem, and the huge amount of data sources they have available:

- [anything prometheus-like](https://grafana.com/docs/grafana/latest/datasources/prometheus/#prometheus-api)
- [cloudwatch](https://grafana.com/grafana/plugins/cloudwatch/)
- [honeycomb](https://grafana.com/blog/2021/08/30/introducing-the-honeycomb-plugin-for-grafana/)
- [tempo](https://grafana.com/docs/tempo/latest/getting-started/tempo-in-grafana/)
- [loki](https://grafana.com/docs/loki/latest/getting-started/grafana/)
- [elastic](https://grafana.com/blog/2021/03/04/why-were-partnering-with-elastic-to-build-the-elasticsearch-plugin-for-grafana/)
- [sentry](https://grafana.com/blog/2021/12/16/introducing-the-sentry-data-source-plugin-for-grafana/)

plus tons more that you are less likely to run into. Even if you only use if it against prometheus, it's still a very painless component to install with tons of benefits.
If you also manage to talk your company out of sending wheel-barrows full of money to elastic (in favour of elastic), you'll probably have an even better time.

Grafana is packaged as a small-ish [grafana-maintained helm chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana), which is pinned as [a subchart under kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/Chart.yaml#L45-L48).

### Governance & Grafana Labs

Grafana has a more [company driven governance model](https://github.com/grafana/grafana/blob/main/GOVERNANCE.md) - it's maintained almost exclusively by people employed by Grafana Labs - and the company is clearly optimizing for their own cloud offering of a parallel subset of this ecosystem; **Grafana Cloud**.

This obvious conflict of interest does pollute the purity of ecosystem somewhat, but at least they have financing to move at the great pace they are moving. Some examples of recent contributions:

- [loki](https://github.com/grafana/loki) - a serious elastic contender for logs that integrates with grafana
- [tempo](https://github.com/grafana/tempo) - a super clean tracing backend that integrates with grafana
- [well maintained helm charts for grafana/tempo/loki](https://github.com/grafana/helm-charts/tree/main/charts)
- [prometheus agent mode](https://grafana.com/blog/2021/11/16/why-we-created-a-prometheus-agent-mode-from-the-grafana-agent/)

Of course, there is the [feeling](https://github.com/grafana/grafana/issues/37679) that the non-open source variants of this functionality might be receiving less attention, but I can't really blame them for pursuing a sensible monetisation strategy.

I do hope [Grafana OnCall](https://grafana.com/blog/2021/11/09/announcing-grafana-oncall/) makes it out of their cloud as a better alternative to alertmanager though.

### Monitoring Mixins

A default grafana/prometheus-operator installation is not going to be very helpful without some dashboards that tell you about the state of your system(s).

Common patterns for alerts/dashboards/recording rules are encapsulated in a collection of mixins that are browsable on [monitoring.mixins.dev](https://monitoring.mixins.dev/).

The [`kubernetes-mixin`](https://monitoring.mixins.dev/kubernetes/) stands out in particular, providing excellent, drill-down-linked dashboards that are going to be vital for a large percentage of kubernetes related incidents.

In general, these provide a great starting point (albeit [sometimes](https://monitoring.mixins.dev/kubernetes/#kubernetes-system-kubelet) overly noisy - link to kubelet capacity) for most clusters. You likely have to re-configure some thresholds, and remove some of these alerts as you see fit you your production cluster, but the defaults are generally intelligent.

Unfortunately, there are [many operational challenges with these mixins](https://grafana.com/blog/2021/01/14/how-prometheus-monitoring-mixins-can-make-effective-observability-strategies-accessible-to-all/#the-challenges-with-mixins). `helm` is certainly not best suited to take full advantage of them as not every option is bubbled up to the charts, and these values flow through so many layers it's challenging to find where they truly originate, e.g. [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/templates/prometheus/rules-1.14/prometheus.yaml) <- [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus/blob/main/manifests/prometheusOperator-prometheusRule.yaml) <- [prometheus-operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/example/mixin/alerts.yaml).

This often caused me not wanting to bother with fixing it in the first place, which of course leads to the mixins not being as good as they could be. AFAIKT, your options are:

- forking the mixins you care about and opting out of upstream fixes
- post-template modifications of minor details with hacky solutions like sed/jq
- managing mixins out-of-band, aligning implicit default values with the charts, and customizing with jsonnet
- going through the drudgery of propagating mixin fixes through several repos

**Forking mixins** at least makes your yaml readable in your gitops repo so it feels like the least-worst option to me - particularly given how [awful](https://prometheus-operator.dev/docs/developing-prometheus-rules-and-grafana-dashboards/#adjustment) the other solutions are.

Regardless, it's another useful, but imperfect component that you are going to need.

### Metric Sources

If you just installed mixins, you will have missing values in all dashboards. This is because they presume the existence of standard metric sources inside a Kubernetes cluster.
We will run through these (briefly) as well. These components have in general behaved very well out of the box for me, so don't have too much to say about them.

#### node-exporter

The main external metric source. A [prometheus org maintained](https://github.com/prometheus/node_exporter) deamonset component that scrapes system level unix metrics. It mounts `/`, `/sys`, and `/proc` - with `hostPID` and `hostNetwork` enabled - to grab extensive information about each node.

It's a [sub-chart of kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/Chart.yaml#L41-L44), and it has a slew of [configurable exporters](https://github.com/prometheus/node_exporter#collectors), which can be [configured from the chart](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/prometheus-node-exporter/values.yaml#L150-L152), but the [defaults from kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/values.yaml#L1358-L1360) are likely good enough.

#### kube-state-metrics

The second stand-alone metric exporter for kubernetes. Maintained by kubernetes itself; [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) is a smaller component that generates metrics from what it sees the state of objects are from the apiserver. Uses [client-go reflectors](https://github.com/kubernetes/kube-state-metrics/blob/master/docs/design/metrics-store-performance-optimization.md#proposal) and uses the results of these long watches to populate metrics.

It's a conceptually pretty simple piece; an api -> metrics transformer, but kubernetes has a lot of apis, so definitely not something you want to write yourself.

In example terms; this component provides the base data for what you need to answer the questions like whether your: "Pod has been in an unhealthy state for >N minutes" / "Deployment has failed to complete its last rollout in N minutes" / "HorizontalPodAutoscaler has been maxed out for >N minutes". Stuff that you can figure out with `kubectl get -oyaml`.

KSM is deployed via an [in-tree subchart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) under [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/Chart.yaml#L37-L40).

You can configure what apis it provides metrics for [under collectors](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-state-metrics/values.yaml#L155-L183).

#### Label configuration

The only issue I've run into with KSM is that the metric labels are often insufficient for integration with existing standard alerting setups. This can be somewhat manipulated with [`metricLabelsAllowlist`](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-state-metrics/values.yaml#L135-L142), e.g.:

```yaml
    metricLabelsAllowlist:
    - "deployments=[app.kubernetes.io/name,app]"
    - "jobs=[app.kubernetes.io/name,app]"
    - "horizontalpodautoscalers=[app.kubernetes.io/name,app]"
```

 to inject more labels from the root object onto metrics. Annoyingly, these only get injected into an informational `_labels` metric, so you'd have to extend kubernetes-mixin with big joins to get these values exposed in the alert:

```diff
diff --git development/rules-kubernetes-apps.yaml development/rules-kubernetes-apps.yaml
index e36496e..988d6a6 100644
--- development/rules-kubernetes-apps.yaml
+++ development/rules-kubernetes-apps.yaml
@@ -220,7 +220,9 @@ spec:
-      expr: kube_job_spec_completions{job="kube-state-metrics", namespace=~".*"} - kube_job_status_succeeded{job="kube-state-metrics", namespace=~".*"}  > 0
+      expr: |-
+        (kube_job_spec_completions{job="kube-state-metrics", namespace=~".*"} -
+        kube_job_status_succeeded{job="kube-state-metrics", namespace=~".*"}  > 0) *
+        on(job_name) group_left(label_app_kubernetes_io_name)
+        sum by (namespace, job_name) (kube_job_labels{job="kube-state-metrics", label_app_kubernetes_io_name=~".+"})
```

#### kubernetes internal sources

For poking at the internals of kubernetes. The stack contains configurable scrapers for:

- kubelet
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- kube-proxy
- coreDns or kubeDns
- etcd

There is some sparse documentation for these under [kubernetes/cluster-admin](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/).

These are a little more optional, but you need the [kubelet metrics](https://github.com/kubernetes/kubernetes/tree/ea0764452222146c47ec826977f49d7001b0ea8c/pkg/kubelet/metrics/collectors) (via [cadvisor](https://github.com/google/cadvisor)), for the main kubernetes mixins, so make sure those are enabled.

The more superfluous ones that come with the kubeapiserver (particularly the [burnrate stuff](https://monitoring.mixins.dev/kubernetes/#kube-apiserver-burnraterules)) are particularly heavy evaluation rules (saw a ~6 cores reduction after removing them from one busy prometheus pair). Imo, you probably only need some of these if you are a cloud provider.

## Part 2: Thanos

Before this step, you can have a perfectly self-contained (one-chart) prometheus stack. Grafana's default data source would point at the prometheus `Service`, metrics would fade out after prometheus' retention period.

awkward no-official charts that are good enough. bitnami / thanos-charts (that maintainers don't have time to manage) / banzai(i think). all have problems.

## Part 3: Extras

The final set of components for external metric sources, and components necessary to take full advantage of Kubernetes' `HorizontalPodAutoscaler`.

### exporters

[tons of exporters availble](https://github.com/prometheus-community/helm-charts/tree/main/charts)

### metrics-server
even deployed natively on `k3d` by default

### prometheus-adapter
arcane, badly documented syntax, template hell.

