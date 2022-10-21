if exists("b:current_syntax")
  finish
endif

let b:current_syntax = "fml"

syn match 		randomNumber '\d+' 

syn keyword 	ident 	macro call
syn keyword 	cond 	if then else
syn keyword 	while 	while
syn keyword 	command nop move turn pickup mark drop

syn keyword 	lr 		left right
syn keyword 	valeur 	friend foe friendwithfood foewithfood food rock
syn keyword 	valeur 	marker foemarker home foehome 

syn keyword 	direction 	here leftahead rightahead ahead

hi def link 	ident 	Keyword
hi def link 	cond 	Conditional
hi def link 	while 	Repeat

hi def link 	lr 		Type
hi def link 	valeur	Type

hi def link 	direction Type

syn region block start="{" end="}" fold transparent


setlocal indentexpr=FmlIndent()

function! FmlIndent()
  let line = getline(v:lnum)
  let previousNum = prevnonblank(v:lnum - 1)
  let previous = getline(previousNum)

  if (previous =~ "{") && (previous !~ "}") && (trim(line) != "}") 
	return indent(previousNum) + &tabstop
  else
	return indent(previousNum) - &tabstop
  endif

endfunction

