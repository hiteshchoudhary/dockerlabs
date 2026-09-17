# Challenge

One mode remains untouched: **`none`**.

Run a long-lived detached `alpine` container named exactly **`chai-18-lonely`** with its network mode set to `none`. Then step inside and look around: `ip addr` shows only a loopback interface, `/etc/resolv.conf` is empty of useful answers, and `ping 8.8.8.8` can't even try — *network unreachable*. No veth pair was ever crimped for this container; there is no cable to trace.

**You pass when:** `chai-18-lonely` is running from `alpine` with network mode `none`, it has no IP address on any network, and a ping to the outside world from inside it fails — the verifier checks all three, and the last one is the only verifier in this Part that celebrates a *failed* connection.
