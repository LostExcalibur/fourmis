# Description du langage

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
- `!= <direction> <valeur>`, qui fonctionne comme 


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


# Syntax Highlight

On (bébou) a fait un joli plugin de syntax highlighting, comme ça c'est beau, et nos fichiers `.fml` sont donc plus lisible. (On a aussi de l'auto-indentation pour faciliter le dévloppement de stratégies sans erreurs hihi)

