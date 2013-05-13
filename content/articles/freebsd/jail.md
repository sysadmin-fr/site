---
title: Les jails sous FreeBSD
short_name: Jails FreeBSD
has_toc: true
image: freebsd-logo.png
is_dynamic: true
---

## Contenu
{{TOC}}

## Introduction

Avec l’accroissement constant de la mutualisation des ressources systèmes, les mécanismes de sécurité UNIX classiques sont rapidement devenus insuffisants. Pour répondre à cette problématique, des mécanismes tels que `chroot(8)` sont apparus afin d’isoler les applications les unes des autres afin d’éviter d’infecter tout un système en cas de compromission de l’une de ces applications.

Cependant `chroot` présente de nombreux inconvénients qui ne permettent pas de garantir une sécurité optimale :

* Restriction uniquement au niveau du système de fichiers (Pas de restriction au niveau des communications inter-processus, des accès à la couche réseau, ni au périphériques)
* Failles de sécurité existantes permettant de sortir relativement simplement du chroot
* Difficulté de mise en œuvre

Ce manque de fiabilité et de flexibilité de chroot à provoqué l’apparition de mécanismes de cloisonnement beaucoup plus robustes tels que :

* Les Zones Solaris
* Les Jails [FreeBSD](http://www.FreeBSD.org/)

C’est ce dernier mécanisme qui va être détaillé au sein de cet article au travers d’une présentation et aussi d’un exemple de mise en œuvre sur système FreeBSD.

## Caractéristiques

La communauté FreeBSD à donc développé le mécanisme de jail permettant de créer des environnements complètement cloisonnés permettant d’héberger soit des applications comme le ferait chroot, soit une instance complète de système FreeBSD construite à partir des sources du système hôte.

Dans cette dernière configuration, le contenu de la jail sera vu comme un vrai système FreeBSD indépendant (modulo les restrictions imposés par la jail) avec sa propre arborescence, ses propres applications installées, ses propres utilisateurs (y compris un super user root) et sa propre configuration.

Le mécanisme jail se décompose en 2 parties : 

1. une primitive système : `jail(2)` ;
2. une commande utilisateur : `jail(8)`.

Les principales fonctionnalités de jail sont les suivantes : 

* Isolation complète par rapport au système hôte (surveillée en permanence par le noyau FreeBSD) et aux autres jails.
* Restriction d’accès au hardware.
* Restriction d’accès au réseau.

A chaque jail crée est affectée un `JID` (Jail Identifier). Chaque processus lancé au sein d’une Jail se verra attribué en plus des attributs UNIX classiques (`PID`, `UID`, `GID`), le `JID` de celle-ci. C’est par l’intermédiaire de ce `JID` que va être déterminée la possibilité de communication entre les processus, la règle étant que seuls des processus ayant le même `JID` peuvent communiquer entre eux.

Il existe cependant une exception à cette règle pour la communication entre les processus d’une jail et le système hôte (qui aura toujours comme `JID` la valeur 0) hébergeant les jails : il est possible pour le système hôte de communiquer avec les processus de n’importe quelle jail (utilisation des commandes jls et jexec par exemple). L’inverse n’est bien évidemment pas possible pour éviter des accès non désirés pouvant permettre la compromission du système hôte.

En plus de ce `JID`, chaque jail dispose d’une adresse IP et d’un hostname correspondant. Chaque processus lancé dans une jail ne peut se binder que sur l’adresse IP de celle-ci sans possibilité d’usurpation d’adresse MAC.

En pratique, l’adresse IP de la jail est montée sur le système hôte et l’appel système jail se charge de la redirection du trafic réseau vers la bonne jail. Il est donc possible ainsi de mettre en place une politique de filtrage réseau par jail au niveau du système hôte.

## Restrictions

Par défaut, il est impossible de faire grand-chose au sein d’une jail y compris pour le root de celle-ci qui n’a que des droits modérés. Voici une liste de ce qu’il n’est pas possible de faire dans une jail si l’on s’en tient à une configuration par défaut :

* Capturer les paquets de l’interface réseau (Par défaut les périphériques `/dev/bpf*` ne sont pas accessibles) ;
* Altérer l’arborescence /dev gérée par devfs ;
* Modifier la configuration réseau ;
* Changer les flags des fichiers ;
* Redémarrer l’instance de la jail.

## Limitations

Le mécanisme de jail présente cependant certaines limitations qu’il est important de connaître afin d’éviter des mauvaises surprises : 

* Pas de possibilité d’affecter plusieurs adresses IPv4
* Pas de possibilité de faire de l’adressage IPv6
* Pas de quota pour le processeur ou la mémoire par jail
* Impossibilité de mettre des quotas disques par utilisateur dans une jail.

## Mise en œuvre par l’exemple


Pour cette mise en œuvre, nous allons procéder à la création d’une jail dans laquelle nous allons déployer un système FreeBSD complet étape par étape. Dans cet exemple, le système hôte sera ares et le système emprisonné delenn.

## Configuration du système hôte

### Configuration des services

La première chose à faire est de s’assurer que tous les services du système hôte n’écoutent pas sur la future adresse IP qui sera réservée à la jail sinon il sera impossible d’accéder à des services utilisant le même couple IP/port sur la jail, les processus du système hôte étant prioritaires.


### Récupération des sources

Pour pouvoir construire la jail, nous allons utiliser les sources du système hôte normalement situées dans le répertoire /usr/src. Si ces sources ne sont pas installées, il est nécessaire de les récupérer depuis un des miroirs FreeBSD.

    ptitoliv@ares$ cvsup -g -L 2 standard-supfile

Note : Il faut que les sources récupérées soient celles de la release FreeBSD déployée sur le système hôte. 

### Mise à jour du système hôte

Il est vivement conseillé que le système hôte soit à jour avec les derniers patches de sécurité avant de commencer le déploiement de la jail. La solution la plus confortable est d’utiliser les sources récupérées précédemment pour faire cette opération. Ainsi les deux systèmes (hôte et jail seront parfaitement identiques en ce qui concerne l’arborescence de base)

### Préparation de la jail

Maintenant que nous disposons de tout ce qui est nécessaire pour installer la jail, nous pouvons procéder à la création et au déploiement de celle-ci. Il faut donc créer un répertoire qui accueillera la jail et dans lequel nous allons installer les sources compilées provenant de /usr/src..

    ptitoliv@ares$ sudo mkdir –p –m 0700 /home/jails/delenn
    ptitoliv@ares$ cd /usr/src
    ptitoliv@ares$ sudo make buildworld
    ptitoliv@ares$ sudo make installworld DESTDIR=/home/jails/delenn
 
Une fois les sources compilées et déployées, il est nécessaire de déployer les fichiers de configuration par défaut à l’intérieur de la jail.

    ptitoliv@ares$ cd /usr/src
    ptitoliv@ares$ sudo make distribution DESTDIR=/home/jails/delenn

Une fois le déploiement terminé, on se retrouve dans le répertoire racine de la jail avec l’arborescence classique d’un système FreeBSD. 

    ptitoliv@ares$ sudo ls -al /home/jails/delenn/
    total 45
    drwxr-xr-x  16 root  wheel   512 May 27 14:45 .
    drwxr-xr-x   3 root  wheel   512 May 27 13:56 ..
    -rw-r--r--   2 root  wheel   801 May 27 14:03 .cshrc
    -rw-r--r--   2 root  wheel   251 May 27 14:03 .profile
    -r--r--r--   1 root  wheel  6193 May 27 14:03 COPYRIGHT
    drwxr-xr-x   2 root  wheel  1024 May 27 14:35 bin
    drwxr-xr-x   5 root  wheel   512 May 27 14:03 boot
    dr-xr-xr-x   4 root  wheel   512 Jul 12 00:17 dev
    drwxr-xr-x  17 root  wheel  2048 Jun 16 20:50 etc
    lrwxrwxrwx   1 root  wheel     9 May 27 14:45 home -> /usr/home
    drwxr-xr-x   3 root  wheel  1024 May 27 14:00 lib
    drwxr-xr-x   2 root  wheel   512 May 27 13:58 libexec
    drwxr-xr-x   2 root  wheel   512 May 27 13:57 mnt
    dr-xr-xr-x   1 root  wheel     0 Sep  1 16:28 proc
    drwxr-xr-x   2 root  wheel  2560 May 27 13:59 rescue
    drwxr-xr-x   2 root  wheel   512 Jun 16 23:20 root
    drwxr-xr-x   2 root  wheel  2560 May 27 14:01 sbin
    lrwxr-xr-x   1 root  wheel    11 May 27 13:57 sys -> usr/src/sys
    drwxrwxrwt   6 root  wheel   512 Sep  1 07:30 tmp
    drwxr-xr-x  15 root  wheel   512 Jun 16 18:55 usr
    drwxr-xr-x  21 root  wheel   512 Jul 12 00:17 var
    
## Configuration de la jail

L’arborescence de la jail étant construire, on passe à présent à la configuration du comportement de celle-ci. C’est ici que l’on va configurer l’adresse IP, le nom d’hôte et toutes les restrictions d’accès. Toutes les directives de configuration des jails doivent être ajoutées au fichier /etc/rc.conf.

Les directives de configurations de jail se décomposent en deux grands ensembles :

* Les directives de configuration générale de toutes les jails ;
* Les directives spécifiques à chaque jail.

Toutes les directives de configuration possibles sont visualisables dans le fichier `/etc/defaults/rc.conf`.
 
Pour notre jail, voici la configuration appliquée dans `/etc/rc.conf` : 

    #####################################################
    # CONFIGURATION GENERAL DU SYSTEME JAIL
    #####################################################
    
    # Activation du mécanisme des jails
    jail_enable="YES"
    
    # Liste des jails déclarées
    jail_list="delenn"            
    
    # Possibilité de changement de l’hostname de la jail
    jail_set_hostname_allow="NO" 
    
    # Possibilité de restriction de protocoles utilisables
    # seulement à TCP/IP
    jail_socket_unixiproute_only="YES"
    
    # Possibilité de restriction des appels IPC
    jail_sysvipc_allow="NO"
    
    #####################################################
    # CONFIGURATION SPECIFIQUE POUR LA JAIL DELENN
    #####################################################
    
    # Racine de l’arborescence de la JAIL
    # ATTENTION : Ne pas mettre de symlinks dans ce path !!!
    jail_delenn_rootdir="/usr/home/jails/delenn"
    
    # Hostname de la jail    
    jail_delenn_hostname="delenn.ptitoliv.net"
    
    # Adresse IP de la jail     
    jail_delenn_ip="192.168.141.42"
    
    # Carte réseau utilisée par la jail
    jail_delenn_interface="rl0"
           
    # Script à exécuter au demarrage de la jail
    jail_delenn_exec="/bin/sh /etc/rc"
    
    # Script à exécuter à l’arret de la jail
    jail_delenn_exec_stop="/bin/sh /etc/rc.shutdown"
    
    # Flags d’exécution de la jail
    # -l : Exécute la jail dans un environnement propre
    # -U root : lancée en tant que root
    # Autres flags pour usage particulier disponibles sur la page de man
    # jail(8)
    jail_delenn_flags="-l -U root"
    
    # Montage des differents filesystems
    jail_delenn_devfs_enable="YES"                 
    jail_delenn_fdescfs_enable="YES"               
    jail_delenn_procfs_enable="YES"                
    
## Accès aux périphériques

Nous avons vu dans la première partie de cet article qu’un des points forts de jail était la possibilité de restreindre l’accès aux périphériques du système hôte. Pour ce faire, il est nécessaire de définir un ruleset contenant la liste des périphériques dont l’accès est autorisé à la jail. 

Tout d’abord, il est nécessaire de définir ce ruleset dans le fichier `/etc/devfs.rules` en s’inspirant fortement de l’exemple fourni par FreeBSD dans le fichier `/etc/defaults/devfs.rules`.


    [jail_rules=4]
    add include $devfsrules_hide_all
    add include $devfsrules_unhide_basic
    add include $devfsrules_unhide_login

Le parsing du ruleset se fait de manière séquentielle c'est-à-dire que les directives sont appliquées les unes à la suite des autres. Voici en détail l’action de chaque directive :

* `$devfsrules_hide_all` : Interdit l’accès à toutes les resources `devfs` ;
* `$devfsrules_unhide_basic` : Autorise l’accès à `/dev/null`, `/dev/zero`, `/dev/random` et `/dev/urandom` ;
* `$devfsrules_unhide_login` : Autorise l’accès aux périphériques gérant les terminaux ainsi que les entrées/sorties.

La politique par défaut de la jail est donc d’interdire l’accès à tous les périphériques puis d’autoriser ceux dont on a besoin.

Une fois le ruleset défini, il faut préciser dans `/etc/rc.conf` que la jail doit l’utiliser avec l’instruction : 

    jail_delenn_devfs_ruleset="jail_rules"  

## Finalisation de la configuration

La configuration de la jail est quasiment terminée. Il ne reste plus qu’à activer les services de base que l’on trouve activés par défaut sur FreeBSD à savoir `ssh` et `syslog` afin que la jail puisse démarrer correctement. On édite donc le fichier `/home/jails/delenn/etc/etc.conf` qui correspond au fichier `/etc/rc.conf` de la jail une fois lancée.

    sshd_enable="YES"
    syslogd_flags="-ss"

## Mise en route de la jail

La jail est à présent configurée et prête à démarrer. La mise en route se fait en deux temps. Il faut d’abord monter l’adresse IP de la jail sur le système hôte. Si ceci n’est pas fait, il sera impossible d’accéder à la jail par TCP/IP.

    ptitoliv@ares$ sudo ifconfig rl0 alias 192.168.141.42

Le démarrage de la jail se fait par l’intermédiaire du script `/etc/rc.d/jail`. Il existe deux façons d’utiliser ce script :

1. Démarrage de toutes les jails déclarées dans /etc/rc.conf avec le paramètre « jail_list » :

    `ptitoliv@ares$ sudo /etc/rc.d/jail start`

2. Sélection des jails à démarrer parmi la liste déclarée avec le paramètre jail_list

    `ptitoliv@ares$ sudo /etc/rc.d/jail start [jail1] [jail2] …`

Les mêmes opérations sont valables pour l’arrêt d’une jail en remplaçant le mot clé `start` par `stop`.

Démarrons donc à présent notre jail : 

    ptitoliv@ares$ sudo /etc/rc.d/jail start delenn
    Configuring jails:.
    Starting jails: delenn.ptitoliv.net.

Afin de vérifier que la jail est bien lancée, FreeBSD met à disposition la commande `jls`. 

    ptitoliv@ares$ sudo jls
    JID IP Address      Hostname                   Path
    16  192.168.141.42  delenn.ptitoliv.net        /usr/home/jails/delenn

## Sécurisation de la jail

A ce stade la, la jail est disponible mais elle n’est pas encore totalement sécurisée. En effet, il n’y a aucun compte utilisateur et le compte root ne dispose pas de mot de passe. Il n’est pas donc encore possible d’accéder à la jail par SSH étant donné qu’aucun compte n’est utilisable pour se connecter.

Nous allons donc utiliser l’outil jexec qui permet d’exécuter une commande à l’intérieur d’une jail depuis le système hôte. Le prototypage de la commande est le suivant : 

    jexec &lt;jid&gt; &lt;commande à exécuter&gt;


Ouvrons donc un shell sur notre jail afin d’initialiser les comptes utilisateurs : 

    ptitoliv@ares$ sudo jexec 16 sh
    # passwd root
    Changing local password for root
    New Password:
    Retype New Password:
    # adduser olivier
    Username: olivier
    Full name: Olivier 
    Uid (Leave empty for default):
    Login group [olivier]: wheel
    Login group is wheel. Invite olivier into other groups? []:
    Login class [default]:
    Shell (sh csh tcsh bash nologin) [sh]:
    Home directory [/home/olivier]:
    Use password-based authentication? [yes]:
    Use an empty password? (yes/no) [no]:
    Use a random password? (yes/no) [no]:
    Enter password:
    Enter password again:
    Lock out the account after creation? [no]:
    Username   : olivier
    Password   : *****
    Full Name  : Olivier BONHOMME
    Uid        : 1002
    Class      :
    Groups     : wheel
    Home       : /home/olivier
    Shell      : /bin/sh
    Locked     : no
    OK? (yes/no): yes
    adduser: INFO: Successfully added (olivier) to the user database.
    Add another user? (yes/no): no
    Goodbye!
    
Les comptes utilisateurs créés, il est a présent possible de se connecter à la jail par `ssh`.

    [ptitoliv@iria ~]$ ssh olivier@192.168.141.42
    Password:
    Last login: Sun Sep  2 13:38:59 2007 from gatekeeper
    Copyright (c) 1980, 1983, 1986, 1988, 1990, 1991, 1993, 1994
            The Regents of the University of California.  All rights reserved.
    
    FreeBSD 5.3-RELEASE (GENERIC) #0: Fri Nov  5 04:19:18 UTC 2004
    
    . . .
    
    $ uname -a
    FreeBSD delenn.ptitoliv.net 5.3-RELEASE FreeBSD 5.3-RELEASE #0: Fri Nov  5 04:19:18 UTC 2004     root@harlow.cse.buffalo.edu:/usr/obj/usr/src/sys/GENERIC  i386
    
Si l’on fait un `top`, on peut voir les processus lancés sur la jail : 

    last pid: 29306;  load averages:  0.14,  0.36,  0.24   up 183+00:16:55 13:53:22
    10 processes:  1 running, 9 sleeping
    CPU states:  2.7% user,  0.0% nice,  0.4% system,  1.2% interrupt, 95.7% idle
    Mem: 595M Active, 85M Inact, 202M Wired, 31M Cache, 110M Buf, 68M Free
    Swap: 967M Total, 533M Used, 434M Free, 55% Inuse
    
      PID USERNAME PRI NICE   SIZE    RES STATE    TIME   WCPU    CPU COMMAND
    27575 root      96    0  3756K  2684K select   0:00  0.00%  0.00% sendmail
    29007 root       4    0  6436K  2792K sbwait   0:00  0.00%  0.00% sshd
    27586 root       8    0  1480K   936K nanslp   0:00  0.00%  0.00% cron
    29010 olivier   96    0  6416K  2844K select   0:00  0.00%  0.00% sshd
    27514 root      96    0  1416K   768K select   0:00  0.00%  0.00% syslogd
    29011 olivier    8    0  1808K  1168K wait     0:00  0.00%  0.00% sh
    29303 olivier   96    0  2296K  1384K RUN      0:00  0.00%  0.00% top
    27569 root       4    0  3684K  2452K select   0:00  0.00%  0.00% sshd
    28540 root       5    0  1764K   864K ttyin    0:00  0.00%  0.00% sh
    27579 smmsp     20    0  3636K  2440K pause    0:00  0.00%  0.00% sendmail

La jail est à présent installée et opérationnelle. Il n’y a plus qu’à administrer celle-ci comme l’on ferait pour un système FreeBSD classique.

## Conclusion

L’objectif de cet article a été de montrer le fonctionnement de jail et ses avantages certains par rapport à d’autres mécanismes comme chroot. Malgré certaines limitations soient présentes, jail permet de mettre en place simplement des applications mutualisées dans des environnements cloisonnés et sécurisés à moindre frais en ce qui concerne la consommation de ressources par rapport aux solutions de virtualisation. Avec l’arrivée de FreeBSD 7.x très prochainement, le système jail va encore s’améliorer et proposer de nouvelles fonctionnalités (telles que la complète indépendance de la couche réseau entre la jail et le système hôte) qui permettront de rendre jail encore plus intéressant dans le cadre de projets systèmes.
