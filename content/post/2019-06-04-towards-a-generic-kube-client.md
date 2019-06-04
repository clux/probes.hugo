---
title: A generic kubernetes client
subtitle: Shaving a yak for a client-rust
date: 2019-06-04
tags: ["rust", "kubernetes"]
categories: ["software"]
---

It's been about a months since we released [`kube`](https://github.com/clux/kube-rs), a new rust client library for kubernetes. We wrote a [blog post at the time explaining the initial setup](/post/2019-04-29-rust-on-kubernetes), and while we did explore some high level concepts, everything was uncertain. Would the generic setup work with native objects? How far would it extend? Would it be a primarily deserializing type client? What about custom queries? Event handling? Surely, it'd be a fools errand to write an entire client library?

With the last `0.10.0` release, it's now clear that the generic setup extends quite far. Unfortunately, this yak is hairy, even by yak standards.

<!--more-->

## Overview
The reason this library even works at all, is the amount of homebrew generics present in the kubernetes API.

Thanks to the hard work of many kubernetes engineers, __most__ API returns can be serialized into some wrapper around this struct:

```rust
#[derive(Deserialize, Serialize, Clone)]
pub struct Object<T, U> where T: Clone, U: Clone
{
    #[serde(flatten)]
    pub types: TypeMeta,
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
If you follow this rabbit hole, you can end up with the following type signatures:

```rust
impl<K> Api<K> where
    K: Clone + DeserializeOwned + KubeObject
{
  fn get(&self, name: &str) -> Result<K>;
  fn create(&self, pp: &PostParams, data: Vec<u8>) -> Result<K>;
  fn patch(&self, name: &str, pp: &PostParams, patch: Vec<u8>) -> Result<K>;
  fn replace(&self, name: &str, pp: &PostParams, data: Vec<u8>) -> Result<K>;
  fn watch(&self, lp: &ListParams, version: &str) -> Result<Vec<WatchEvent<P, U>>>;
  fn list(&self, lp: &ListParams) -> Result<ObjectList<K>>;
  fn delete_collection(&self, lp: &ListParams) -> Result<Either<ObjectList<K>, Status>>;
  fn delete(&self, name: &str, dp: &DeleteParams) -> Result<Either<K, Status>>;

  fn get_status(&self, name: &str) -> Result<K>;
  fn patch_status(&self, name: &str, pp: &PostParams, patch: Vec<u8>) ->Result<K>;
  fn replace_status(&self, name: &str, pp: &PostParams, data: Vec<u8>) -> Result<K>;
}
```

These are the main query methods on our core `Api` ([docs](https://clux.github.io/kube-rs/kube/api/struct.Api.html) / [src](https://github.com/clux/kube-rs/blob/master/src/api/typed.rs)). Observe that similar types of requests take the same `*Params` objects to configure queries. Return types also have clear patterns.

There's is no hidden de-multiplexing on the parsing side either. When calling `list`, we just [turbofish](https://turbo.fish/) that type in for `serde` to deal with internally:

```rust
self.client.request::<ObjectList<Object<P, U>>>(req)
```

There is a new required trait `KubeObject` to deal with, but this has an automatic blanket implementation this for `K = Object<P, U>`.

### client-go semantics
While it might not seem like it with all this talk about generics, we are actually trying to model things a little closer to `client-go` and internal kube `apimachinery` (insofar as it makes sense).

Just have a look at how `client-go` presents [Pod objects](https://github.com/kubernetes/client-go/blob/7b18d6600f6b0022e31c46b46875beffd85cc71a/kubernetes/typed/core/v1/pod.go#L39-L50) or [Deployment objects](https://github.com/kubernetes/client-go/blob/e65ca70987a6941be583f205696e0b1b7da82002/kubernetes/typed/extensions/v1beta1/deployment.go#L39-L53). There's already a pretty clear overlap with the above signatures.

Maybe you are in the camp with `Bryan Liles`, who said that ["client-go is not for mortals"](https://youtu.be/Rbe0eNXqCoA?t=563) during his kubecon 2019 keynote. It's certainly a large library (sitting at ~80k lines of mostly go), but amongst the [chunks of intermixed cruft and useful code](https://godoc.org/k8s.io/client-go/tools/cache), it does embed a bunch of [really interesting patterns](https://godoc.org/k8s.io/client-go/util/retry#RetryOnConflict).

At any rate, the terminology in this library should now be a lot more familiar now that we're trying use ideas from `client-go`, follow the [api-concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/) better, and take inspiration from frameworks [kubebuilder](https://book.kubebuilder.io/). That said, we are inevitably going to hit some walls when kubernetes isn't as generic as we inadvertently promised it to be.

But delay that sad tale; let's look at how to use the `Api`:

## Api Usage
Using the `Api` now amounts to choosing one of the constructors for the native types you want (or perhaps a `customResource`) and use the verbs listed above.

For `Pod` objects, you can construct and use such an object like:

```rust
let pods = Api::v1Pod(client).within("kube-system");
let podlist = pods.list(&ListParams::default())?;
```

Here the `podlist` var is an `ObjectList` of `Object<PodSpec, PodStatus>`. This leverages `k8s-openapi` for [PodSpec](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodSpec.html) and [PodStatus](https://docs.rs/k8s-openapi/0.4.0/k8s_openapi/api/core/v1/struct.PodStatus.html) as the source of these large types.

If needed, you [can define these structs yourself](https://github.com/clux/kube-rs#raw-api), but as an example, let's show how that plays in with [CRDs](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/); because custom resources require you to define everything about them anyway.

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

type Foo = Object<FooSpec, FooStatus>;
```

This is all you need to get your "code generation". No external tools to shell out to; `cargo build` gives you your json serialization/deserialization, and the generic `Api` gives you your api machinery. With it, you can the construct and use your `customResource` as follows:

```rust
let foos : Api<Foo> = Api::customResource(client, "foos")
    .version("v1")
    .group("clux.dev")
    .within("default");

let baz = foos.get("baz")?;
assert_eq!(baz.spec.info, "baz info");
```

Here we are fetching and parsing straight into the typed struct. But what about posting and patching? For brevity, let's `create` and `patch` a `Foo` using the [serde_json macro](https://docs.serde.rs/serde_json/macro.json.html):

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

Here `json!` really shines. You can also reference variables and [you can attach structs to keys](https://github.com/clux/kube-rs/blob/0b0ed4d2f035cf9e455f1ad8ae346cf87fc20cac/examples/crd_openapi.rs#L140-L146) within.

## Higher level abstractions
With the core api abstractions in place, we can easily build Reflectors (structs that contain the logic to watch and cache all state for a single resource type), and more. Since we [talked about Reflector's earlier](/post/2019-04-29-rust-on-kubernetes); Let's cover Informers.

### Informers
An informer for a resource is an event notifier for that resource. It calls `watch` when you ask it to, and it informs you of new events. In go, you attach event handler functions to it. In rust, we just pattern match our `WatchEvent` enum directly for a similar effect:

```rust
fn handle_nodes(ev: WatchEvent<Node>) -> Result<(), failure::Error> {
    match ev {
        WatchEvent::Added(o) => {},
        WatchEvent::Modified(o) => {},
        WatchEvent::Deleted(o) => {},
        WatchEvent::Error(e) => {}
    }
    Ok(())
}
```

The `o` being destructured here is an `Object<NodeSpec, NodeStatus>`. See [informer examples](https://github.com/clux/kube-rs/blob/master/examples/) for doing something with the objects.

To actually initialize and drive a node informer, you can do something like this:

```rust
fn main() -> Result<(), failure::Error> {
    let config = config::load_kube_config().expect("failed to load kubeconfig");
    let client = APIClient::new(config);
    let nodes = Api::v1Node(client);
    let ni = Informer::new(nodes)
        .labels("role=worker")
        .init()?;

    loop {
        ni.poll()?;

        while let Some(event) = ni.pop() {
            handle_nodes(event)?;
        }
    }
}
```

The harder parts typically come if you need a separate threads; like one to handle polling, one for handling events async, perhaps you are interacting with a set of threads in an tokio/actix runtime.

You [should handle these cases](https://cloud.google.com/blog/products/containers-kubernetes/best-practices-for-building-kubernetes-operators-and-stateful-apps) (#5), but it's thankfully, not hard. You can just give out a `.clone()` of an `Informer` to the runtime. With `actix` data it's as simple as passing `App::new().data(informer.clone())`, and you can then poll your own clone separately. The [controller-rs](https://github.com/clux/controller-rs) example shows [how to encapsulate an informer](https://github.com/clux/controller-rs/blob/master/src/state.rs) with [actix](https://github.com/clux/controller-rs/blob/5db6caca13f4a33d168c1abe7c94a02559d4f46e/src/main.rs#L20-L51) (using the 1.0.0 rc).

You should end up with a complete controller in a [7MB alpine image](https://github.com/clux/controller-rs/blob/master/Dockerfile).

### Informer Internals
Informers are just wrappers around a `watch` call that keeps track of `resouceVersion`. There's very little inside of it:

```rust
type WatchQueue<K> = VecDeque<WatchEvent<K>>;

#[derive(Clone)]
pub struct Informer<K> where
    K: Clone + DeserializeOwned + KubeObject
{
    events: Arc<RwLock<WatchQueue<K>>>,
    version: Arc<RwLock<String>>,
    client: APIClient,
    resource: RawApi,
    params: ListParams,
}
```

If it wasn't for the extra internal event queue (that users are meant to consume), we could easily have built `Reflector` on top of `Informer`. The only main difference is that a `Reflector` uses the events to maintain an up-to-date `BTreeMap` rather than handing the events out.

As with `Reflector`, we rely on this foundational enum (now public) to encapsulate events:

```rust
#[derive(Deserialize, Serialize, Clone)]
#[serde(tag = "type", content = "object", rename_all = "UPPERCASE")]
pub enum WatchEvent<K> where
    K: Clone + KubeObject
{
    Added(K),
    Modified(K),
    Deleted(K),
    Error(ApiError),
}
```

You can compare with [client-go's WatchEvent](https://github.com/kubernetes/apimachinery/blob/594fc14b6f143d963ea2c8132e09e73fe244b6c9/pkg/apis/meta/v1/watch.go).

## Drawbacks
So. What's awful?

### Everything is camelCase!
Yeah.. Global `#![allow(non_snake_case)]`. It's arguably less helpful to map case-preference to rust's language convention when you need to cross reference values with the [main API docs using Go conventions](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14). But then again we do rely on openapi for a lot of this stuff anyway. Do people have strong feelings about this?

### Delete returns an Either
The `delete` verb akwardly gives you a `Status` object (sometimes..), so we have to maintain logic to conditionally parse those `kind` values (where we expect them) into an [Either enum](https://docs.rs/either/1.5.2/either/enum.Either.html). This means users have to `map_left` to deal with the "it's not done yet" case, or `map_right` for the "it's done" case. Maybe there's a better way to do this. Maybe we need a more semantically correct enum.

### Some resources are true snowflakes
While we do handle the [generic subresources](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#subresources) like [Scale](https://github.com/clux/kube-rs/blob/c14ef965af7d68d37e6acb343d02ef5841c5bf37/src/api/typed.rs#L126-L142), some objects has a bunch of special subresources associated with them.

The most common example is `v1Pod`, which has `pods/attach`, `pods/portforward`, `pods/eviction`, `pods/exec`, `pods/log`, to name a few. Similarly, we can `drain` or `cordon` a `v1Node`. So we clearly have non-standard verbs and non-standard nouns.

This is probably solveable with some blunt `generic_verb_noun` hammer on `RawApi` ([see #30](https://github.com/clux/kube-rs/issues/30)) for our supported apis.

It clearly breaks the generic model somewhat, but thankfully only in the areas you'd expect it to break.

### Not everything follows the Spec + Status model
You might think these exceptions make up a short and insignificant list of legacy objects, but look at this subset:

- [RoleBinding](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#rolebinding-v1-rbac-authorization-k8s-io) with `subjects` + `roleRef`
- [Role](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#role-v1-rbac-authorization-k8s-io) with a `rules` vec
- [ConfigMap](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#configmap-v1-core) - with `data` + `binaryData`
- [Endpoints](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#endpoints-v1-core) - with a `subsets` vector
- [Event](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#event-v1-core) - with 17 random fields!
- [ServiceAccount](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#serviceaccount-v1-core) - `secrets` vector + misc fields

And that was only like 20 minutes in the API docs. Long story short, [we eventually](https://github.com/clux/kube-rs/issues/35) stopped relying on `Object<P, U>` everywhere in favour of `KubeObject` trait objects. This meant we could deal with these special objects in [mod snowflake](https://github.com/clux/kube-rs/blob/0b0ed4d2f035cf9e455f1ad8ae346cf87fc20cac/src/api/snowflake.rs#L15-L62), and we don't have to feel too dirty about it..

### Remaining toil
While many of the remaining tasks are not too difficult, there are quite a few of them:

- [integrating all the remaining native objects](https://github.com/clux/kube-rs/issues/25) (can be done one-by-one)
- support more than [`patch --type=merge`](https://github.com/clux/kube-rs/issues/24)
- [backoff crate](https://docs.rs/backoff/0.1.5/backoff/) use for [exponential backoff](https://github.com/clux/kube-rs/issues/34) => less cascady network failures
- support [local kubeconfig auth providers](https://github.com/clux/kube-rs/issues/19)

The last one is a huge faff, with differences across providers, all in the name of avoiding [impersonating a service accounts when developing locally](/post/2019-03-31-impersonating-kube-accounts).

## Help
The foundation is now there, in the sense that we feel like we're covering most of the theoretical bases (..that we could think of).

[Help with examples/object support/stuff listed above](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22) would be greatly appreciated at this point. Hopefully, this library will end up being useful to some. With some familiarity with rust, the generated [docs](https://clux.github.io/kube-rs/kube/api/index.html) + [examples](https://github.com/clux/kube-rs/tree/master/examples) should get you started.

Anyway, if you do end up using this, and you work in the open, [please let us link to your controllers for examples](https://github.com/clux/kube-rs/issues/12).

</🐂💈>
