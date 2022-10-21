# Installation et setup

## Installation du compilateur

Pour pouvoir faire fonctionner le compilateur, il faut avoir installé :
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

Une fois que vous avez coder votre fichier en langage `fml` (voir section "Description du langage" pour apprendre à coder en `fml`), par exemple `strategie.fml`, il est très simple de le compiler en un fichier `.brain`. Pour cela, il faut lancer la commande
```bash
$ antsc strategie.fml strategie.brain
```
par défaut, si vous ne spécifiez pas la cible de sortie (`stratégie.brain`), votre fichier compilé sera eccri à l’addresse `cervo.brain`.

## Tests

On peut simpelment effectuer la commande `make test`, qui va compiler les fichiers `.fml` présents dans le dossier `tests`, et les comparer avec des fichiers `.brain` de référence, qui correspondent au résultat attendu. S’il y a une différence entre le résultat de la compilation et le fichier de référence, make lèvera une `Error 1` et indiquera les différences entre le fichier compilé et le fichier de référence. Si il n’y a pas d’erreurs, les fichiers compilés sont ensuite supprimé. S’il y a une erreur, le fichier problématique n’est pas supprimé pour pouvoir l’étudier et le comparer avec le fichier de référence.

Les tests effectués correspondent à des bouts de code à compiler, suffisemment simple pour pouvoir être traduit "à la main", et qui testent une fonction ou une opération (un test pour les if, un test pour les while, etc…). À chaque fichier test `testFonction.fml` correspond un fichier de référence `veriftestFonction.brain`. Lorsque `make test` est appelé, il compile les fichiers `testFonction.fml` en des fichiers `testFonction.brain`, qu’il compare ensuite aux fichiers `veriftestFonction.brain`.

## Coloration syntaxique

On (bébou) a fait un joli plugin de syntax highlighting, comme ça c'est beau, et nos fichiers `.fml` sont donc plus lisible. (On a aussi de l'auto-indentation pour faciliter le dévloppement de stratégies sans erreurs hihi)

# Le langage fml

## Description du langage

Poru créer nos stratégies, nous avons mis au point un langage haut niveau, le `fml`. 

À la base de ce langage, il y a les instructions basiques, qui vont dirrectement affecter le comportement de la fourmi. Elles sont au nombre de 7 :
- nop -> l’opération vide, ne correspond à aucune actio
- move -> la fourmi avance
- turn [direction] -> la fourmi tourne dans la direction `direction`
- pickup -> la fourmi ramasse la nourriture au sol
- marki i -> la fourmi marque la case sur laquelle elle se trouve du marqeur i
- unmark i -> la fourmi retire le marqueur i
- drop -> la fourmi pose la nourriture qu’elle tiens au sol (si elle ne tiens pas de nourriture, elle ne fait rien)

Pour pouvoir manipuler ces opérations, on a accès à plusieurs opérateurs, à savoir 
- `if (<condition>) then {<code>} else {<code>}`. Si on veux ignorer le `else`, on peut utiliser l’opérateur `nop`.
- `while (<condition>) do {<code>}`.

Les `<condition>` à mettre dans les `if`et les `while`peuvent prendre plusieurs formes :
- `= <direction> <valeur>`, qui est vrai si l’élément dans la direction `direction` est bien `valeur`. Par exemple, `= ahead friend`.
- `!= <direction> <valeur>`, qui fonctionne comme le `=` mais dans l’autre sens
- `random <entier>` qui est vrai avec une probabilité de `1/<entier > `

## Exemples
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

## Optimisation

Après avoir effecuté notre compilation, nous procédon à une étape de post-compilation, qui est assez simple : On cherche, dans code final en `.brain` des blocs de la forme :
````
label_p:
  Goto label_q
````
puis on remplace toutes les occurences de `label_p` par des `label_q`, et on supprime le bloc. Ce procédé permet donc de supprimer ces blocs qui sont non seulement inutiles et prennent de la place, mais qui en plus ralentissent la fourmi.

# Fonctionnement de la stratégie

On va chercher la nourriture, puis on la ramène à la maison. Ensuite, on gagne.


