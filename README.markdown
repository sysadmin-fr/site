Comment contribuer
==================

Le site est basé sur [nanoc](http://nanoc.stoneship.org/), il est donc recommandé de l'installer pour valider les modifications effectuées sur le site.

    $ git clone http://github.com/asyd/sysadmin-fr

Créer votre articles dans le répertoire articles (ou books s'il va contenir plusieurs pages), au format HTML ou [markdown](http://daringfireball.net/projects/markdown/syntax#). Les images doivent être déposées dans le répertoire images, en créant un sous dossier pour votre article, ou utilisateur. Modifier également la page articles.html pour créer un lien, dans la section adéquate. Pour tester et valider vos modifications, utiliser nanoc :

    $ nanoc view
