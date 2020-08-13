---
title: The hidden generics of kubernetes' API
subtitle: a path forward for kubernetes clients
date: 2020-08-12
tags: ["rust", "kubernetes"]
categories: ["software"]
---

Last year, [kube-rs](https://github.com/clux/kube-rs) was made and the first crate [kube](https://crates.io/crates/kube) published. We accidentally stumbled, then latched ourseleves onto the hidden generics in kubernetes' `apimachinery`.

<!--more-->

talking about this at kubecon.. ZEIT.
apimachinery has the types we define. client-go enforces the generics we enforce, but manually with codegen.

## Tighter intergration with k8s-openapi
traits

## Automatic genreation of custom resource code
kube-derive

## Maintainers
New maintainers; <img alt="kubernetes beta client" style="display:inline" src="https://img.shields.io/badge/kubernetes%20client-beta-green.svg?style=plastic&colorA=306CE8"/>
teo, after writing runtime (link runtime post)

## unresolved
`k8s-openapi` is [sans-io principle](https://sans-io.readthedocs.io/), we are not.
leads to client dependency and client configuration feature flags duplicating everywhere. ideally, you should own the client, and how it is set up.
