# Steven Fitzpatrick

Software Engineer in Seattle, WA

**@sf1tzp**
*[linkedin](https://www.linkedin.com/in/sf1tzp/)
[github](https://www.github.com/sf1tzp/)*

Hello!

## Symbology Online - Open Source, LLM Generated Insights from SEC Filings
### From: March 2025 - Present
### Description
Symbology is a project I started after doing some research into investing principles. A large component of "Fundamental Analysis" is qualitative - not quantitative, and I saw an intersection between this task and the capabilities of LLMs.

For Symbology, I drafted and implemented a LLM-generation pipeline service, which sources textual filing documents from the SEC to create brief, informative summaries of company activities (and risk factors, current events, etc).

The project experiments with prompt engineering techniques, cryptography & decentralization schemes, and is my first web UI project in quite a while.

Along the way, I:
- Built custom VM infrastructure at home with KVM, including support for GPU passthrough, custom base images with monitoring enrollment built-in, rootless containers and other niceties.
- Deployed several containerized services (Logs & Metrics Stack, ollama/open-webui, symbology app services, etc).
- Developed a custom CLI to create, store, rate & review prompts, model parameter sets, generated contents.
- Benchmarked & Dialed-in model parameters to ensure VRAM confinement, cutting runtime by ~2/3 compared to naive configurations (~12m runtime avg down to ~4m avg by right-sizing model & context size for my hardware).
- Explored Svelte js and ShadCN component library to build UIs (https://symbology.online).
- Merged PRs in open source repositories [dgunning/edgartools](https://github.com/dgunning/edgartools) and [frcooper/ollama-exporter](https://github.com/frcooper/ollama-exporter).

## Microsoft - Azure Local Undercloud
### From: August 2021 - November 2024
### Description
Here I was involved during the creation of a baremetal kubernetes infrastructure project (Which went by various names, "Azure Operator Nexus", "Azure Local").

We utilized cluster API (CAPI) to create and upgrade kubernetes clusters, which supported various VM and containerized workloads (including other kubernetes clusters). I had hands-on experience in many elements of the stack, from specific linux host configurations, through `Machine` and `Cluster` CAPI abstractions, as well as operational aspects like interfacing with the Azure control plane, writing dashboard and alert queries, and triaging issues while on call.

Additionally, we practiced software supply chain security and "DevOps" style code-ownership, and I am well experienced in configuring image builds, CI/CD, code review, git, etc.

Along the way, I:
- Contributed to various services, k8s operators and general HTTP APIs, system utilities in multiple languages.
- Was frequently assigned feature ownership and led development efforts up & down the stack.
- Mentored and encouraged knowledge sharing with at least 5 scheduled 'lunch-and-learn' style deep-dives into various domain specific topics.
- Helped establish service level indicators and objectives for server & cluster lifecycle actions.
  - Targeted logging enhancements drove time-to-identify down immensely during lifecycle actions.
  - Developed state-transition dashboard widgets to illustrate lifecycle action progress / status.
  - Worked with cross-team contacts to correlate logging between various management API services and the platform.

## AT&T - Network Cloud
### From: July 2019 - August 2021
### Description
AT&T's Network Cloud was/is the precursor to Microsoft's Operator Nexus / Azure Local platform. Here I was involved with the configuration of the platform's monitoring stack (Elasticsearch, fluentd, prometheus, grafana, alertmanager). We managed configuration via helm, in the now archived openstack-archive/openstack-helm-infra repository. While the project was active, I was nominated as a Core Reviewer of the openstack-helm projects and became familiar with many kubernetes concepts and operational practices.

## And Earlier
### From Past - 2019
### Description
Prior to 2019 I worked as a systems administrator and in various other odd-jobs. There's too much to write here, but I still rely on insights and learnings from this time.
