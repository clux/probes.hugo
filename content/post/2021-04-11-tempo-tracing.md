---
title: Improving the observability of kube-rs controllers with Tempo, Loki and Prometheus
subtitle: Tempo, Loki, Prometheus
date: 2021-02-28
tags: ["rust", "kubernetes"]
categories: ["software"]
---

Instrumentation of rust software for Tempo, Loki, and Prometheus integration.

<!--more-->

> Eirik Albrigtsen is a core-maintainer on [kube-rs](https://github.com/clux/kube-rs), the rust kubernetes client library and async controller runtime, and an SRE at [TrueLayer](https://truelayer.com/). In this guest blog post, he explains how to instrument a rust controller for Loki, Tempo, and Prometheus.

## Background
Writing [kubernetes controllers](https://kubernetes.io/docs/concepts/architecture/controller/) can seem like a [daunting task](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-controllers). You need to deal with streaming kubernetes watch events that pertain to your object type as they come in, and based on those updates, you must manage your own custom resource based on declarative information. You must also do this in an error-relient, self-healing, and idempotent manner.

A lot of the patterns for writing controllers have converged a lot over the years with tools such as kubebuilder, operator framework (both in go) - and our own rust runtime crate [kube_runtime](https://docs.rs/kube-runtime/0.52.0/kube_runtime/controller/struct.Controller.html) - so they now end up looking very similar, with varying degrees of boilerplate. The difficulty of writing them has gone down, but if left uninstrumented, they can still be very difficult to debug.

By default, the standard kubernetes debugging pattern is `kubectl logs` with `grep`, and having to `kubectl port-forward` to the service if it presents an http api, and then interrogating that with `curl`. It takes a lot of context switching, and you are never sure whether you are going to get results.

So in this post, we will [continue from a tweet](https://twitter.com/sszynrae/status/1369405372222603264) to explain the current state of affairs of observability in rust using Prometheus (for metrics), Loki (for logs), and Tempo (for traces). We are going gloss over the infrastrucute setup here and use the [Grafana Agent](https://github.com/grafana/agent) to ship all the data to Grafana Cloud.

TODO: embed tweet?

## Tracing and Logs
Let's start with tracing and [tracing crate](https://crates.io/crates/tracing), as tracing interplays heavily with logs in rust.

The `tracing` crate provides instrumentation macros (like `trace!` and `error!`) that can be used at various layers in your codebase (often at IO points or places things can go wrong). They create [`Event`s](https://docs.rs/tracing/0.1.25/tracing/event/struct.Event.html) which exist within the context of a [span](https://docs.rs/tracing/0.1.25/tracing/span/index.html). These spans are what you ship. Typically, you ship them as part of complete traces to your opentelemetry collector, but you can also ship them as log lines to stdout. It all depends on the type of [subscribers](https://crates.io/crates/tracing-subscriber) you use.

### Subscriber Setup
The subscribers we are going to use, is going to be `tracing-subscriber`'s json [formatter](https://docs.rs/tracing-subscriber/0.2.17/tracing_subscriber/fmt/index.html), and [`tracing-opentelemetry`](https://crates.io/crates/tracing-opentelemetry). The latter will ship to Tempo, and the former to Loki. We can also use the standard `RUST_LOG` evar to filter out unwanted modules via an [`EnvFilter`](https://docs.rs/tracing-subscriber/0.2.17/tracing_subscriber/struct.EnvFilter.html). The total setup is:

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

Now, notice that we haven't defined our `otel_tracer` yet. That's because `tracing-opentelemetry` does not contain everything we need for opentelemetry; only enough to get it working with the `tracing` ecosystem. For the rest, we have to venture fully into [rust-opentelemetry land](https://github.com/open-telemetry/opentelemetry-rust) where we will pick the [opentelemetry-otlp crate](https://github.com/open-telemetry/opentelemetry-rust/tree/main/opentelemetry-otlp) for the grpc transport layer using [tonic](https://github.com/hyperium/tonic). Many other opentelemetry crates will work here such as the familiar Jaeger, but we going with the newest and shiniest - plus non-proprietary - setup here.

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
Using the `tracing` crate, we can wrap our async functions in spans, with a [`#[instrument]`](https://docs.rs/tracing/0.1.25/tracing/attr.instrument.html) function macro to create a new span at every invocation.

```rust
#[instrument(skip(ctx))]
async fn reconcile(foo: Foo, ctx: Context<Data>) -> Result<ReconcilerAction, Error> {
    // reconciler here
}
```

This will add our `foo` custom object to the span, but not the context, because that is merely a compile-time static object that's not very interesting to send and see in every trace.

As nothing else lower down towards `main` has instrumentation, each reconcile creates its own root span, and gets its own unique id. This instrumentation and this unique id is enough to get traces sent to `Tempo`, and we can verify this by checking the `tempo_receiver_accepted_spans` metric from the grafana agent.

However, we don't have any way of finding these spans yet. We need trace discoverability.

### Log Instrumentation.
For us to actually discover traces, we want to put our trace ids in logs. We modify our instrumentation to tell it we are going to record an extra field.

```rust
#[instrument(skip(ctx), fields(trace_id))]
async fn reconcile(foo: Foo, ctx: Context<Data>) -> Result<ReconcilerAction, Error> {
    Span::current().record("trace_id", &field::display(&get_trace_id()));
    // reconciler here
}
```

Where the `get_trace_id` function claws itself through the [opentelemetry root sdk crate](https://github.com/open-telemetry/opentelemetry-rust/tree/main/opentelemetry) as well as the tracing and otel layers:

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
To avoid manual steps of going from logs to traces, we add a [Derived Field](https://grafana.com/docs/grafana/latest/datasources/loki/#derived-fields) in our configured logs data source, to regex our json logs for our `traceId`, and turn that into an internal link for Grafana to step into our Tempo data source.

TODO: image of the click split.

Now, we have logs -> traces.

TODO: showcase the trace.

## Metrics
For the easy part; to avoid manually interrogating any apis, we let prometheus scrape our `/metrics` endpoint and expose that with the help of a [prometheus crate](https://github.com/tikv/rust-prometheus/).

What metrics do we want? Well, since we are writing a controller, the amount of reconciliations so we can watch for unusual spikes/drops in rates, and the time it took to reconcile, a histogram.

For the Histogram we are going to be using the new and experimental Exemplars feature requiring `prometheus` 2.26 or `agent` 0.14.
No rust prometheus crate has official support for them at the time of writing, but we have a PR on [tikv/rust-prometheus](https://github.com/tikv/rust-prometheus/pull/395) with at least a PoC that we will be using.

Let's focus on the histogram:

```rust
let reconcile_histogram = prometheus::register_histogram_vec!(
        "foo_controller_reconcile_duration_seconds",
        "The duration of reconcile to complete in seconds",
        &[],
        vec![0.01, 0.1, 0.25, 0.5, 1., 5., 15., 60.]
    )?;
```

A basic histogram, with buckets centered around a half-second (the expected reconciliation time).

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
The `Histogram::observe_with_exemplar` behaviour is the experimental one [subject to change](https://github.com/tikv/rust-prometheus/pull/395).

We can then visualize the p95 reconcile times with a standard `histogram_quantile` call in Grafana from Prometheus:

```
histogram_quantile(0.95, sum(rate(foo_controller_reconcile_duration_seconds_bucket[60m])) by (le))
```

TODO: image of histogram with exemplars once 2.26 is running in agent 0.14.

## Signals
We are now fully instrumented. So what's the general plan to track these signals now?

**First**, our metrics capture our known knows, it tells us __what__ is going wrong through our core signals, so we obviously put alerts on them. In our case it is that the reconciler is not working (perhaps a drop in the reconciliation rate), or is taking too long (a system problem, or perhaps merely outliers in histogram).

**Second**, our logs tell us __where__ the problem is occuring. Logs with error levels can typically point us to points in the code, but without much context or timing. If you don't know your core signals yet, a cheap alert on [error logs with LogQL](https://grafana.com/docs/loki/latest/alerting/#we-arent-using-metrics-yet) is a good start for known unknowns.

**Thirdly**, our traces, should provide the final bit of information about __why__ the problem is occuring. This `Api` call is perhaps taking too long, or we are maybe not dealing with an error case in a sufficiently idempotent manner, or perhaps the reconciler isn't even doing what it's supposed to be doing. Tracing is there to capture your unknown unknowns. The trace has timings, and the complete call-graph which you can extend outside the controller itself (if it is that complicated). It's the last line of information before you have to really dig into your code, so you have instrumented enough that you know what to do.

With these general directions we __hope__ that we will be able to easily tackle problems as they occur in the future. Granted, you deal with them to a lesser degree than in most other languages thanks to the many [memory safety](https://hacks.mozilla.org/2019/01/fearless-security-memory-safety/) and [security guarantees](https://msrc-blog.microsoft.com/2019/07/22/why-rust-for-safe-systems-programming/) from the language, but we still program for big distributed systems.

```
Should we encounter races,
we can step to the traces
via the metric and logs; the places,
that diagnosed the relevant cases,
to avoid availability disgraces,
or debugging in mazes.
```

## End
This is a young ecosystem, but the pieces are there. You can pin your versions as you upgrade, and have metrics, logs, traces, and multiple ways to move between them on Grafana.
For the complete example operator from this post, see [controller-rs](https://github.com/clux/controller-rs), which will quickly have more up to date code than this post. Hope this has been useful!

Note that compared to a full microservice cloud, this is a pretty simplified, toy demo. For the more complete microservice experience, keep an eye on future [TrueLayer Enineering blog posts](https://truelayer.com/blog/category/engineering), as we are looking to embrace Tempo in our Rust native, and heavily prometheus instrumented cloud.
