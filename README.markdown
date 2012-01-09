Comment contribuer
==================

Le site est basé sur [nanoc](http://nanoc.stoneship.org/), il est donc recommandé de l'installer pour valider les modifications effectuées sur le site.

Le contenu du site est hébergé sur le repository GITHUB http://github.com/asyd/sysadmin-fr.

Si vous avez les droits en écriture sur le repository GIT
---

    $ git clone http://github.com/asyd/sysadmin-fr

Si vous avez forké le repository GIT
---

Nous travaillons pour l'instant dans la branch "migration". C'est pourquoi c'est celle-ci qu'il faut cloner.

    $ git clone -b migration git@github.com:votreCompte/sysadmin-fr.git
    $ git remote add asyd https://github.com/asyd/sysadmin-fr.git
    $ git fetch asyd

Vous pouvez alors vérifier que votre repository est à jour par rapport à celui d'asyd:

    $ git diff migration asyd/migration

Cette commande ne vous donnera un diff que si il y a eu un commit dans l'un ou l'autre des repositories.
Reste à mettre à jour votre repository avec celui d'asyd, qui reste le repo "officiel":
   
    $ TBD

Une fois que vous êtes content de votre travail, vous avez:
- Commité dans votre repo,
- Pushé ce commit dans votre repo sur github
Il reste à demander à asyd s'il veut bien de votre travail. Il faut pour cela lancer un "pull request" depuis la page de votre repo. Après avoir cliqué sur le bouton "pull request", attention de bien choisir "asyd:migration" comme branch de destination. Par exemple:

    "You're asking asyd to pull 4 commits into asyd:migration from votreCompte:migration"

Edition du contenu
==================

Créer votre articles dans le répertoire articles (ou books s'il va contenir plusieurs pages), au format HTML ou [markdown](http://daringfireball.net/projects/markdown/syntax#). Les images doivent être déposées dans le répertoire images, en créant un sous dossier pour votre article, ou utilisateur. Modifier également la page articles.html pour créer un lien, dans la section adéquate. Pour tester et valider vos modifications, utiliser nanoc :

    $ nanoc view
