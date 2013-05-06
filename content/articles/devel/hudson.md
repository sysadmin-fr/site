---
title: Intégration continue avec Hudson
is_dynamic: true
---

## Table de contenu
{{TOC}}

## Introduction

Dans le cadre de projets de développement logiciels réalisés par une équipe plus ou moins conséquente, l'évolution du code source de l'application est répartie entre ces plusieurs personnes. Le fait que chaque partie du code soit à la charge d'une personne différente, peut entrainer des régressions, des conflits ou bien tout simplement des bugs fonctionnels lors de la mise en commun des différentes parties du code (En particulier si chacun travaille dans son coin et que la communication dans l'équipe de développement n'est pas forcément le maitre mot).


Le résultat souvent constaté est donc que le code de chaque développeur fonctionne très bien indépendamment du reste mais lors du merge on peut constater des bugs pouvant aller du simple bug/fait amusant à une catastrophe complète. Cet état à la fâcheuse tendance d'entrainer des surcouts de développement importants afin de faire fonctionner l'applicatif final avec toutes les parties de code mergées.

L'objectif de cet article est donc de présenter un concept de génie logiciel permettant d'éviter cet état de fait mais aussi de voir comment l'on peut mettre ceci en application dans le cadre d'un projet de développement.

Cet article évoquera donc brièvement le concept d'intégration continue ainsi que l'outil Hudson permettant de mettre en oeuvre ce concept.

## Intégration Continue

>Afin de présenter le concept d'intégration continue, je vais citer la définition présente sur Wikipedia qui résume très bien l'idée de base.

>L'intégration continue est une technique utilisée en génie logiciel.

>Elle consiste à vérifier à chaque modification de code source que le résultat des modifications ne produit pas de régression de l'application en cours de développement. Bien que le concept existait auparavant, l"intégration continue" se réfère généralement à la pratique de l'extreme programming.

>Pour appliquer cette technique, il faut d'abord que :

>* le code source soit partagé (en utilisant des logiciels de gestion de versions tels que CVS ou Subversion)
>* les développeurs intègrent (commit) quotidiennement (au moins) leurs modifications
>* des tests d'intégration soit développés pour valider l'application (avec JUnit par exemple)

>Les principaux avantages d'une telle technique de développement sont :

>* les problèmes d'intégration sont détectés et réparés de façon continue, évitant les problèmes de dernière minute
>* prévient rapidement en cas de code incompatible ou manquant
>* test immédiat des unités modifiées
>* une version est toujours disponible pour test, démonstration ou distribution


Source : 
[Lien vers Wikipedia](http://fr.wikipedia.org/wiki/Int%C3%A9gration_continue)

## Hudson

### Présentation

Hudson est un logiciel écrit en Java. Il s'agit d'une application WEB accessible et utilisable avec un simple navigateur que ce soit pour l'administration ou l'utilisation.

Hudson permet de mettre en oeuvre tous les mécanismes du concept d'intégration continue à savoir : 

* Faire du polling depuis un SCM (Source Code Management) pour détecter les mises à jour faites au niveau du code source ;
* Réaliser un build du code source récupéré dans le SCM soit dès qu'un changement est detecté au niveau des sources (Nouveau Commit effectué) soit à intervalles réguliers sans se soucier de la présence de nouveaux commits ou non ;
* Alerter un contact unique et/ou les committers concernés dans le cas d'un build instable ou incorrect ;
* Mise à disposition du résultat des builds corrects pour utilisation (Notion d'artifact).

L'équipe de développement de ce logiciel est très active et sort régulièrement de nouvelles versions apportant son lot d'améliorations et d'évolutions. On notera également la présence d'un système de plugins permettant d'ajouter de nouvelles fonctionnalités à hudson comme par exemple le support de nouveaux SCM (comme Git par exemple) ou bien l'intégration avec un bug tracker en cas de build échoué.

Le logiciel se présente sous la forme d'une archive WAR que l'on peut déployer de deux façons :

* Déploiement sous forme d'un Web Service dans un serveur Tomcat ou bien Jetty
* Fonctionnement en mode Standalone. Le WAR intègre le mini serveur Web Winstone permettant de faire fonctionner Hudson sans application externe

### Installation

L'installation du logiciel est relativement simple si l'on considère le mode standalone (Utilisation du serveur WEB integré). 

Le seul prérequis est de disposer d'une version de java récente comme par exemple : 

    hudson@stardust:~$ java -version
    java version "1.5.0_10"
    Java(TM) 2 Runtime Environment, Standard Edition (build 1.5.0_10-b03)
    Java HotSpot(TM) Server VM (build 1.5.0_10-b03, mixed mode)

Pour l'installation proprement dite, il suffit de suivre la procédure suivante : 

* Téléchargement de la dernière version stable sur le site officiel <a href="http://hudson.dev.java.net">http://hudson.dev.java.net</a>
* Création d'un workspace directory dans lequel Hudson va être exécuté mais aussi ou vont être réalisé et stockés tous les builds pour les differents projets (Exemple : `/var/hudson`)

Le WAR de Hudson (nommé hudson.war) peut être stocké n'importe où comme par exemple `/usr/local/bin/hudson.war`, mais cette localisation peut être changée par l'administrateur de la machine.

Pour exécuter hudson en mode standalone, il suffit de lancer la commande suivante : 

    java -jar hudson.war

Si tout est correct, Hudson devrait être accessible par l'adresse `http://<ip>:8080`.

Remarque : Un script de démarrage pour `/etc/init.d` est disponible sur le site de Hudson. Ce script est RedHat/Fedora compliant. Cependant, un portage pour Debian est disponible en pièce jointe sur ce billet.

### Utilisation

Sous Hudson, chaque projet de développement est appelé un Job. Pour mettre en place un mécanisme d'intégration continue pour un projet, il suffit donc de créer un nouveau job.

Chaque job sera identifié par un nom et un type, le type pouvant être un des 4 suivants :

* Free Software Project ;
* Projet Maven2 (Permet de faire un build en bénéficiant de toutes les fonctionnalités du gestionnaire de configuration et de développement Maven) ;
* Projet Multi-Configuration (Permet de gérer des projets déployables sur des configurations multiples et variés tel que des architectures matérielles differentes par exemple ou bien des environnements différents ;
* Surveillance d'un job externe.

Pour cet article, nous considérons l'utilisation du template <q>Free Software Project</q> afin de compiler une application écrite en C et déroulant une chaine de compilation classique pour ce genre de projet (Utilisation de make ou de cmake)

Une fois le type de projet sélectionné, on passe donc à l'étape suivante qui consiste à configurer le job lui même. C'est à ce niveau de la configuration que l'on va sélectionner le SCM à utiliser, les instructions à exécuter pour dérouler la chaine de compilation etc. etc.

Voyons en détail les informations importantes à renseigner pour la configuration d'un job :

* Name / Description : Spécification du nom du job et d'une description détaillée
* Discard old builds : Hudson conserve une trace de tous les builds réalisés. Il est cependant possible de supprimer les builds les plus anciens. Il est possible de préciser soit le nombre maximum de builds a conserver ou bien un nombre maximum de jours pendant lequel les builds doivent être conservés.
* Source Code Management : Permet de spécifier le SCM à utiliser. Par défaut, il n'est possible d'utiliser que CVS ou SUBVERSION. Cependant, il existe un certains nombre de plugins permettant de rajouter des SCM (comme par exemple GIT). En plus du SCM, on spécifiera bien evidemment l'URL d'accès du module correspondant au projet.
* Build Triggers : C'est dans cette section que l'on va configurer la manière dont va être réalisé le build du job. Il existe plusieurs manière de lancer l'exécution d'un build :

  * Lancer l'exécution du build après que le build d'un autre job ait été exécuté. On spécifiera le nom du ou des jobs Hudson en paramètre ==> Option Build after other projects are built
  * Lancer l'exécution du build lorsque des nouveaux commits seront enregistrés au niveau du SCM ==> Option Poll SCM. On spécifiera sous forme d'une entrée crontab l'intervalle de temps entre 2 consultations du SCM pour vérifier la présence de nouveaux commits.
  * Lancer l'exécution du build à intervalles réguliers indépendamment de l'état du code source dans le SCM. On spécifiera l'intervalle de temps entre 2 builds sous forme d'une entrée crontab.

* Build : C'est dans cette section que l'on va spécifier les différentes directives à exécuter pour dérouler la chaine de génération du build. Il est possible de spécifier plusieurs types de directives :

  * Execute Shell : Execution de commandes shell UNIX
  * Execute Windows Batch Command : Execution de commandes Windows
  * Invoke Ant : Permet de spécifier une cible ANT
  * Invoke Top Level Maven targets : Permet de spécifier une cible MAVEN

* Post-install actions : Cette section permet de décrire toutes les taches à réaliser après l'exécution d'un build (que celui-ci soit correct ou non). On pourra donc par exemple :

  * Archive the artifacts : Permet de sélectionner les resultats du build à conserver. Les fichiers retenus seront accessible en téléchargement depuis la page de résultat de chaque build.
  * Record fingerpints of files to track usage : Permet d'apposer une empreinte digitale sur chaque fichier résultats pour des besoin de tracking.
  * Publish Javadoc : Generation de la javadoc associée au projet
  * Publish JUnit Test Report : Génération des fichiers resultats de tests unitaires générés par JUnit. (Utiles uniquement pour les projets JAVA)
  * Build other projects : Déclenche l'exécution d'autres projets Hudson une fois le build du projet courant exécuté
  * E-mail Notifications : Si cette option est active, un mail d'alerte sera envoyé en cas d'une opération de build échouée. Les mails seront envoyés soit à une liste de destinataires spécifiées en paramètre soit au commiter responsable du build erroné (Attention : Cela implique que chaque commiter ait une adresse valide. Pour celà, il faut renseigner au niveau de la gestion des utilisateurs les adresses email au fur et a mesure que hudson les detecte lors de l'interrogation du SCM.

Une fois toutes ces informations renseignées, le job Hudson est prêt à être exécuté. Si l'on revient à la  page d'accueil, Hudson présente un tableau résumé de tous les projets avec leur status (Stabilité, Date du dernier build realisé avec succès, date du dernier build échoué, durée d'exécution du build)

Lorsque l'on sélectionne un projet particulier, on tombe sur la page de status du projet sur laquelle on retouve les informations et les fonctionnalités suivantes : 

* Visualisation de la copie locale courante extraite du SCM utilisée pour réaliser les build
* Visualisation des derniers changements commités dans le SCM (Recent Changes)
* Déclenchement de l'exécution d'un build
* Modification de la configuration du job

Un des éléments importants de cet écran est la liste des builds. Pour chaque build, on peut connaitre son status (Bleu : Génération avec succès, Rouge : Erreur lors de la génération, Rouge Clignotant : En cours d'exécution)

On remarque également la présence de flux RSS auxquels on peut s'abonner avec son lecteur préféré. Pour chaque projet, on aura les deux flux RSS suivants : 

* Un flux contenant la liste de tous les builds ;
* Un flux contenant la liste de tous les builds erronés.

Chaque build dispose également d'une page de statut dans laquelle on peut retrouver diverses informations concernant le build telles que :

* Une description des changements commités depuis le dernier build ;
* Une trace console des commandes exécutées lors de la génération du build. Cette fonctionnalité est très utile pour débugger et comprendre les causes d'un build incorrect.

On notera la présence d'une barre de navigation de type Previous / Next très pratique pour naviguer entre les différents builds d'un même projet.

## Administration

Pour terminer cette présentation, il est important de parler un petit peu de l'administration générale de l'applicatif. Toutes les options de configuration générale sont accessibles depuis la page d'accueil par l'option de menu <q>Gérer Hudson</q>.

On passera rapidement sur la configuration générale du système qui est relativement simple. Accessible par l'option <q>System Configuration</q>, cette section nous permet de configurer tous les paramètres généraux tels que les chemins d'accès, le serveur SMTP de sortie pour envoyer les mails, le nombre de tâches exécutables en parallèles etc. etc. 

Pour chaque option de menu (comme pour tout le reste de l'applicatif d'ailleurs), une aide contextuelle relativement riche est disponible pour chaque option de configuration.

Un des points forts de Hudson est son système de plugins permettant d'enrichir le fonctionnement de base de Hudson. Grâce à ce système dont la configuration est accessible par le menu <q>Manage Plugins</q>, il est possible d'ajouter des fonctionnalités telles que la gestion de nouveaux SCM, la connexion avec un bug tracker de type TRAC, la remontée d'alertes sur les builds par l'intermédiaire d'un bot IRC et bien d'autres possibilités.

La liste de tous les plugins existants est disponible à l'adresse suivante : 


[Hudson Plugins](https://hudson.dev.java.net/servlets/ProjectDocumentList?expandFolder=5818&folderID=0)

Les plugins installables sont au format HPI (Maven package) afin de faciliter l'installation. Pour ajouter un plugin, il suffit d'uploader celui-ci par l'intermédiaire du formulaire prévu à cet effet, de redémarrer hudson et c'est fait : la nouvelle fonctionnalité est disponible.

Un exemple concret : Le support du SCM GIT. Par défaut, hudson ne supporte que CVS et SVN. Le simple ajout du plugin git permet de s'interfacer simplement et efficacement avec un repository GIT.

Note : Actuellement il n'existe pas de versions téléchargeable du plugin GIT, celui-ni n'étant disponible que dans le sources pour le moment. Cependant, une version au format HPI fonctionnelle est disponible en pièce jointe attachée à ce billet.

Pour terminer, un petit mot sur la gestion des personnes. Il est en effet possible de créer des utilisateurs dans hudson. Ces utilisateurs peuvent être utilisés soit pour faire de la sécurité, soit pour identifier les committers sur un projet donné.

Hudson propose une création automatique d'utilisateurs en fonction de la détection de nouveaux commiters dans le SCM ce qui est très pratique sur de gros projets. Ce sont ces comptes utilisateurs qui seront utilisés pour identifier les différents commiters dans les différentes sections de hudson.

Il est important de vérifier régulièrement que les adresses e-mail sont correctement remplies afin d'être sur que les commiters reçoivent bien les mails d'alerte les concernant. Normalement hudson est capable de le faire tout seul mais dans certains cas, les adresses e-mail sont mal renseignées au niveau des comptes utilisateurs.


### Conclusion

Cet article a donc présenté le principe d'intégration continue ainsi que le fonctionnement d'hudson. Cependant, il n'a été présenté ici que les fonctionnalités de base et les possibilités d'exploitation semblent importantes. Hudson est un outil très performant et très evolutif permettant de gérer des projets importants.


Malgré son orientation claire pour les projets java, Hudson s'avère très puissant pour faire de l'intégration continue d'applicatifs et même de drivers développés en C. De plus son interface WEB conviviale et sa rapidité de mise en place sont très appréciables : on peut en effet avoir un hudson opérationnel et un build fonctionnel en très peu de temps.

De plus, la constante evolutivité du projet tant au niveau du développement de l'application elle même que l'ajouts de nouvelles fonctionnalités au travers de l'ajout de nouveaux plugins en font un outil très maniable.

Un outil donc à conseiller pour nos amis les développeurs.
