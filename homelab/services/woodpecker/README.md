# Woodpecker CI

> NOTE: Woodpecker Agent requires access to the docker daemon in order to spawn runner containers

Since I'm using a containerd set up which doesn't need that daemon, this method of woodpecker deployment
will not work on my system.

There's a k8s backend that should work better for me, once/if I decide to set up a cluster in my infra.
