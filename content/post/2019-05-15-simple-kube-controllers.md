---
title: Kubernetes controllers in rust
subtitle: Light weight foundations for a generic kubernetes interface
date: 2019-05-15
tags: ["rust", "kubernetes"]
categories: ["software"]
---

When writing controllers using [client-go](https://github.com/kubernetes/client-go), there's plenty of useful structures you end up interacting with

The kubernetes API itself has a surpising amount of "generic" interface

either  via go, or `kubectl` via shell.

<!--more-->

resolved shit:
- parameters exposed generically
- native objects exposed generically
- interspersing kube api calls ez now
- informers

unresolved:
- reflectors on top of informers
- new terminology?

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

### [`kube`](https://github.com/clux/kube-rs) version `0.7.0`

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
