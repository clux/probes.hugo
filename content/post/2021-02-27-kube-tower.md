---
title: State of Kube 2021
subtitle: Tower, Hyper, Websockets.
date: 2021-02-27
tags: ["rust", "kubernetes"]
categories: ["software"]
---

After a quarter year of extensive improvements to [kube](https://github.com/clux/kube-rs), it's time to take a birds-eye view of what we got, and showcase some of the improvements we have. After all, it's been about [40 kube releases](https://github.com/clux/kube-rs/releases), one major version of [tokio](https://github.com/tokio-rs/tokio), and one [kubecon talk](https://www.youtube.com/watch?v=JmwnRcc2m2A) since my (very outdated) [last blog post](/post/2019-06-04-towards-a-generic-kube-client).

<!--more-->

## Crates
As of `0.50.X`, With modules and crates now delineated better, there's now multiple crates in the repository:

- **kube**: `Api` wrapper and `Client` + `Service` to codify protocol from `Config`
- **kube-derive**: proc-macro to derive `CustomResource` necessities from a struct
- **kube-runtime**: stream based controller runtime

Today, we will give a birds-eye view of the main interfaces in `kube`, and highlight its recent upgrades.

### kube::Api
Let's start with the basic feature you'd expect from a client library, the **[Api](https://docs.rs/kube/0.50.1/kube/struct.Api.html)**.

Its goals:

- allow interaction with any kubernetes resource
- stay compatible with any struct from [k8s-openapi](https://arnavion.github.io/k8s-openapi/v0.11.x/k8s_openapi/api/index.html)
- defer IO handling to the injected `Client`
- map `Client` output through `serde`


We make this generic by making **two assumptions about kubernetes**:

- all objects have metadata from [apimachinery/meta/types](https://github.com/kubernetes/apimachinery/blob/master/pkg/apis/meta/v1/types.go)
- `client-go` api generation is generics in disguise ([generated api](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed))

We won't cover this now, but you can watch the talk from [KubeCon2020: The Hidden Generics in Kubernetes' API](https://www.youtube.com/watch?v=JmwnRcc2m2A) (or [read the slides](https://clux.github.io/kubecon2020)).

The `Api` has been remarkably stable over the past two years, despite the internals being restructured heavily.

One improvement is to the ergonomics of patching, which now has a [typed Patch enum](https://docs.rs/kube/0.50.1/kube/api/enum.Patch.html) for selecting the patch type.

Despite full support, we always advocate for [server-side apply](https://kubernetes.io/blog/2020/04/01/kubernetes-1.18-feature-server-side-apply-beta-2/) everywhere these days as a lot of the awkward issues with local patching are generally [swept under the rug](https://github.com/kubernetes/kubernetes/issues/58414) with the clearly superior patch mode present in newer versions of kubernetes.

Here's how patching looks today:

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

The biggest `Api` improvement recently was the inclusion of the most complicated [subresources](https://github.com/clux/kube-rs/blob/master/kube/src/api/subresource.rs): `Api::exec` and `Api::attach`, and these actually uses a different protocol; [websockets](https://github.com/clux/kube-rs/issues/229).

Despite the complexities, these details have ended up being completely invisible to the user; you can hit [Api::exec](https://docs.rs/kube/0.50.1/kube/struct.Api.html#method.exec) like any other method, and you get the expected streams you can pipe from and pipe to:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">kube master: optional websocket support for exec/attach with <a href="https://twitter.com/tokio_rs?ref_src=twsrc%5Etfw">@tokio_rs</a> 1.0. Pipe streams to/from k8s pods. <a href="https://t.co/WhSFlPmm60">pic.twitter.com/WhSFlPmm60</a></p>&mdash; eirik ᐸ&#39;aᐳ (@sszynrae) <a href="https://twitter.com/sszynrae/status/1346122892707319810?ref_src=twsrc%5Etfw">January 4, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

### kube::Config
Not to be confused with the file in your home directory, our [Config](https://docs.rs/kube/0.50.1/kube/struct.Config.html) is actually just the relevant parameters we extract from the [kubeconfig file](https://docs.rs/kube/0.50.1/kube/config/struct.Kubeconfig.html) (or [cluster evars](https://docs.rs/kube/0.50.1/kube/struct.Config.html#method.from_cluster_env) when in-cluster), to help us create a client.

Unless there's something [we don't support](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3Aconfig), you generally won't even need to instantiate a `Config` because [Client::try_default](https://docs.rs/kube/0.50.1/kube/struct.Client.html#method.try_default) will try both variants.

### kube::Client
One of the most updated parts of `kube` this year, the [`Client`](https://docs.rs/kube/0.50.1/kube/struct.Client.html) has had a lot ripped out of it.
It is now entirely concerned with the __protocol__, and handles the serialization plumbing between the `Api` and the apiserver.

Most improvements are only really appreciable internally;

- __watch__ buffering is now using a [tokio codec](https://docs.rs/tokio-util/0.6.3/tokio_util/codec/index.html) to give us a much more readable [streaming event parser](https://docs.rs/kube/0.50.1/src/kube/client/mod.rs.html#204-272), while still returning a `TryStream<Item = Result<WatchEvent<T>>>` for `Api::watch`

- [Client::connect](https://docs.rs/kube/0.50.1/kube/struct.Client.html#method.connect) added to give a way to [hyper::upgrade](https://docs.rs/hyper/0.14.4/hyper/upgrade/index.html) an existing `http` connection ([wtf is upgrading?](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade)) to grant a streaming websocket connection from the existing http library. This is the secret sauce behind `Api::exec`.

Websockets is using `tokio-tungstenite`, a dependency so light-weight it's [only pulling](https://github.com/snapview/tokio-tungstenite/blob/master/Cargo.toml) in `tungstenite` without its [default-features](https://github.com/snapview/tungstenite-rs/blob/master/Cargo.toml). Crucially, this lets us avoid having yet another way to specify tls stacks and cause a corresponding explosion of features ([weak-dep-features](https://github.com/rust-lang/cargo/issues/8832) when).

Of course, supporting multiple protocols, tls stacks, and certs from kubeconfigs means that there's considerable tls handling in kube. Fortunately, we have mostly managed to confine it to [one cursed file](https://github.com/clux/kube-rs/blob/master/kube/src/service/tls.rs).

To end on a bang, the absolute biggest change in the `Client`:

> Every api call now goes through [Client::send](https://docs.rs/kube/0.50.1/src/kube/client/mod.rs.html#70-91)'s new Service, rather than `reqwest::send`, and we no longer depend on `reqwest`.

### kube::Service
The new [Service](https://docs.rs/kube/0.50.1/kube/struct.Service.html) - injected into the `Client` - is what actually deals with the processing of the request call to turn it into a response.

The `Service` can be constructed [from](https://docs.rs/kube/0.50.1/src/kube/service/mod.rs.html#66-126) a `Config`, so you can use a normal `Config` variant, or even [arbitrary input](https://docs.rs/kube/0.50.1/src/kube/config/mod.rs.html#51-62) to attempt to connect to a kubernetes cluster.

The `Service` creates a series of ordered [__layers__](https://docs.rs/kube/0.50.1/src/kube/service/mod.rs.html#71-125) to be executed for each request:

- Authentication (extracting tokens, possibly talking to auth providers)
- Url + header mapping from Config to http request
- Dealing with optional compression
- Send it to a `HyperClient` configured with a connector

The Connector for `hyper` deals with TLS stack selection + Timeouts + [proxying](https://github.com/clux/kube-rs/pull/438)

__Why this abstraction?__ Well, this isn't a special setup. This is merely abstracting around [tower::Service](https://docs.rs/tower-service/0.3.1/tower_service/trait.Service.html) which allows us to take and reuse `tower`'s [common service layers](https://docs.rs/tower/0.4.6/tower/#modules) as what effectively is __middleware__.

It's not hard to find benefits to standardising this abstraction: you can already [mock services out of the box](https://docs.rs/tower-test/0.4.0/tower_test/macro.assert_request_eq.html), but we do want a [better mocking setup](https://github.com/clux/kube-rs/issues/429#issuecomment-782957601) for a future testing helpers. None of our layers are public yet either.

For now, however, the end result is a more light-weight http client: `hyper` over `reqwest`, and without changing the core api boundaries (inserting `Service` between `Client` and `Config` will not affect the vast majority of users who use `Client::try_default` is the main start point).


## TODO: done


## TODO: kube-runtime
- mention removal of old [informers](/post/2019-04-29-rust-on-kubernetes)
- mention shutdown procedures


## Help

[Help](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22) always appreciated, even if you are just fixing [docs](https://docs.rs/kube/0.50.1/kube/) or [examples](https://github.com/clux/kube-rs/tree/master/examples)
[discussions](https://github.com/clux/kube-rs/discussions/422)


</🐂💈>