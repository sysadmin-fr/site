# Description

Cet article a pour objectif de donner une première approche à l'utilisation de Nexus. 
Nexus est un serveur qui délivre des 

Nexus gère trois types de dépôts :

 * local (hosted) c'est là que l'on va déployer nos propres artefacts
 * proxy, il permet de définir des dépôts distants (par exemple ceux de maven.org), et agira en tant que proxy pour les artefacts téléchargés
 * virtual, 

Par défaut Nexus vient avec un certain nombre de définitions de dépôts, notamment pour les proxy.

# Installation de nexus

Rien de particulier, pour ma part j'utilise aussi bien la version bundle que la version WAR. Pour la première il suffit d'extraire et de lancer Nexus avec le script qui va bien dans `bin/jsw/<platform>/nexus`. Le port d'écoute par défaut est le 8081. Pour une version de production, n'oubliez pas de changer le mot de passe du compte administrateur.

# Utilisation du nexus comme proxy dans maven

S'il n'existe pas déjà, crée le fichier `~/.m2/settings.xml` et rajouter la section suivante :

	<mirrors>
  		<mirror>
    		<id>nexus</id>
    		<mirrorOf>*</mirrorOf>
    		<url>http://localhost:8081/nexus/content/groups/public</url>
  		</mirror>
	</mirrors>

Désormais, lors que vous exécuterez maven, il ira télécharger depuis Nexus, qui agira en tant que proxy ce qui va donc grandement accélérer les temps de build, d'autant plus si votre serveur est LAN.

# Publier des artifacts avec maven

## settings.xml

Dans le fichier `~/.m2/settings.xml`, rajouter la section suivante pour définir les credentials de notre nexus :

    <servers>
        <server>
            <username>admin</username>
            <password>xxx</password>
            <id>opencsi</id>
        </server>
        <server>
            <username>admin</username>
            <password>xxx</password>
            <id>opencsi-snapshot</id>
        </server>
	

## pom.xml

Dans le fichier `pom.xml` des projets que nous voulons publier dans Nexus, rajouter la configuration suivante :

    <repositories>
      <repository>
         <id>opencsi-snapshot</id>
         <url>http://dev.opencsi.com/nexus/content/repositories/opencsi-snapshot/</url>
      </repository>
    </repositories>

Inutile de dire que les deux id doivent correspondre.

## 

Pour publier votre projet, il suffira de faire un :

    mvn deploy

# Autres commandes utiles

## Publier un fichier 

Vous désirez compiler un projet maven qui utilise 

    mvn deploy:deploy-file -Durl=http://dev.opencsi.com/nexus/content/repositories/picketlink-snapshot/ -DrepositoryId=picketlink-snapshot -Dfile=picketlink-core-2.1.1.Final.jar -DgroupId=org.picketlink -DartifactId=picketlink-core -Dversion=2.1.2-SNAPSHOT -Dpackaging=jar

  