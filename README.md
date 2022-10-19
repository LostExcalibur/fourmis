# Description du langage

Poru créer nos stratégies, nous avons mis au point un langage haut niveau, le `fml`. Ce langage est composé de plusieurs constructeur :
	- Et un type program, qui correspond à l'ensemble du programme.
	- De type expression
	- De type commande
	- De type condition
	- De type valeur
	- De type direction
	- De type lr (les républicains, ou left-right)

Ces types peuvent être comoposés les uns avec les autres :
	- Le type programme correspond à un ensembles d'expressions, toutes séparées par des `;`
	- Le type expression comporte différent opérateurs :
		-- Do, une expression qui correspond à une commande
		-- MoveElse, une expression qui comporte une autre liste d'expression : la fourmi bouge, et si elle ne peut pas effectuer ce mouvement, on execute les expressions.
		-- PickElse, la même chose mais pour récupérer de la nourriture au sol.
		-- IfThenElse, de la forme `if (condition) then {liste d'expression} else {liste d'expression}, qui est assez descriptive.
		-- While, de la forme `while (condition) do {liste d'expressions}, assez clair aussi
		-- Macro, qui défini une macro avec la syntaxe `macro nom_de_la_macro : liste_dexpressions `
		-- Call, qui appelle la macro nommée.
	- Le type commande, qui correspond à des instruction basiques. Il comprend les instructions suivantes :
		-- nop -> aucune opération, ne fait rien
		-- move -> la fourmi avance
		-- turn lr -> la fourmi tourne dans la direction lr
		-- pickup -> ramasse la nourriture au sol
		-- mark i -> pose un marqueur de phéromones i
		-- unmark i -> enlève le marqueur de phéromones i
		-- drop -> pose la nourriture
	- Le type condition, qui se trouve dans les expression `if`et `while`. Il existe trois variantes possibles :
		-- =, qui s'utilise avec la syntaxe suivante `(= direction valeur)`, qui vérifie si ce qui se trouve dans la directiont `direction` correspond bien à la valeur `valeur`.
		== !=, qui s'utilise avec la syntaxe suivante `(!= direction valeur)`, qui vérifie si ce qui e trouve dans la direction `direction` est différent de la valeur `valeur`
		-- random, qui s'utilise avec la syntaxe `(random n)`, et qui est vrai avec une probabilité de 1/n



# Fonctionnement de la stratégie

On va chercher la nourriture, puis on la ramène à la maison. Ensuite, on gagne.


# Syntax Hilight

On (bébou) a fait un joli plugin de syntax highlighting, comme ça c'est beau, et nos fichiers `.fml` sont donc plus lisible. (On a aussi de l'auto-indentation pour faciliter le dévloppement de stratégies sans erreurs hihi)
