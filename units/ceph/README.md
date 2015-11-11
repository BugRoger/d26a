# Adding an additional disk 

Get an OSD ID:

```
docker run -i -v /etc/ceph:/etc/ceph -t ceph/base /bin/bash
ceph osd create
0
```

Prepare and mount the data drive:

```
mkdir -p /var/lib/ceph/osd/ceph-{osd-id}
lsblk
mkfs -t xfs -f /dev/sda
```

Make a new unit: `var-lib-ceph-osd-ceph\\x2d{osd_id}.mount`
```
[Unit]
Description=OSD-0 Data

[Mount]
What=/dev/sda
Where=/var/lib/ceph/osd/ceph-0
Type=xfs

systemctl daemon-reload
systemctl start var-lib-ceph-osd-ceph\\x2d0.mount
```

To avoid immediate recovery and rebalancing on shutdown an installation of a new osd: `ceph osd set noout`
After restart of all osds: `ceph osd unset noout`



# Cluster Health

```
$ docker run -i -v /etc/ceph:/etc/ceph -t ceph/base ceph status
    cluster e8622249-a406-43d3-a3cb-54d1d5251f22
     health HEALTH_OK
     monmap e3: 3 mons at {core01=192.168.2.2:6789/0,core02=192.168.2.3:6789/0,core03=192.168.2.4:6789/0}, election epoch 12, quorum 0,1,2 core01,core02,core03
     osdmap e10: 3 osds: 3 up, 3 in
      pgmap v22: 192 pgs, 3 pools, 0 bytes data, 0 objects
            15462 MB used, 683 GB / 698 GB avail
                 192 active+clean
```

```
$ docker run -i -v /etc/ceph:/etc/ceph -t ceph/base ceph health
HEALTH_OK
```

