# router exporter

node_exporter on the ASUS RT-AX1800S (stock firmware), kept alive by a
reconciler on soundship. Successor to the retired
`services/monitoring/router_exporters.sh` ritual, which installed the
exporter by hand and lost it on every reboot: stock AsusWRT mounts the
filesystem read-only outside `/tmp`, `/tmp` is RAM, and no boot hook
exists without custom firmware.

The loop closes from outside instead: a systemd timer on soundship
probes `10.0.0.1:9100` every five minutes and, when it stops answering,
pipes the binary over SSH (dropbear has no scp) and relaunches it. A
router reboot costs at most ~five minutes of metrics.

Hardware fact that pins the binary: the original-revision RT-AX1800S is
MediaTek MT7621 — **mipsle** builds. A v2 unit (MT7981) would need
arm64; check the sticker before changing `node_exporter_version` or the
arch.

## Mint steps (one-time, in the router UI)

1. Administration → System: enable **SSH (LAN only)**, port 22, with
   password login off once the key works.
2. Run `just router` once — it generates the reconciler's keypair on
   soundship and prints the public key. Paste it into **Authorized
   Keys** in the same UI page.
3. Run the reconciler once by hand and watch it work:

   ```
   sudo systemctl start router-exporter-reconcile.service
   journalctl -u router-exporter-reconcile.service -n 20
   curl -s http://10.0.0.1:9100/metrics | head
   ```

## After the first successful run

Restore the router's scrape target on the hub: estate-hub
`flux/apps/sfi-central/monitoring-central/central-scrapeconfigs.yaml`
says where (a static target `10.0.0.1:9100`, jobName `node_exporter`,
`instance: router` — luxor's shape, so the imported dashboards keep
working).

## Retirement plan

estate-hub tracks an OpenWrt flash of this router (planned ~spring).
OpenWrt's `prometheus-node-exporter-lua` package survives reboots
natively; when that lands, this service and its timer are deleted.

## Limits, stated plainly

- The exporter is down between a router reboot and the next timer tick.
  That gap is the design, not a bug — it costs minutes of node metrics
  from a device whose interesting signal (is the WAN up) blackbox
  already probes from in-cluster.
- Stock firmware auto-updates can change SSH behavior; the reconciler
  fails loudly into the journal, which ships to the hub's Loki
  (job=systemd, host=soundship).
- blackbox_exporter is deliberately not reinstalled on the router — it
  moved in-cluster with the luxor-era migration and stays there.
