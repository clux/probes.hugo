---
title: Kubernetes operators in rust
subtitle: Writing light weight kube cloud services without go
date: 2019-04-29
tags: ["rust", "kubernetes"]
categories: ["software"]
---

When interacting with kubernetes it's generally been standard practice to use either [client-go](https://github.com/kubernetes/client-go) via go, or `kubectl` via shell.

While these are good, non-controversial choices, the advancement of client libraries, and smarter openapi bindings, combined with the generics and procedural macros of [rust-lang](https://www.rust-lang.org/), it's now quite possible to write fully fledged kube operators, using slim rust kube clients.

<!--more-->

## ..couldn't we have done this for ages?

Yes, but you'd have to set up all the watch machinery yourself and decide on a strategy for tracking the state.

The most painstaking part of this is dealing with watch events and `resourceVersion` properties directly (metadata returned by kube so you can keep calling `watch` without getting duplicate events). The events themselves are also newline delimited json, each a wrapped struct of what you want or an error type.

In `client-go`, a lot of this behaviour is wrapped up in something they call a [reflector](https://github.com/kubernetes/client-go/blob/master/tools/cache/reflector.go); a local cache responsible for updating itself and making sure its internal state reflects the state of `etcd` for the resource it's watching.

## The land of kube clients
First off, there are several good crates availble for kubernetes usage already. There's [k8s-openapi](https://github.com/Arnavion/k8s-openapi); the [increasingly clever](https://github.com/Arnavion/k8s-openapi/releases) set of rust bindings from the openapi spec, and [kubernetes](https://github.com/ynqa/kubernetes-rust), a is a very sensible convenience wrapper around `reqwest` + `k8s-openapi`, but it lacks quite a bit of error handling.

In a perfect world, we should all use `k8s-openapi` because it operates on the [sans-io principle](https://sans-io.readthedocs.io/) where you can just plug in any client. However, it [awkward when dealing with multiple values](https://github.com/Arnavion/k8s-openapi/blob/22d6a71d39104ec6147b7df94e4a0810ef898fbe/k8s-openapi-tests/src/lib.rs#L251-L306), and it [doesn't really support CRDs well yet](https://github.com/Arnavion/k8s-openapi/issues/39) and this is the main thing we wanted to use a kube client for.

So to tackle the CRD use case, we started out with an older version of the [kubernetes crate](https://github.com/ynqa/kubernetes-rust), before `k8s-openapi` was added as a dependency, and added error handling.

### Stealing Reflectors
Up until this point, there's been nothing special of this unnecessary fork of a kube client. But this is where reflectors come in. A `Reflector<T>` is a `Sync` + `Send` cache of some `T` with everything it needs to keep itself up to date:

```rust
#[derive(Clone)]
pub struct Reflector<T> where
  T: Debug + Clone + Named + DeserializeOwned
{
    data: Arc<RwLock<Cache<T>>>,
    client: APIClient,
    resource: ApiResource,
}
```

Here, `T` is meant to be the deserializable struct you own that represents the `.spec` portion of a CRD. This is wrapped up in several containers, first `Arc` + `RwLock` for thread safety (this data needs to be readable across workers in `actix` at the very least). The Reflector implements methods for the `write()` part of `RwLock` while consumers can `read()` to their heart's content.

The details of `Cache<T>` is a little more involved, but the state you ultimately get out of it is a `BTreeMap<String, T>` (aliased to `ResourceMap<T>`), where the key is `Named` how you like (probably using the `.name` key of the CRD).

By calling the provided `.poll()` methods as frequently as you'd like, you'll be able to read the up-to-date result Map from `.read()` and use the `Reflector<T>` as a cache.

### New crate: [`kube`](https://github.com/clux/kube-rs)
Once the `Reflector` was added and working in our fork, we decided to release it and see how useable it would be directly. The [kube](https://github.com/clux/kube-rs) crate is available at version `0.2.0` at the moment:

```toml
[dependencies]
kube = "0.2.0"
```

It should behave like the [kubernetes crate](https://github.com/ynqa/kubernetes-rust), but with more error handling, and various generic structs including reflectors.

## How would you actually use this?
Easy. You'll have a struct that defines your CRD:

```rust
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct FooResource {
  name: String,
  info: String,
}
```

Make it nameable for quick cache access:

```rust
impl Named for FooResource {
    // we want Foo identified by self.name in the cache
    fn name(&self) -> String {
        self.name.clone()
    }
}
```

create your state container with an instance of `Reflector<FooResource>`:

```rust
#[derive(Clone)]
pub struct State {
    foos: Reflector<FooResource>,
}
```

This is useable, but it won't update without you driving it. Let's make a nice constructor with some methods on it, since it'll be the interface you'll use from your application (and maybe you'll need more resources):

```rust
impl State {
    fn new(client: APIClient) -> Result<Self> {
        let namespace = env::var("NAMESPACE").unwrap_or("kube-system".into());
        let fooresource = ApiResource {
            group: "clux.dev".into(),
            resource: "foos".into(),
            namespace: namespace,
        };
        let foos = Reflector::new(client, fooresource)?;
        Ok(State { foos })
    }
    /// Internal poll for internal thread
    fn poll(&self) -> Result<()> {
        self.foos.poll()
    }
    /// Exposed refresh button for use by app
    pub fn refresh(&self) -> Result<()> {
        self.foos.refresh()
    }
    /// Exposed getter for read access to state for app
    pub fn foos(&self) -> Result<ResourceMap<FooResource>> {
        self.foos.read()
    }
}
```

with that set up, we can set up a simple system that runs the reflector, by making sure `Reflector::poll` is called continuously. Here we illustrate it by using a simple thread, that polls every `10` seconds (the same as kube's internal timeout for watch calls):

```rust
pub fn init(cfg: Configuration) -> Result<State> {
    let state = State::new(APIClient::new(cfg))?; // for app to read
    let state_clone = state.clone(); // clone for internal thread
    std::thread::spawn(move || {
        loop {
            std::thread::sleep(Duration::from_secs(10));
            match state_clone.poll() {
                Ok(_) => trace!("State refreshed"), // normal case
                Err(e) => {
                    // Can't recover: boot as much as kubernetes' backoff allows
                    error!("Failed to refesh cache '{}' - rebooting", e);
                    std::process::exit(1); // boot might fix it if network is failing
                }
            }
        }
    });
    Ok(state)
}
```

The `.poll()` call watch for events since the last internal `resourceVersion` and modify the `Cache` according to the `WatchEvent` returned by kubernetes. If for some reason we've desynced and the `resourceVersion` is too old (happens occasionally) then the `Reflector` will attempt to `refresh` the full state internally.

## Exposing it from actix

To wrap this up and use it in an `actix-web` application, create your `kube::config`, pass it to `init` to start and initialize your `State`. The state can be embedded straight onto `App::data`:

```rust
let kubecfg = match env::var("HOME").expect("have HOME dir").as_ref() {
    "/root" => kube::config::incluster_config(),
    _ => kube::config::load_kube_config(),
}.expect("Failed to load kube config");

let state = init(kubecfg).expect("Failed to initialize reflectors");
HttpServer::new(move || {
    App::new()
        .data(state.clone())
    })
    .bind("0.0.0.0:8080").expect("Can not bind to 0.0.0.0:8080")
    .start();
```


and from there, it's more or less following [actix examples](https://github.com/actix/examples) to read shared state in an http handler. The following will do:

```rust
fn get_foos(state: Data<State>, req: HttpRequest) -> HttpResponse {
    let foos = state.foos().unwrap();
    HttpResponse::Ok().json(foos)
}
```

## Full example

To see how it's all put together, you can browse the source for [operator-rs](https://github.com/clux/operator-rs); a full example that you can deploy directly onto kube with its [7MB docker image](https://github.com/clux/operator-rs/blob/master/Dockerfile) using only the [necessary access](https://github.com/clux/operator-rs/blob/master/yaml/deployment.yaml)

## Unresolved problems
This is a **very early stage happy path**. It works for custom resources very well, but any other resources can benefit from `k8s-openapi`.

### Overly generic abstractions?
The chosen abstraction in the `kube` client is one targetting an `ApiResource`, which maps cleanly onto a url of the form `/apis/{group}/v1/namespaces/{namespace}/{resource}`. A lot of the kube apis has that format, but this struct is probably too simplistic to be reuseable between all native structs:

```rust
pub struct ApiResource {
    /// API Resource name
    pub resource: String,
    /// API Group
    pub group: String,
    /// Namespace the resources reside
    pub namespace: String,
}
```

The `WatchEvent` enum might be more reuseable though:

```rust
#[serde(tag = "type", content = "object", rename_all = "UPPERCASE")]
pub enum WatchEvent<T> where
  T: Debug + Clone
{
    Added(T),
    Modified(T),
    Deleted(T),
    Error(ApiError),
}
```

This type of watch events seem to come out of many watch calls, but it's unclear how much this would be discarding of useful data in a more generic setting.

The same can be said about our simplistic `Metadata`, `Resource<T>`, and `ResourceList<T>`. These are defined in [resource.rs](https://github.com/clux/kube-rs/blob/be4ec4848a795556158602e9a6b7a996b6eed86e/src/api/resource.rs#L90-L133), and are currently unexported implementation details of `kube`. If they are useful, it's possible that these will be exposed in future versions of `kube`.

### Library Divergence?
What about the fact that there's now like 3 kube clients in rust land, all of which have the same config parsing and `x509` gunk?

Yeah, that's not great.

Maybe there's a need for an actual crate that deals with `Configuration` alone so that effort isn't duplicated.

It might also be good if we could factor this subjective view of what a reflector should do out of a `kube` library, but that style of `sans-io` based setup would require some restructuring.

### Yep. But it's midnight now
This is fresh. There's likely dragons just over the corner, as well as missing features not ported from existing clients. Suggestions and ideas are [welcome](https://github.com/clux/kube-rs/issues).

It's very comforting at laest, to be able to follow a rust-native setup for kube; relying on generics + serde to populate most of the Api and have something clean.

Next steps is for me is to to port [raftcat](https://github.com/Babylonpartners/shipcat/tree/master/raftcat) (a simple operator in babylon's cloud) to use this client. Hopefully, after some battle testing, this stuff can be less <img alt="kubernetes alpha client" style="display:inline" src="https://img.shields.io/badge/kubernetes%20client-alpha-green.svg?style=plastic&colorA=306CE8"/>
