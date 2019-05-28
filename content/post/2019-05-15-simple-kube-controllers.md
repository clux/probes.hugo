---
title: Kubernetes API in rust
subtitle: A generic interface for the new rust client library
date: 2019-05-15
tags: ["rust", "kubernetes"]
categories: ["software"]
---

It's been about a months since we released [`kube`](https://github.com/clux/kube-rs), a client library for kubernetes in rust and there is a [blog post at the time explaining the initial setup](./2019-04-29-rust-on-kubernetes.md). While we did explore some high level concepts at the time, everything was experimental: would the generic setup work with native objects? How far would it extend? Would it be a primarily deserializing type client? What about custom queries? Event handling? Surely, it'd be a fools errand to write an entire client library?

With the last `0.7.0` release, it's becoming clear that the generic setup extends quite far and is quite useable. The terminology in the library is also a lot more representative of the Go world.

<!--more-->

## Stepping back
The reason this library even works at all, is the amount of homebrew generics present in the kubernetes API.

Thanks to the hard work of many kubernetes engineers, pretty much any non-error object retrieved from the API of kubernetes can in fact be deserialized into this struct:

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct Object<T, U> where T: Clone, U: Clone
{
    #[serde(default, flatten, skip_serializing_if = "Option::is_none")]
    pub typemeta: Option<TypeMeta>,
    pub metadata: Metadata,
    pub spec: T,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub status: Option<U>,
}
```

You can infer a lot of the inner api workings by looking at [kubernetes/apimachinery/blob/master/pkg/apis/meta/v1/types.go](https://github.com/kubernetes/apimachinery/blob/master/pkg/apis/meta/v1/types.go). Kris Nova's 2019 FOSDEM talk on [the internal clusterfuck of kubernetes]
(https://fosdem.org/2019/schedule/event/kubernetesclusterfuck/) also provides additional context.

By making these similar generic mappings we can provide a much simpler interface to what the generated openapi bindings can provide (albeit with a few holes at the moment).

## Parsing + Querying
Let's compare some openapi generated structs:

- [PodList](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodList.html)
- [NodeList](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.NodeList.html)
- [DeploymentList](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/apps/v1/struct.DeploymentList.html)

All with identical contents. You could just define this generic struct:

```rust
#[derive(Deserialize)]
pub struct ObjectList<T> where
  T: Clone
{
    pub metadata: Metadata,
    #[serde(bound(deserialize = "Vec<T>: Deserialize<'de>"))]
    pub items: Vec<T>,
}
```

Similarly, the query parameters optionals structs:

- [ListNodeOptional](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.ListNodeOptional.html)
- [ListPodForAllNamespacesOptional](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.ListPodForAllNamespacesOptional.html)
- [ListDeploymentForAllNamespacesOptional](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/apps/v1/struct.ListDeploymentForAllNamespacesOptional.html)

These are a mouthful. And again, almost all of them have the same fields. Not going to go through the whole setup here, because the TL;DR is that once you build everything with the `types.go` assumptions in mind, a lot just falls into place.

In fact, you can write a generic machinery that works entirely with `Object<P, U>`. Check out a subest of the current typed API looks li#ke:

```rust
impl<P, U> OpenApi<P, U> where
    P: Clone + DeserializeOwned,
    U: Clone + DeserializeOwned + Default,
{
    fn get(&self, name: &str) -> Result<(Object<P, U>, StatusCode)> {
        let req = self.api.get(name)?;
        self.client.request::<Object<P, U>>(req)
    }
    fn create(&self, pp: &PostParams, data: Vec<u8>) -> Result<(Object<P, U>, StatusCode)> {
        let req = self.api.create(&pp, data)?;
        self.client.request::<Object<P, U>>(req)
    }
    fn delete(&self, name: &str, dp: &DeleteParams) -> Result<(Object<P, U>, StatusCode)> {
        let req = self.api.delete(name, &dp)?;
        self.client.request::<Object<P, U>>(req)
    }
    fn list(&self, lp: &ListParams) -> Result<(ObjectList<Object<P, U>>, StatusCode)> {
        let req = self.api.list(&lp)?;
        self.client.request::<ObjectList<Object<P, U>>>(req)
    }
    fn delete_collection(&self, lp: &ListParams) -> Result<(ObjectList<Object<P, U>>, StatusCode)> {
        let req = self.api.delete_collection(&lp)?;
        self.client.request::<ObjectList<Object<P, U>>>(req)
    }
    fn patch(&self, name: &str, pp: &PostParams, patch: Vec<u8>) -> Result<(Object<P, U>, StatusCode)> {
        let req = self.api.patch(name, &pp, patch)?;
        self.client.request::<Object<P, U>>(req)
    }
    fn replace(&self, name: &str, pp: &PostParams, data: Vec<u8>) -> Result<(Object<P, U>, StatusCode)> {
        let req = self.api.replace(name, &pp, data)?;
        self.client.request::<Object<P, U>>(req)
    }
```

Everything takes the same `Params` (see the [docs](https://clux.github.io/kube-rs/kube/api/index.html) for details), and these can easily be converted into `Request` objects (containers for a url, query params, and data).

The real satisfying part here, is how you can just tell `client.request` to parse the `list` of objects as an `ObjectList<Object<P, U>>`.

## Api Usage
Using the `Api` now amounts to choosing one of the constructors for the native type you want (or perhaps a `customResource`) and use the verbs listed above. Thus, it actually nicely [overlaps quite a bit with how it's presented in client-go](https://github.com/kubernetes/client-go/blob/7b18d6600f6b0022e31c46b46875beffd85cc71a/kubernetes/typed/core/v1/pod.go#L39-L50).

For `Pod` objects, you can get such an object with:

```rust
let pods = OpenApi::v1Pod(client).within("kube-system");
let (pl, _) = pods.list(&ListParams::default())?;
```

Which would return `pl` as an `ObjectList` of `Object<PodSpec, PodStatus>`, leveraging `k8s-openapi` for [PodSpec](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodSpec.html) and [PodStatus](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodStatus.html) as the source for these large types.

You can define these structs yourself however, and for a custom resource, you are required to do so:

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct FooSpec {
    name: String,
    info: String,
}

#[derive(Deserialize, Serialize, Clone, Debug, Default)]
pub struct FooStatus {
    is_bad: bool,
}
```

but then you can do all the operations on it after telling `kube` where to look:

```rust
let foos : OpenApi<FooSpec, FooStatus> = OpenApi::customResource(client, "foos")
    .version("v1")
    .group("clux.dev")
    .within("dev");

let baz = foos.get("baz")?;
assert_eq!(baz.spec.info, "baz info");
```

Being able to parse straight into your typed structs is nice, what about posting and patching? For brevity, let's `create` and `patch` a `Foo` using the [serde_json json macro](https://docs.serde.rs/serde_json/macro.json.html):

```rust
let f = json!({
    "apiVersion": "clux.dev/v1",
    "kind": "Foo",
    "metadata": { "name": "baz" },
    "spec": { "name": "baz", "info": "baz info" },
});
let (o, c) = foos.create(&pp, serde_json::to_vec(&f)?)?;
assert_eq!(f["metadata"]["name"], o.metadata.name)
assert_eq!(c, StatusCode::CREATED);
```

Easy enough. What about a [patch](https://kubernetes.io/docs/tasks/run-application/update-api-object-kubectl-patch/#alternate-forms-of-the-kubectl-patch-command)?

```rust
let patch = json!({
    "spec": { "info": "patched baz" }
});
let (o, _) = foos.patch("baz", &pp, serde_json::to_vec(&patch)?)?;
assert_eq!(o.spec.info, "patched baz");
assert_eq!(o.spec.name, "baz");
```

Works fine. Although it's `patch --type=merge` which is the [only supported format atm](https://github.com/clux/kube-rs/issues/24).

Note that we are always returning the `StatusCode`, even though this is generally only useful for when you need to distinguish `CREATED` from `OK` and `ACCEPTED`. The request would've been a success if you got an `Ok` anyway.

## Higher level abstractions
With the core api abstractions in place. We can build Reflectors (structs that contain the logic to watch and cache state for a single resource type), and more. Since we talked about Reflector's earlier; Let's cover Informers.

### Informers
An informer in is just something that informs you of events. In go, you attach event handler functions to it. In rust, we just pattern match our `WatchEvent` enum directly for a similar effect:

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

```rust
#[derive(Deserialize, Serialize, Clone)]
#[serde(tag = "type", content = "object", rename_all = "UPPERCASE")]
pub enum WatchEvent<P, U> where
  P: Clone, U: Clone + Default,
{
    Added(Object<P, U>),
    Modified(Object<P, U>),
    Deleted(Object<P, U>),
    Error(ApiError),
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

Controllers in go can be slightly awkward to write because of all the indirection; (shared informers -> blah)


## Lacks
### Missing native objects
[Not all standard api-resources have been filled out yet!](https://github.com/clux/kube-rs/issues/25). Help is greatly appreciated.

### Missing special case nouns
Verbs defined above Object. Thus there's a current lack on working with special resources such as `pods/exec` or `pods/log`. See [#30](https://github.com/clux/kube-rs/issues/30).
