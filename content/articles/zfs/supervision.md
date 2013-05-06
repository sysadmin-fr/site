---
title: Supervision ZFS
is_dynamic: true
---

## Table de contenu
{{TOC}}

Vous aussi vous êtes intéressé par ZFS ? Vous trouvez génial ce système de fichier / gestionnaire de volume, vous l'utilisez déjà, et vous voulez en connaître un peu plus sur la supervision d'un pool zfs ? Alors cet article est pour vous.</p>

## Introduction

Attention, j'ai rédigé cet article à partir de tests d'OpenSolaris, notamment les build 55, puis un upgrade vers le ON du 30 Juillet 2007, certaines fonctionnalités utilisées ne sont donc disponible dans Solaris 10 (update 3), et problablement dans des versions inférieures d'OpenSolaris.</p>

## Les commandes utiles

### La commande `zpool`

Celle là, vous la connaissez forcément, ne serait-ce que pour la création du zpool. D'ailleurs, à ce propos, noter que dans  les commandes `create`, `add`, `replace` vous pouvez chaîner les différents types de zpool, comme par exemple la commande :

    # zpool create data mirror c5t0d0 c6t0d0 mirror c7t0d0 c8t0d0

créée automatiquement un stripping (RAID-0) de deux miroirs (RAID-1).

Néanmoins, la principale commande qui m'intéresse pour cet article est la commande <i>zpool iostats</i> qui me permet d'afficher la consommation d'IO aussi bien sur l'ensemble du <i>pool</i> que sur chaque périphérique. Pour ma part, sans l'argument <i>interval</i>, je ne trouve pas que cette commande soit vraiment pertinente, par contre, dès que l'on fais quelque chose du genre :</p>

    # zpool iostat -v data 1

on obtiens quelque chose de très intéressant :

                   capacity     operations    bandwidth
    pool         used  avail   read  write   read  write
    ----------  -----  -----  -----  -----  -----  -----
    data         602M  3.16G      0     51      0  6.43M
      raidz1     602M  3.16G      0     51      0  6.43M
        c5t0d0      -      -      0     25      0  2.15M
        c6t0d0      -      -      0     25      0  2.15M
        c7t0d0      -      -      0     25      0  2.15M
        c8t0d0      -      -      0     26      0  2.23M
    ----------  -----  -----  -----  -----  -----  -----

### kstat / mdb

Ces deux commandes permettent d'interroger des variables noyaux, dans notre cas, on s'intéresse au module arc (qui correspond à la gestion du cache) de ZFS.

    -bash-3.00# kstat 'zfs:0:arcstats'
    module: zfs                             instance: 0
    name:   arcstats                        class:    misc
        c                               489160704
        c_max                           489160704
        c_min                           67108864
        crtime                          47.134895524
        deleted                         75
        demand_data_hits                0
        demand_data_misses              0
        demand_metadata_hits            682
        demand_metadata_misses          105
        evict_skip                      0
        hash_chain_max                  1
        hash_chains                     16
        hash_collisions                 17
        hash_elements                   1395
        hash_elements_max               1396
        hits                            682
        mfu_ghost_hits                  8
        mfu_hits                        61
        misses                          105
        mru_ghost_hits                  8
        mru_hits                        621
        mutex_miss                      0
        p                               244580352
        prefetch_data_hits              0
        prefetch_data_misses            0
        prefetch_metadata_hits          0
        prefetch_metadata_misses        0
        recycle_miss                    0
        size                            176953964
        snaptime                        1543.649408772

### Quelques variables utiles :

* `hits` Le nombre de demandes d'IO qui sont gérées par ARC
* `misses` Le nombre de demandes d'IO qui n'ont pas été gérées par arc
