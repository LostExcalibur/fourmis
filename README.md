# Installation et setup

## Installation du compilateur

Poru pouvoir faire fonctionner le compilateur, il faut avoir installé :
- OCaml, version 4.08 ou plus
- Le système de construction `dune` version 1.11 ou plus (installable avec `opam install dune`)
- `ocp-indent` et `ocamlfind` (installable avec `opam install ocp-indent ocamlfind`)

Avant toutes choses, il faut exécuter la commande
```bash
$ make deps
```
dans ce dossier, depuis un terminal. Vous pouvez tester que le programme `simple-parser-gen` à bien été installé à l’aide de la commande
```bash
$ simple-parser-gen --help
```
Il vous faut ensuite compiler le compilateur. Pour ce faire, il suffit d’exécuter la commande
```bash
$ make
```

Et voilà ! Vous avez maintenant le fichier executable `antsc`, votre compilateur !


## Comment compiler un fichier `.fml`

Une fois que vous avez coder votre fichier en langage `fml` (voir section "Le langage fml" pour apprendre à coder en `fml`), par exemple `strategie.fml`, il est très simple de le compiler en un fichier `.brain`. Pour cela, il faut lancer la commande
```bash
$ ./antsc strategie.fml -o strategie.brain
```
par défaut, si vous ne spécifiez pas la cible de sortie (`stratégie.brain`), votre fichier compilé sera écrit à l’addresse `cervo.brain`. On peut également utiliser `-O` au lieu de `-o` pour compiler en une version optimisée (voir section Optimisation).

## Tests

On peut simpelment effectuer la commande 
```bash
$ make test
```
qui va compiler les fichiers `.fml` présents dans le dossier `tests`, et les comparer avec des fichiers `.brain` de référence, qui correspondent au résultat attendu. S’il y a une différence entre le résultat de la compilation et le fichier de référence, make lèvera une `Error 1` et indiquera les différences entre le fichier compilé et le fichier de référence. Si il n’y a pas d’erreurs, les fichiers compilés sont ensuite supprimé. S’il y a une erreur, le fichier problématique n’est pas supprimé pour pouvoir l’étudier et le comparer avec le fichier de référence.

Les tests effectués correspondent à des bouts de code à compiler, suffisemment simple pour pouvoir être traduit "à la main", et qui testent une fonction ou une opération (un test pour les if, un test pour les while, etc…). À chaque fichier test `testFonction.fml` correspond un fichier de référence `veriftestFonction.brain`. Lorsque `make test` est appelé, il compile les fichiers `testFonction.fml` en des fichiers `testFonction.brain`, qu’il compare ensuite aux fichiers `veriftestFonction.brain`.

## Coloration syntaxique

Pour obtenir la coloration syntaxique dans vim, il suffit d’utiliser la commande
```
$ make vim
```

# Le langage fml

## Description du langage

Poru créer nos stratégies, nous avons mis au point un langage haut niveau, le `fml`. 

À la base de ce langage, il y a les instructions basiques, qui vont dirrectement affecter le comportement de la fourmi. Elles sont au nombre de 7 :
- `nop` -> l’opération vide, ne correspond à aucune actio
- `move` -> la fourmi avance
- `turn <direction>` -> la fourmi tourne dans la direction `direction`
- `pickup` -> la fourmi ramasse la nourriture au sol
- `marki i` -> la fourmi marque la case sur laquelle elle se trouve du marqeur i
- `unmark i` -> la fourmi retire le marqueur i
- `drop` -> la fourmi pose la nourriture qu’elle tiens au sol (si elle ne tiens pas de nourriture, elle ne fait rien)

Pour pouvoir manipuler ces opérations, on a accès à plusieurs opérateurs, à savoir 
- `if (<condition>) then {<code>} else {<code>}`. Si on veux ignorer le `else`, on peut utiliser l’opérateur `nop`.
- `while (<condition>) do {<code>}`.

Les `<condition>` à mettre dans les `if`et les `while`peuvent prendre plusieurs formes :
- `= <direction> <valeur>`, qui est vrai si l’élément dans la direction `direction` est bien `valeur`. Par exemple, `= ahead friend`.
- `!= <direction> <valeur>`, qui fonctionne comme le `=` mais dans l’autre sens
- `random <entier>` qui est vrai avec une probabilité de `1/<entier > `

On peut également combiner ces conditions avec des opérateurs `et` et `ou` avec la syntaxe suivante : `et (<condition1>) (<condition2>)`

Le langage `fml` permet également la construction de macro. Attention, il faut toujours définir les macros en haut du fichier, avant de les appeler. La syntaxe des macros est simple :
```
macro <nom de la macro> = {
	<code>
}
```
Et, pour appeler une macro précédemment définie, il suffit d’utiliser l’instruction `call <nom de la macro>`.


On peut d’ailleurs définir ces macros dans un autre fichier, par exemple dans `macros.fml`. Ensuite, dans notre fichier principal `strategie.fml`, il suffit de le commencer par `include macros`, et on a alors accès à toutes les macros.

## Exemple
Un exemple de code fml peut se trouver à l’adresse `exemple.fml` dans le dossier principal. Le code ressemble à ceci :
```
while (!= here food) do {
        if (random 2) then {
                turn left;
                move
        }
        else {
                turn right;
                move
        }
};
pickup;
while (!= here home) do {
        if (= leftahead home) then {
                turn left;
                move
        }
        else {
        if (= rigthahead home) then {
                turn right;
                move
        }
        else {
                move
        }
        }
};
drop;
move
```



# Compilateur

Le fonctionnement du compilateur est assez transparent pour la plupars des instructions. Il y a cependant quelques points intéressant à relever. La compilation d’un if simple, par exemple `if (= leftahead friend) then {drop} else {nop}` donnerait 
```
debut:
  Sense LeftAhead label_0 label_1 Friend
label_0:
  Drop
  Goto label_2
label_1:
  Goto label_2
label_2:
  Goto debut
```
Ensuite, on se sert de cette base pour construire les `if (et (<condition1>) <(condition2>))`, les `if (ou (<condition1>) (<condition2>))` et les `while (<condition>)`.

Pour compiler un `if (et (<condition1>) (<condition2>)) then {<expression1>} else {<expression2>}`, on compile, avec ce qu’on à fait pour le `if` simple, le code suivant :
```
if (<condition1>) then {
	if (<condition2>) then {
		<expression1>
	}
	else {
		<expression2>
	}
} else {
		<expression2>
}
```

On peut utiliser le même procédé pour compiler des `if (ou)`.


Pour la compilation des `while` se base sur la compilation d'un if. En effet, on compile `while (<condition>) do {<expression>}` en compilant un `if (<condition>) then {<expression>} else {break i+1}` entre un `Goto label_i \n label_i :` et un `Goto label_i \n label_i+1 :`. Par exemple, le code `while (!= ahead rock) do {move}` se compile en :

```
debut :
  Goto label_0
label_0 :                               ; début de la boucle while
  Sense Ahead label_3 label_2 Rock      ; début du if
label_2 :
  Move label_5
  Goto label_5
label_5 :
  Goto label_4
label_3 :
  Goto label_1                          ; break i
label_4 :                               ; fin du if
  Goto label_0                          ; retour au début de la boucle while
label_1 :                               ; label après le while
  Goto debut
```

## Optimisation

Après avoir effectué notre compilation, nous procédons à des étapes de post-compilation, qui permettent à la fois de réduire la taille du fichier de sortie, mais également de réduire le nombre d’opération "inutiles" (et donc d’accélérer nos fourmis).

Grace à ces optimisations, on arrive à réduire la taille du fichier d’une vingtaine de pourcents.

### Remplacement des label -> Goto

La première optimisation est assez simple : On cherche, dans code final en `.brain` des blocs de la forme :
````
label_p:
  Goto label_q
````
puis on remplace toutes les occurences de `label_p` par des `label_q`, et on supprime le bloc. Ce procédé permet donc de supprimer ces blocs qui sont non seulement inutiles et prennent de la place, mais qui en plus ralentissent la fourmi.

### Remplacement des label -> Flip et des label -> Sense

Ensuite, on cherche dans le code final `.brain` des blocs de la forme :
````
label_a:
  Flip ... label_b label_c
````
et on remplace le `Goto label_a` par le `Flip ...` (fonctionne aussi avec un `Sense`).



On va chercher la nourriture, puis on la ramène à la maison. Ensuite, on gagne.
# Fonctionnement de la stratégie

Notre stratégie fonctionne en divisant les fourmis en groupes, chacuns ayant une tache spécifique :
- Les fourmis qui démarrent à la bordure de la base obtiennent le rôle de "gardien". Leur tâche est de créer un cordon de sécurité autour de la base pour empêcher les ennemis d’entrer. Elles doivent également récupérer la nourriture que les travailleuses et les voleuses vont poser devant la base.
- Les fourmis travailleusent vont chercher des sources de nourriture, puis les ramènes à la base.
- Les fourmis voleusent vont chercher la base ennemi, et s’en servent comme source de nourriture.
