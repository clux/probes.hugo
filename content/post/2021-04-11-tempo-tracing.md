---
title: Improving the observability of kube-rs controllers with Tempo and Loki
subtitle: Tempo, Loki, Prometheus
date: 2021-02-28
tags: ["rust", "kubernetes"]
categories: ["software"]
---

Instrumentation of rust software for Tempo and Loki integration.

<!--more-->

> Eirik Albrigtsen is a core-maintainer on [kube-rs](https://github.com/clux/kube-rs), the rust kubernetes client library and async controller runtime, and an SRE at [TrueLayer](https://truelayer.com/). In this guest blog post, he explains how to instrument a rust controller for Loki, Tempo, and Prometheus.

## Background
Writing [kubernetes controllers](https://kubernetes.io/docs/concepts/architecture/controller/) can seem like a [daunting task](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-controllers). You need to deal with streaming kubernetes watch events that pertain to your object type as they come in, and based on those updates, you must manage your own custom resource accordingly. You must do this in an error-relient, self-healing, and idempotent manner.

A lot of the patterns for writing controllers have converged a lot over the years with tools such as kubebuilder, operator framework (both in go), and our own rust runtime crate [kube_runtime](https://docs.rs/kube-runtime/0.52.0/kube_runtime/controller/struct.Controller.html), so they now end up looking very similar. The difficulty of writing them has gone down, but if left uninstrumented, they can be very difficult to debug.

By default, the standard kubernetes debugging pattern ends up being `kubectl logs` with `grep` or having to `kubectl port-forward` to the service if it presents an http api, and then interrogating that. It's not a particularly pleasant.

So in this post, we will [continue from a tweet](https://twitter.com/sszynrae/status/1369405372222603264) to explain the current state of affairs in rust with integration to Loki (for logs), Tempo (for traces), and Prometheus (for metrics).

TODO: embed tweet

## Tracing and Logs
Let's start with tracing and [tracing crate](https://crates.io/crates/tracing), as tracing interplays heavily with logs in rust.

The `tracing` crate provides instrumentation macros (like `trace!`) that are typically used everywhere necessary in your codebase (typically at IO points or places things can go wrong). They create [`Event`s](https://docs.rs/tracing/0.1.25/tracing/event/struct.Event.html) which exist within the context of a [span](https://docs.rs/tracing/0.1.25/tracing/span/index.html). These spans are what you ship. Typically, you ship them to your opentelemetry collector, but you can also ship them as log lines to stdout. It all depends on the type of [subscribers](https://crates.io/crates/tracing-subscriber) you use.

### Subscriber Setup
The subscribers we are going to use, is going to be `tracing-subscriber`'s json formatter, and [`tracing-opentelemetry`](https://crates.io/crates/tracing-opentelemetry). We will ship the latter to Tempo, and the former to Loki. We can also use the standard `RUST_LOG` evar to filter out spammy modules via an [`EnvFilter`](https://docs.rs/tracing-subscriber/0.2.17/tracing_subscriber/struct.EnvFilter.html). The total setup is:

```rust
let telemetry = tracing_opentelemetry::layer().with_tracer(otel_tracer);
let logger = tracing_subscriber::fmt::layer().json();

let filter_layer = EnvFilter::try_from_default_env()
    .or_else(|_| EnvFilter::try_new("info"))?;

// Register all subscribers
let collector = Registry::default()
    .with(telemetry)
    .with(logger)
    .with(filter_layer);

tracing::subscriber::set_global_default(collector)?;
```

Now, notice that we haven't defined our `otel_tracer` yet. That's because `tracing-opentelemetry` does not contain everything we need for opentelemetry; only enough to get it working with the `tracing` ecosystem. For the rest, we have to venture fully into [rust-opentelemetry land](https://github.com/open-telemetry/opentelemetry-rust) where we will pick the [opentelemetry-otlp crate](https://github.com/open-telemetry/opentelemetry-rust/tree/main/opentelemetry-otlp) (for the grpc tonic transport layer). Jaeger and many others will work well, but we going with the newest and shiniest non-proprietary setup here.

With this crate the `otel_tracer` can be created with:

```rust
let otel_tracer = opentelemetry_otlp::new_pipeline()
    .with_endpoint(&otlp_endpoint)
    .with_trace_config(opentelemetry::sdk::trace::config().with_resource(
        opentelemetry::sdk::Resource::new(vec![opentelemetry::KeyValue::new(
            "service.name",
            "foo-controller",
        )]),
    ))
    .with_tonic()
    .install_batch(opentelemetry::runtime::Tokio)?
```

A few non-defaults have been configured here:

- `service.name` resource (to get [tempo to show a service name](https://github.com/open-telemetry/opentelemetry-rust/issues/475) in span rather than `OTLPResourceNoAttributes`)
- `batch_exporter` with [tokio](https://github.com/tokio-rs/tokio) for better performance and to avoid [locking issues](https://github.com/open-telemetry/opentelemetry-rust/issues/473)

### Tracing Instrumentation
Using the `tracing` crate, we can wrap our async functions in spans, with a [`#[instrument]`](https://docs.rs/tracing/0.1.25/tracing/attr.instrument.html) function macro.

```rust
#[instrument(skip(ctx))]
async fn reconcile(foo: Foo, ctx: Context<Data>) -> Result<ReconcilerAction, Error> {
    // reconciler here
}
```

This will add our `foo` custom object to the span, but not the context, because that is merely a compile-time static object that's not very interesting to send and see in every trace.

This is enough to get traces sent to `Tempo`, and we can verify this by checking TODO: tempo accepted spans name.
However, this does not give us any trace id discoverability.

### Log Instrumentation.
For us to actually discover traces, we want to put our trace ids in logs. To do this, we modify our instrumentation to tell it we are going to record an extra field.

```rust
#[instrument(skip(ctx), fields(trace_id))]
async fn reconcile(foo: Foo, ctx: Context<Data>) -> Result<ReconcilerAction, Error> {
    Span::current().record("trace_id", &field::display(&get_trace_id()));
    // reconciler here
}
```

Not bad, but __how do we get the trace id__?

Currently this requires clawing it through the [opentelemetry root sdk crate](https://github.com/open-telemetry/opentelemetry-rust/tree/main/opentelemetry) as well as the tracing and otel layers:

```rust
pub fn get_trace_id() -> String {
    use opentelemetry::trace::TraceContextExt; // opentelemetry::Context -> opentelemetry::trace::Span
    use tracing_opentelemetry::OpenTelemetrySpanExt; // tracing::Span to opentelemetry::Context
    tracing::Span::current().context().span().span_context().trace_id().to_hex()
}
```

This feels perhaps a bit awkward at the moment, but using logs as trace discovery is also a pretty novel idea, so this is probably subject to change.

The final `toml` for tracing + opentelemetry dependencies thus becomes:

```toml
tracing = "0.1.25"
tracing-subscriber = { version = "0.2.17", features = ["json"] }
tracing-opentelemetry = "0.12.0"
opentelemetry = { version = "0.13.0", features = ["trace", "rt-tokio"] }
opentelemetry-otlp = { version = "0.6.0", features = ["tokio"] }
```

With this final setup, we can now see our `traceId` field in the logs, which we can copy-paste into tempo and step away from our application for a bit.

### Loki Configuration
TODO: derived fields
TODO: image for clicking


## Metrics
For the easy part; to avoid manually interrogating any apis, we let prometheus scrape our `/metrics` endpoint and expose that with the help of a [prometheus crate](https://github.com/tikv/rust-prometheus/).

What metrics do we want? Well, in this case, we are writing controllers, so amount of reconciliations, a counter, and the time it took to reconcile, a histogram with exemplars.

<small>Some contenders such as [metrics-rs](https://github.com/metrics-rs/metrics) exists. Neither have exemplar support at the time of writing, but we have a PR on [tikv/rust-prometheus](https://github.com/tikv/rust-prometheus/pull/395) for it.</small>

Let's focus on the histogram:

```rust
let reconcile_histogram = prometheus::register_histogram_vec!(
        "foo_controller_reconcile_duration_seconds",
        "The duration of reconcile to complete in seconds",
        &[],
        vec![0.01, 0.1, 0.25, 0.5, 1., 5., 15., 60.]
    )?;
```

A basic histogram, with buckets centered around a half-second.

To actually instrument this we need a start and end duration, and observe it at the end:

```rust
// start of reconciler
let start = Instant::now();

// .. do stuff here...

// end of reconciler
let duration = start.elapsed().as_millis() as f64 / 1000.0;
let ex = Exemplar::new_with_labels(duration, hashmap!{"trace_id" => trace_id});
reconcile_duration
    .with_label_values(&[])
    .observe_with_exemplar(duration, ex);
```

I.e. capture how many seconds it took, and then register that (via the prometheus client library) to the correct bucket.
The `Histogram::observe_with_exemplar` behaviour is [currently unmerged and subject to change](https://github.com/tikv/rust-prometheus/pull/395), but it is usable.

We can then visualize the p95 reconcile times with a standard `histogram_quantile` call in Grafana from Prometheus:

```
histogram_quantile(0.95, sum(rate(foo_controller_reconcile_duration_seconds_bucket[60m])) by (le))
```

TODO: image of histogram with exemplars once 2.26 is running in agent 0.14.
