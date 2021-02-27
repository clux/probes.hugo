---
title: State of Kube 2021
subtitle: CRDgen + Tower
date: 2021-02-27
tags: ["rust", "kubernetes"]
categories: ["software"]
---

After a quarter year of extensive improvements to [`kube`](https://github.com/clux/kube-rs), it's time to take a birds-eye view of what we got, and showcase some of the improvements we have. After all, it's been about [40 releases](https://github.com/clux/kube-rs/releases), and one [kubecon talk](https://www.youtube.com/watch?v=JmwnRcc2m2A) since __my__ [last (very outdated) blog post](/post/2019-06-04-towards-a-generic-kube-client) (and most of the drawbacks mentioned therein are no more).

<!--more-->

## Overview
As of `0.50.X`, With modules and crates now delineated better, there's now multiple crates in the repository:

- `kube`: generic `Api` wrapper, `Client` to use with it, `Service` to codify protocol, `Config` for kubeconfig
- `kube-derive`: proc-macro to derive `CustomResource` necessities from a struct
- `kube-runtime`: stream based controller runtime

Today, we will give a birds-eye view of the main interfaces in `kube`, and highlight its recent upgrades.

### Api
Let's start with the basic feature you'd expect from a client library, the [`Api`](https://docs.rs/kube/0.50.1/kube/struct.Api.html) (and perhaps our most documented struct).
It: lets you interact with any kubernetes resource, takes care of serialization/deserialisation, takes a client to perform io, is generic over the kubernetes resource, and is compatible with any struct from [k8s-openapi](https://arnavion.github.io/k8s-openapi/v0.11.x/k8s_openapi/api/index.html) where cases follow standard rust `snake_case`.

We have made this generic (despite the golang source not doing this in a generic manner) by taking advantage of two kubernetes assumptions:

- all objects use metadata from [apimachinery/meta/types.go](https://github.com/kubernetes/apimachinery/blob/master/pkg/apis/meta/v1/types.go)
- [resource apis follow enforced conventions that makes client api generation possible](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed)

We won't cover this again, but for a information on how this works, watch my talk from [KubeCon2020: The Hidden Generics in Kubernetes' API](https://www.youtube.com/watch?v=JmwnRcc2m2A) (or [read the slides](https://clux.github.io/kubecon2020)).

The more awkward issues around the various [`Patch`](https://docs.rs/kube/0.50.1/kube/api/enum.Patch.html) modes are now [generally avoided](https://github.com/kubernetes/kubernetes/issues/58414) with [server-side apply](https://kubernetes.io/blog/2020/04/01/kubernetes-1.18-feature-server-side-apply-beta-2/) - present in newer versions of kubernetes - so the general usage for updating objects tends to look like this:

```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let client = Client::try_default().await?;
    let foos: Api<Foo> = Api::namespaced(client, "default");

    let ss_apply = PatchParams::apply("kube").force()
    let patch = serde_json::json!({
        "apiVersion": "clux.dev/v1",
        "kind": "Foo",
        "spec": {
            "name": "foo",
            "replicas": 2
        }
    });
    foos.patch("myfoo", &ss_apply, &Patch::Apply(patch)).await?;
    Ok(())
}
```

The biggest `Api` improvement recently was the inclusion of the most complicated [subresources](https://github.com/clux/kube-rs/blob/master/kube/src/api/subresource.rs): `exec` and `attach`, which actually uses a different transport; [a websocket connection](https://github.com/clux/kube-rs/issues/229). Originally, this was done with `async_tungstenite`, and pulling in another client library (and a corresponding explosion of features), but with the [Client](#client) rewrite, all of this is now hugely simplified.

From a user point of view, you can now pipe to the websocket input stream, pipe from the websocket output stream, and write as complicated apps as you'd like:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">kube master: optional websocket support for exec/attach with <a href="https://twitter.com/tokio_rs?ref_src=twsrc%5Etfw">@tokio_rs</a> 1.0. Pipe streams to/from k8s pods. <a href="https://t.co/WhSFlPmm60">pic.twitter.com/WhSFlPmm60</a></p>&mdash; eirik ᐸ&#39;aᐳ (@sszynrae) <a href="https://twitter.com/sszynrae/status/1346122892707319810?ref_src=twsrc%5Etfw">January 4, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

### Config
Not to be confused with the file in your home directory, our [`Config`](https://docs.rs/kube/0.50.1/kube/struct.Config.html) is actually just the relevant parameters we extract from the [kubeconfig file](https://docs.rs/kube/0.50.1/kube/config/struct.Kubeconfig.html) (or [cluster evars](https://docs.rs/kube/0.50.1/kube/struct.Config.html#method.from_cluster_env) when in-cluster), to help us create a client.

Unless there's something we don't support ([open an issue](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3Aconfig)), you generally won't even need to instantiate a `Config` because [`Client::try_default`](https://docs.rs/kube/0.50.1/kube/struct.Client.html#method.try_default) will try both variants.

### Client
One of the most changed pieces of `kube` this year, the [`Client`](https://docs.rs/kube/0.50.1/kube/struct.Client.html) has had a lot ripped out of it.
It is now __entirely__ concerned with the protocol, and handles the serialization plumbing between the `Api` and the apiserver.

Many improvements are only appreciable from the inside, like how watch call buffering is now using a [tokio codec](https://docs.rs/tokio-util/0.6.3/tokio_util/codec/index.html) to give us a much more readable [`Client::request_events`](https://docs.rs/kube/0.50.1/src/kube/client/mod.rs.html#204-272) while still returning an `impl TryStream<Item = Result<WatchEvent<T>>>` for `Api::watch`.

There's also the new [`Client::connect`](https://docs.rs/kube/0.50.1/kube/struct.Client.html#method.connect), a way to [upgrade an existing `http` connection](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade) to grant a websocket connection without actually requiring an extra client library. This is used under the hood in the new [`Api::exec`](https://docs.rs/kube/0.50.1/kube/struct.Api.html#method.exec) and [`Api::attach`](https://docs.rs/kube/0.50.1/kube/api/struct.Api.html#method.attach).

Without doubt the biggest change, however, is that every api call now goes through [`Client::send`](https://docs.rs/kube/0.50.1/src/kube/client/mod.rs.html#70-91), rather than `reqwest::send`; because **we no longer depend on `reqwest`**. How? It's all thanks to [Service](#service):

### Service
The all new [`Service`](https://docs.rs/kube/0.50.1/src/kube/service/mod.rs.html#35-37) is what actually deals with the processing of the request call to turn it into a response.

The basic mechanisms is that it creates a series of __layers__ to be run through, in order, when running the request. These are:

- Authentication (extracting tokens from Config, possibly executing an oauth request via a provider)
- Url + header mapping from Config to http request
- Dealing with compression
- Building a Connector for `hyper` that deals with TLS (from `openssl` or `rustls`) and timeouts


It can be constructed from a `Config` via an [`impl TryFrom<Config>`](https://docs.rs/kube/0.50.1/src/kube/service/mod.rs.html#66-126), so you can use a normal `Config` variant, or even [arbitrary input](https://docs.rs/kube/0.50.1/src/kube/config/mod.rs.html#51-62) to attempt to connect to a kubernetes cluster.

It is a [`tower::Service`](https://docs.rs/tower-service/0.3.1/tower_service/trait.Service.html)... something

so it comes with ways to [mock out of the box](https://docs.rs/tower-test/0.4.0/tower_test/macro.assert_request_eq.html).
nb most layers not public yet.
WANT: [better mocking capabilities](https://github.com/clux/kube-rs/issues/429)


## TODO: done


## TODO: kube-runtime
- mention removal of old [informers](/post/2019-04-29-rust-on-kubernetes)
- mention shutdown procedures


## Help

[Help](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22) always appreciated, even if you are just fixing [docs](https://docs.rs/kube/0.50.1/kube/) or [examples](https://github.com/clux/kube-rs/tree/master/examples)


</🐂💈>
