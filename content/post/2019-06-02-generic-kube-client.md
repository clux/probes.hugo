---
title: A generic kubernetes client
subtitle: Shaving a yak for a client-rust
date: 2019-05-15
tags: ["rust", "kubernetes"]
categories: ["software"]
---

It's been about a months since we released [`kube`](https://github.com/clux/kube-rs), an experimental client library for kubernetes in rust, and we even wrote a [blog post at the time explaining the initial setup](/post/2019-04-29-rust-on-kubernetes). While we did explore some high level concepts at the time, everything was uncertain: would the generic setup work with native objects? How far would it extend? Would it be a primarily deserializing type client? What about custom queries? Event handling? Surely, it'd be a fools errand to write an entire client library?

With the last `0.9.0` release, it's now clear that the generic setup extends quite far. Unfortunately, this yak is hairy, even by yak standards.

<!--more-->

## Overview
The reason this library even works at all, is the amount of homebrew generics present in the kubernetes API.

Thanks to the hard work of many kubernetes engineers, most API returns can be serialized into some wrapper around this struct:

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct Object<T, U> where T: Clone, U: Clone
{
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub apiVersion: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub kind: Option<String>,
    pub metadata: ObjectMeta,
    pub spec: T,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub status: Option<U>,
}
```

You can infer a lot of the inner api workings by looking at [apimachinery/meta/types.go](https://github.com/kubernetes/apimachinery/blob/master/pkg/apis/meta/v1/types.go). Kris Nova's 2019 FOSDEM talk on [the internal clusterfuck of kubernetes]
(https://fosdem.org/2019/schedule/event/kubernetesclusterfuck/) also provides a much welcome, rant-flavoured context.

By taking advantage of this construct, and similar generic api concepts we can provide a much simpler interface to what the generated openapi bindings can provide, but with some caveats that we'll cover later.

## More object patterns
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
    pub metadata: ListMeta,
    #[serde(bound(deserialize = "Vec<T>: Deserialize<'de>"))]
    pub items: Vec<T>,
}
```

Similarly, the query parameters optionals structs:

- [ListNodeOptional](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.ListNodeOptional.html)
- [ListPodForAllNamespacesOptional](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.ListPodForAllNamespacesOptional.html)
- [ListDeploymentForAllNamespacesOptional](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/apps/v1/struct.ListDeploymentForAllNamespacesOptional.html)

These are a mouthful. And again, almost all of them have the same fields. Not going to go through the whole setup here, because the TL;DR is that once you build everything with the `types.go` assumptions in mind, a lot just falls into place and we can write our own generic api machinery.

## Api machinery
If you follow this rabbit hole, you're likely to end up with something like the following type signatures:

```rust
impl<P, U> Api<P, U> where
    P: Clone + DeserializeOwned,
    U: Clone + DeserializeOwned + Default,
{
  fn get(&self, name: &str)
    -> Result<Object<P, U>> {}

  fn create(&self, pp: &PostParams, data: Vec<u8>)
    -> Result<Object<P, U>> {}

  fn patch(&self, name: &str, pp: &PostParams, patch: Vec<u8>)
    -> Result<Object<P, U>> {}

  fn replace(&self, name: &str, pp: &PostParams, data: Vec<u8>)
    -> Result<Object<P, U>> {}

  fn watch(&self, lp: &ListParams, version: &str)
    -> Result<Vec<WatchEvent<P, U>>> {}

  fn list(&self, lp: &ListParams)
    -> Result<ObjectList<Object<P, U>>> {}

  fn delete_collection(&self, lp: &ListParams)
    -> Result<Either<ObjectList<Object<P, U>>, Status>> {}

  fn delete(&self, name: &str, dp: &DeleteParams)
    -> Result<Either<Object<P, U>, Status>> {}
}
```

These are the main query methods on our core `Api` ([docs](https://clux.github.io/kube-rs/kube/api/struct.Api.html) / [src](https://github.com/clux/kube-rs/blob/master/src/api/typed.rs)). Observe that similar types of requests take the same `*Params` objects to configure the queries, and the return types have clear patterns.

There's isn't some hidden de-multiplexing on the parsing side here either. When calling `list`, we really just [turbofish](https://turbo.fish/) that type in for `serde` to deal with internally:

```rust
self.client.request::<ObjectList<Object<P, U>>>(req)
```

### client-go semantics
While it might not seem like it with all this talk about generics, we are actually trying to model things a little closer to `client-go` and internal kube `apimachinery` (where it makes sense).

Just have a look at [how client-go presents Pod objects](https://github.com/kubernetes/client-go/blob/7b18d6600f6b0022e31c46b46875beffd85cc71a/kubernetes/typed/core/v1/pod.go#L39-L50). There's already a pretty clear overlap with the above signatures.

Amusingly, Bryan Liles said that ["client-go is not for mortals"](https://youtu.be/Rbe0eNXqCoA?t=563) during his kubecon 2019 keynote. Without sounding too much like undead sympathizers, we would like to add that it's still an amazing client library.

At any rate, the terminology in this library should already by a lot more representative of what people expect after following the [canonical sources](https://kubernetes.io/docs/reference/using-api/api-concepts/) and taking inspiration from stuff like [kubebuilder](https://book.kubebuilder.io/). That said, we are inevitably going to hit some walls when kube isn't as generic as we inadvertently promised it to be.

Enough waffle. Let's look at how to use it.

## Api Usage
Using the `Api` now amounts to choosing one of the constructors for the native type you want (or perhaps a `customResource`) and use the verbs listed above.

For `Pod` objects, you can construct and use such an object like:

```rust
let pods = Api::v1Pod(client).within("kube-system");
let podlist = pods.list(&ListParams::default())?;
```

Here the `podlist` var is an `ObjectList` of `Object<PodSpec, PodStatus>`, leveraging `k8s-openapi` for [PodSpec](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodSpec.html) and [PodStatus](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodStatus.html) as the source for these large types.

Now, you [can define these structs yourself](https://github.com/clux/kube-rs#raw-api) if you only need parts of the spec. But let's do that for [CRDs](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/), because you are required to define everything about them anyway:

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct FooSpec {
    name: String,
    info: String,
}

#[derive(Deserialize, Serialize, Clone, Debug, Default)]
pub struct FooStatus {
    isBad: bool,
}
```

This is all you need to get your code generation. No external tools to shell out to, `cargo build` gives you your json serialization/deserialization from this. With it, you can the construct and use your `customResource` as follows:

```rust
let foos : Api<FooSpec, FooStatus> = Api::customResource(client, "foos")
    .version("v1")
    .group("clux.dev")
    .within("default");

let baz = foos.get("baz")?;
assert_eq!(baz.spec.info, "baz info");
```

Here we are parsing straight into the typed structs, so what about posting and patching? For brevity, let's `create` and `patch` a `Foo` using the [serde_json macro](https://docs.serde.rs/serde_json/macro.json.html):

```rust
let f = json!({
    "apiVersion": "clux.dev/v1",
    "kind": "Foo",
    "metadata": { "name": "baz" },
    "spec": { "name": "baz", "info": "baz info" },
});
let o = foos.create(&pp, serde_json::to_vec(&f)?)?;
assert_eq!(f["metadata"]["name"], o.metadata.name)
```

Easy enough (if [a little verbose](https://github.com/clux/kube-rs/issues/31)). What about a [patch](https://kubernetes.io/docs/tasks/run-application/update-api-object-kubectl-patch/#alternate-forms-of-the-kubectl-patch-command)?

```rust
let patch = json!({
    "spec": { "info": "patched baz" }
});
let o = foos.patch("baz", &pp, serde_json::to_vec(&patch)?)?;
assert_eq!(o.spec.info, "patched baz");
assert_eq!(o.spec.name, "baz");
```

Here `json!` really shines. You can also reference variables and [you can attach structs to keys](https://github.com/clux/kube-rs/blob/c14ef965af7d68d37e6acb343d02ef5841c5bf37/examples/crd_openapi.rs#L140-L146) within.

## Higher level abstractions
With the core api abstractions in place, we can easily build Reflectors (structs that contain the logic to watch and cache state for a single resource type), and more. Since we [talked about Reflector's earlier](/post/2019-04-29-rust-on-kubernetes); Let's cover Informers.

### Informers
An informer for a resource is an event notifier for that resource. It calls `watch` when you ask it to, and it informs you of new events. In go, you attach event handler functions to it. In rust, we just pattern match our `WatchEvent` enum directly for a similar effect:

```rust
fn handle_nodes(client: &APIClient, ev: WatchEvent<NodeSpec, NodeStatus>) -> Result<(), failure::Error> {
    match ev {
        WatchEvent::Added(o) => {},
        WatchEvent::Modified(o) => {},
        WatchEvent::Deleted(o) => {},
        WatchEvent::Error(e) => {}
    }
    Ok(())
}
```

The  `o` being destructured here is an `Object<NodeSpec, NodeStatus>`. See [informer examples](https://github.com/clux/kube-rs/blob/master/examples/) for doing something with the objects.

To actually initialize and drive a node informer, you can do something like this:

```rust
fn main() -> Result<(), failure::Error> {
    let config = config::load_kube_config().expect("failed to load kubeconfig");
    let client = APIClient::new(config);
    let nodes = RawApi::v1Node();
    let ni = Informer::raw(client.clone(), nodes)
        .labels("role=worker")
        .init()?;

    loop {
        ni.poll()?;

        while let Some(event) = ni.pop() {
            handle_nodes(&client, event)?;
        }
    }
}
```

The harder parts typically come if you need a separate threads; like one to handle polling, one for handling events async, perhaps you are interacting with a set of threads in an tokio/actix runtime.

You should handle these cases (see [google's best practices tip #5](https://cloud.google.com/blog/products/containers-kubernetes/best-practices-for-building-kubernetes-operators-and-stateful-apps)), and it's not hard. You can give out a `.clone()` of an `Informer` to the runtime, for instance as `actix` state with: `App::new().data(informer.clone())`, and you can poll your own clone separately. The [controller-rs](https://github.com/clux/controller-rs) example shows [how to encapsulate an informer](https://github.com/clux/controller-rs/blob/master/src/state.rs) with [actix](https://github.com/clux/controller-rs/blob/5db6caca13f4a33d168c1abe7c94a02559d4f46e/src/main.rs#L20-L51) (using the 1.0.0 rc).

You should end up with a complete controller in a [7MB alpine image](https://github.com/clux/controller-rs/blob/master/Dockerfile).

### Informer Internals
Informers are just wrappers around a `watch` call that keeps track of `resouceVersion`. There's very little inside of it:

```rust
#[derive(Clone)]
pub struct Informer<P, U> where
    P: Clone + DeserializeOwned,
    U: Clone + DeserializeOwned + Default,
{
    events: Arc<RwLock<WatchQueue<P, U>>>,
    version: Arc<RwLock<String>>,
    client: APIClient,
    resource: RawApi,
    params: ListParams,
}
```

If it wasn't for the internal event queue (that users are meant to consume), we could easily have built `Reflector` on top of `Informer`, but it felt a bit wasteful to do so.

As with `Reflector`, the underlying enum that captures the [more awkward go WatchEvent](https://github.com/kubernetes/apimachinery/blob/594fc14b6f143d963ea2c8132e09e73fe244b6c9/pkg/apis/meta/v1/watch.go) is this:

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

It was private when we only supported `Reflector`, but now it's the main interface.

## Drawbacks
Up until this point, things have been painted with a a pretty rosy brush. Let's knock it down a couple of notches.

### Everything is camelCase!
Yeah.. Global `#![allow(non_snake_case)]`. It's actually less helpful to map cases to our own language convention when you need to cross reference values with the [main API docs using Go conventions](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14). Do people have strong feelings about this?

### Plenty of stuff left
While many of the remaining tasks are not too difficult, there are a lot of them:

- [integrating all the remaining native objects](https://github.com/clux/kube-rs/issues/25) (can be done one-by-one)
- support more than [`patch --type=merge`](https://github.com/clux/kube-rs/issues/24)
- [backoff crate](https://docs.rs/backoff/0.1.5/backoff/) use for [exponential backoff](https://github.com/clux/kube-rs/issues/34) => less cascady network failures
- support [local kubeconfig auth providers](https://github.com/clux/kube-rs/issues/19)

The last one is a huge faff, with differences across providers, all in the name of avoiding [impersonating a service accounts when developing locally](/post/2019-03-31-impersonating-kube-accounts).

### Delete returns an Either
The `delete` verb akwardly gives you a `Status` object (sometimes..), so we have to maintain logic to conditionally parse those `kind` values (where we expect them) into an [Either enum](https://docs.rs/either/1.5.2/either/enum.Either.html). This means users have to `map_left` to deal with the "it's not done yet" case, or `map_right` for the "it's done" case. Maybe there's a better way to do this. Maybe we need a more semantically correct enum.

### Some resources are true snowflakes
While we do handle the [generic subresources](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#subresources) like [Scale](https://github.com/clux/kube-rs/blob/c14ef965af7d68d37e6acb343d02ef5841c5bf37/src/api/typed.rs#L126-L142), some objects has a bunch of special subresources associated with them.

The most common example is `v1Pod`, which has `pods/attach`, `pods/portforward`, `pods/eviction`, `pods/exec`, `pods/log`, to name a few. Similarly, we can `drain` or `cordon` a `v1Node`. So we clearly have non-standard verbs and non-standard nouns.

Now, we **can** implement a `generic_verb_noun` thing on `RawApi` ([see #30](https://github.com/clux/kube-rs/issues/30)) for our supported **stable apis** (because let's be realistic here).

It obviously breaks the generic model somewhat, but thankfully only in the areas you'd expect it to break.

### Not everything follows the Spec + Status model
Out of everything this one ([#35](https://github.com/clux/kube-rs/issues/35)) hurts the most. A bunch of native objects do not use `Spec` and `Status` at all. Unfortunately, they are also so common they are hard to disregard:

- [RoleBinding](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/rbac/v1/struct.RoleBinding.html)
- [Role](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/rbac/v1/struct.Role.html)
- [ConfigMap](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.ConfigMap.html)
- [Endpoints](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.Endpoints.html)
- [Event](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/events/v1beta1/struct.Event.html)
- [ServiceAccount](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.ServiceAccount.html)

There's just no good solution to this at the moment. You can't build a `Reflector<RoleBinding>`. Can you even do that in `client-go`? Is this a `mod snowflake` situation, or do we have to lift the abstraction up one level?

## Help
Going forward, further improvement is going to take [some help](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22). Hopefully, it'll end up being useful to some. With some familiarity with rust, the generated [docs](https://clux.github.io/kube-rs/kube/api/index.html) + [examples](https://github.com/clux/kube-rs/tree/master/examples) should get you started.

Anyway, if you do end up using this, and you work in the open, [please let us link to your controllers for examples](https://github.com/clux/kube-rs/issues/12).

</🐂💈>
