---
title: Kubernetes controllers in rust
subtitle: Light weight foundations for a generic kubernetes interface
date: 2019-05-15
tags: ["rust", "kubernetes"]
categories: ["software"]
---

It's been about a months since we released [`kube`](https://github.com/clux/kube-rs), a client library for kubernetes in rust and there is a [blog post at the time explaining the initial setup](./2019-04-29-rust-on-kubernetes.md). At that time though, everything was experimental: would the generic setup work with native objects? How far would it extend? Would it be a parsing only benefit? Querying? Event handling? Surely, the Reflector idea would hit a wall with that?

With the last `0.7.0` release, it's becoming clear that the setup extends quite far.

<!--more-->

## Stepping back
The surprising reason this library even works at all, is the surprising amoutn of homebrew generics present in the kubernetes API. We discovered this

Controllers in go can be slightly awkward to write because of all the indirection; (shared informers -> blah)

I'd recommend listening to Kris Nova's 2019 FOSDEM talk on [the internal clusterfuck of kubernetes]
(https://fosdem.org/2019/schedule/event/kubernetesclusterfuck/).

## Parsing
While the generated openapi bindings provide a lot of utility, they miss the clear assumptions hidden in the api itself. Just browse some of the million different list structs (1,2,3,...), parameter structs (1,2,3,...), and you can quickly see that these all basically have the same fields.

Pretty much any non-error object retrieved from the API of kubernetes can in fact be deserialized into this struct:

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct Resource<T, U> where T: Clone, U: Clone
{
    #[serde(default, flatten, skip_serializing_if = "Option::is_none")]
    pub typemeta: Option<TypeMeta>,
    pub metadata: Metadata,
    pub spec: T,
    pub status: U,
}
```

with the caveat that the status struct can be missing, which is fine. That's equivalent to the special case where `type U = Option<EmptyStruct>`, at least as far as serde's concerned.

We can also fetch the result of any list call into the following:

```rust
#[derive(Deserialize)]
pub struct ResourceList<T> where
  T: Clone
{
    pub metadata: Metadata,
    #[serde(bound(deserialize = "Vec<T>: Deserialize<'de>"))]
    pub items: Vec<T>,
}
```

Finally, watch calls return newline delimited json, where each of these lines can be parsed into this enum:

```rust
#[derive(Deserialize, Serialize, Clone)]
#[serde(tag = "type", content = "object", rename_all = "UPPERCASE")]
pub enum WatchEvent<T, U> where
  T: Clone, U: Clone
{
    Added(Resource<T, U>),
    Modified(Resource<T, U>),
    Deleted(Resource<T, U>),
    Error(ApiError),
}
```

These three generic structs can help hide a lot of of kubernetes' API duplication and are the key foundations for a generic kube api, atop which we can build higher level abstractions.

## Querying
With the structs and consequently the derived parsing logic ready, we can generate the api structure for each `Resource`. For this, we need some more information about where the resource lives:

```rust
#[derive(Clone, Debug)]
pub struct ApiResource {
    /// API Resource name
    pub resource: String,
    /// API Group
    pub group: String,
    /// Namespace the resources reside
    pub namespace: Option<String>,
    /// API version of the resource
    pub version: String,
    /// Name of the api prefix (api or apis typically)
    pub prefix: String,
}
```

This struct is responsible for creating the base url for the api resource internally. You don't have to remember all these values yourself, we have an enum of native types: `ResourceType` which implements `Into<ApiResource> for Resource`:

```rust
let manual_deploys = ApiResource {
    group: "apps".into(),
    resource: "deployments".into(),
    version: "v1".into(),
    namespace: ns,
    prefix: "apis".into(),
}
assert_eq!(ResourceType::v1Deploys(Some(ns)).into(), manual_deploys);
```

`ApiResource` implements the raw `GET`, `WATCH` operations on the resource necessary for the abstractions for us. You can see the [documentation for ApiResource] if you are interested. These operations generally support the following query parameters:

```rust
#[derive(Default, Clone)]
pub struct GetParams {
    pub field_selector: Option<String>,
    pub include_uninitialized: bool,
    pub label_selector: Option<String>,
    pub timeout: Option<u32>
}
```

You can think of `ApiResource` and `GetParams` together implement `Into<Url>`, with a little hand-waving depending on whether you are listing, getting a single resource, a full list of resources etc.

TODO: patch is weird. Put is simple. No special args except na
TODO: individual verbs.

## Higher level abstractions
You can use `ApiResource` and `GetParams` to talk to the kube api directly, but for the common controller use-cases, you'd be better of using one of the higher level interfaces.

### Informers
An informer in is just something that informs you of events. In go, you attach event handler functions to it. In rust, we just pattern match the `WatchEvent` enum directly for a similar effect:

```rust
fn handle_nodes(client: &APIClient, ev: WatchEvent<NodeSpec, NodeStatus>) -> Result<(), failure::Error> {
    match ev {
        WatchEvent::Added(r) => {},
        WatchEvent::Modified(r) => {},
        WatchEvent::Deleted(r) => {},
        WatchEvent::Error(e) => {}
    }
    Ok(())
}
```

Where the `r` being pattern-matched here is a `Resource<NodeSpec, NodeStatus>`, i.e. it'll be our generic version of `k8s_openapi::api::core::v1::Node`. See the various [informer examples](https://github.com/clux/kube-rs/blob/master/examples/) for ideas on how to use the data.

To actually initialize and drive a node informer (`: Informer<NodeSpec, NodeStatus>`), you can do something like this:

```rust
fn main() -> Result<(), failure::Error> {
    let config = config::load_kube_config().expect("failed to load kubeconfig");
    let client = APIClient::new(config);

    let nodes = ResourceType::Nodes;
    let inf = Informer::new(client.clone(), nodes.into())
        .labels("role=worker")
        .init()?;

    loop {
        inf.poll()?;

        while let Some(event) = inf.pop() {
            handle_nodes(&client, event)?;
        }
    }
}
```

If you need a separate threads, like one to handle polling and events, and another set of threads to support a tokio/actix runtime, then you can give out a `.clone()` of an `Informer` to the runtime, for instance as actix state with: `App::with_state(informer.clone())`, and you can poll your own clone separately. The `Informer` synchronizes its internal event cache and current `resourceVersion` after polling and popping events. See [controller-rs](https://github.com/clux/controller-rs) for a full fledged actix controller example that deploys with a [7MB alpine image](https://github.com/clux/controller-rs/blob/master/Dockerfile).

resolved shit:
- parameters exposed generically
- native objects exposed generically
- interspersing kube api calls ez now
- informers

unresolved:
- reflectors on top of informers
- new terminology?

resources:
- https://engineering.bitnami.com/articles/kubewatch-an-example-of-kubernetes-custom-controller.html
- https://www.firehydrant.io/blog/stay-informed-with-kubernetes-informers/
- https://kubernetes.io/docs/reference/using-api/api-concepts/
- https://book.kubebuilder.io/
- https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/

## Informers
An informer in is just something that informs you of events. In go, you attach event handlers to it. In rust, we grab the event directly and you can pattern match the type of it directly for the same effect:

```rust
fn handle_nodes(client: &APIClient, ev: WatchEvent<NodeSpec, NodeStatus>) -> Result<(), failure::Error> {
    match ev {
        WatchEvent::Added(o) => {
            info!("New Node: {}", o.spec.provider_id.unwrap());
        },
        WatchEvent::Modified(o) => {
            if let Some(true) = o.spec.unschedulable {
                let failed = o.status.conditions.unwrap().into_iter().filter(|c| {
                    (c.status == "True" && c.type_ != "Ready") ||
                    (c.status == "False" &&  c.type_ == "Ready")
                }).map(|c| c.message).collect::<Vec<_>>(); // failed statuses
                warn!("Unschedulable Node: {}, ({:?})", o.metadata.name, failed);
                // Separate API call with client to find events related to this node
                let sel = format!("involvedObject.kind=Node,involvedObject.name={}", o.metadata.name);
                let opts = ListEventForAllNamespacesOptional {
                    field_selector: Some(&sel),
                    ..Default::default()
                };
                let req = Event::list_event_for_all_namespaces(opts)?.0;
                let res = client.request::<Event>(req)?;
                warn!("Node events: {:?}", res);
            }
        },
        WatchEvent::Deleted(o) => {
            warn!("Deleted node: {} ({:?}) running {:?} with labels: {:?}",
                o.metadata.name, o.spec.provider_id.unwrap(),
                o.status.conditions.unwrap(),
                o.metadata.labels,
            );
        },
        WatchEvent::Error(e) => {
            warn!("Error event: {:?}", e);
        }
    }
    Ok(())
}
```


## abstracting

[The clusterfuck hidden in the Kubernetes code base](https://fosdem.org/2019/schedule/event/kubernetesclusterfuck/)

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct Resource<T, U> where
{
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub apiVersion: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub kind: Option<String>,
    pub metadata: Metadata,
    pub spec: T,
    pub status: U,
}
```


```rust
#[derive(Deserialize)]
pub struct ResourceList<T>
{
    pub metadata: Metadata,
    #[serde(bound(deserialize = "Vec<T>: Deserialize<'de>"))]
    pub items: Vec<T>,
}
```

###  version `0.7.0`

```toml
[dependencies]
kube = "0.7.0"
```

## How would you actually use this?
Easy. You'll have a struct that defines your CRD:

```rust
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct FooResource {
  name: String,
  info: String,
}
```

create your state container with an instance of `Reflector<FooResource>`:

```rust
#[derive(Clone)]
pub struct State {
    foos: Reflector<FooResource, Void>,
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
        let foos = Reflector::new(client, fooresource).init()?;
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
            state_clone.poll().map_err(|e| {
                error!("Kube state failed to recover: {}", e);
                // rely on kube's crash loop backoff to retry sensibly:
                std::process::exit(1);
            }).unwrap();
        }
    });
    Ok(state)
}
```
