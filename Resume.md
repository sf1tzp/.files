# Steven Fitzpatrick

Software Engineer in Seattle, WA

**@sf1tzp**
*[linkedin](https://www.linkedin.com/in/sf1tzp/)
[github](https://www.github.com/sf1tzp/)*

## Symbology Online
### From: March 2025 - Present
### Description
Here I drafted and implemented an LLM-generation pipeline service, which uses modern prompt engineering techniques and a content hash source-verification scheme to generate re-produceable results from a variety of source content. It's important to fully utilize the available hardware when processing dozens/hundreds of documents, so I utilized GPU monitoring tools to "right-size" model parameters based on the input size in order to avoid CPU spillover.

Along the way, I:
- Built custom VM infrastructure at home with KVM, including support for GPU passthrough, custom base images with monitoring enrollment built-in, rootless containers and other niceties
- Built several containerized service deployments (Logs & Metrics Stack, ollama/open-webui, symbology app services, etc)
- Explored Svelte js and ShadCN component library to build UIs (https://symbology.online)
- Merged PRs in open source repositories [dgunning/edgartools](https://github.com/dgunning/edgartools) and [frcooper/ollama-exporter](https://github.com/frcooper/ollama-exporter)

## Microsoft - Azure Local Control Plane
### From: August 2021 - November 2024
### Description
Here I was involved during the creation of a baremetal kubernetes infrastructure project (Which went by various names, "Azure Operator Nexus", "Azure Local").

We utilized cluster API (CAPI) to create and upgrade kubernetes clusters, which supported various VM and containerized workloads (including other kubernetes clusters). I had hands-on experience in many elements of the stack, from specific host configurations, through Machine and Cluster CAPI abstractions, as well as operational aspects like interfacing with the Azure control plane, writing dashboard and alert queries, and triaging issues while on call.

Additionally, we practiced software supply chain security and "DevOps" style code-ownership on my team, and I am well experienced in configuring container image builds, CI/CD, code review, git, etc.

Along the way, I:
- Contributed to various services, k8s operators and general HTTP APIs in multiple languages
- Led feature development across the stack

## AT&T - Network Cloud
### From: July 2019 - August 2021
### Description
AT&T's Network Cloud was/is the precursor to Microsoft's Operator Nexus / Azure Local platform. Here I was involved with the configuration of the platform's monitoring stack (Elasticsearch, fluentd, prometheus, grafana, alertmanager). We managed configuration via helm, in the now archived openstack-archive/openstack-helm-infra repository. While the project was active, I was nominated as a Core Reviewer of the openstack-helm projects and became familiar with many kubernetes concepts and operational practices.

## And Earlier
### From Past - 2019
### Description
Prior to 2019 I worked as a systems administrator and in various other odd-jobs. There's too much to write here, but I still rely on some insights and learnings from this time.
