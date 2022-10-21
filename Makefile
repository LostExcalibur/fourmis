### Définitions de variables ###

# Le fichier contenant la grammaire du langage.
GRAMMAR=src/lang.grammar
# Les sources.
SRC=$(wildcard src/*)

# Les fichiers du parser sont générés automatiquement avec l'outil
# `simple-parser-gen`.
PARSER_GEN=simple-parser-gen
PARSER_FILES=src/ast.mli src/ast.ml src/lexer.mli src/lexer.ml src/parser.mli src/parser.ml

### Règles de constructions ###

antsc: $(PARSER_FILES) $(SRC) $(GRAMMAR)
	dune build @install
	@cp _build/install/default/bin/antsc $@

# Interface du module Ast contenant la définition de l'arbre de syntaxe abstraite.
src/ast.mli: $(GRAMMAR)
	$(PARSER_GEN) -a -i $^ | ocp-indent > $@

# Module Ast.
src/ast.ml: $(GRAMMAR)
	$(PARSER_GEN) -a $^ | ocp-indent > $@

# Interface du module Lexer.
src/lexer.mli: $(GRAMMAR)
	$(PARSER_GEN) -l -i $^ | ocp-indent > $@

# Le module Lexer.
src/lexer.ml: $(GRAMMAR)
	$(PARSER_GEN) -l $^ | ocp-indent > $@

# Interface du parser.
src/parser.mli: $(GRAMMAR)
	$(PARSER_GEN) -p -i $^ | ocp-indent > $@

# Le parser.
src/parser.ml: $(GRAMMAR)
	$(PARSER_GEN) -p $^ | ocp-indent > $@

# Génération de tous les fichiers du parser.
parser: $(PARSER_FILES)

vim: fml.vim syntax.vim
	mkdir -p ~/.vim/ftdetect/
	cp fml.vim ~/.vim/ftdetect/fml.vim
	mkdir -p ~/.vim/syntax/
	cp syntax.vim ~/.vim/syntax/fml.vim

deps:
	$(MAKE) --directory parser_generator

clean:
	rm -f $(PARSER_FILES)
	$(MAKE) --directory parser_generator clean

test: antsc
	./antsc tests/testSimple.fml -o tests/testSimple.brain
	diff tests/testSimple.brain tests/veriftestSimple.brain
	rm tests/testSimple.brain
	./antsc tests/testIf.fml -o tests/testIf.brain
	diff tests/testIf.brain tests/veriftestIf.brain
	rm tests/testIf.brain
	./antsc tests/testWhile.fml -o tests/testWhile.brain
	diff tests/testWhile.brain tests/veriftestWhile.brain
	rm tests/testWhile.brain
	./antsc tests/testInclude.fml -o tests/testInclude.brain -I tests/
	diff tests/testInclude.brain tests/veriftestInclude.brain
	rm tests/testInclude.brain
	echo "Pas d’erreurs, totu va bien !"

uninstall_deps:
	$(MAKE) --directory parser_generator uninstall

mrproper: clean
	rm -rf _build
	rm -f antsc antsc.install
	$(MAKE) --directory parser_generator mrproper

.PHONY: parser clean mrproper deps uninstall_deps
