open Printf

let write_file filename = (* Ceci est un exemple. *)
  let oc = open_out filename in (* Ouvre un fichier pour écrire dedans. *)
  let write_label (msg:string) : unit = (* Écriture d'un label. *)
    fprintf oc "%s:\n" msg in
  let write_command (msg:string) : unit = (* Écriture d'autres commandes. *)
    fprintf oc "  %s\n" msg in
  write_label   "start";
  write_command "Drop";
  write_command "Goto start";
  close_out oc

let i = ref 0

let oc = open_out "cervo.brain"

let comp_direction dir =
    match dir with
        | Ast.Here ->               "Here"
        | Ast.Left ->               "Left"
        | Ast.Right ->              "Right"
        | Ast.Ahead ->              "Ahead"

let comp_valeur valeur =
    match valeur with
        | Ast.Friend ->             "Friend"
        | Ast.Foe ->                "Foe"
        | Ast.FriendWithFood ->     "FriendWithFood"
        | Ast.FoeWithFood ->        "FoeWithFood"
        | Ast.Food ->               "Food"
        | Ast.Rock ->               "Rock"
        | Ast.Marker(i,_) ->        "Marker "^(string_of_int i)
        | Ast.FoeMarker ->          "FoeMarker"
        | Ast.Home ->               "Home"
        | Ast.FoeHome ->            "FoeHome"

let comp_command commande =
    match commande with
        | Ast.Nope ->               fprintf oc "\tno operation \n"
        | Ast.Move ->
                fprintf oc "label_%d:\n\tMove label_%d \n" !i !i;
                incr i
        | Ast.Turn(direction,_) ->  fprintf oc  "\tTurn %s\n" (comp_direction direction)
        | Ast.Pickup ->
                fprintf oc "label_%d:\n\tPickUp label_%d\n" !i !i;
                incr i
        | Ast.Mark(i,_) ->          fprintf oc "\tMark %d \n" i
        | Ast.Drop ->               fprintf oc "\tDrop \n"
        | Ast.Label(id,expr) -> fprintf oc "\tlabellll"
        | Ast.Goto(id) ->           fprintf oc "\tgooo"


let comp_condition cond =
    match cond with
        | Ast.Eq(direction,valeur) ->       printf "égall"
        | Ast.Neq(direction,valeur) ->      printf "paégal"
        | Ast.Random(p) ->                  printf "random"


let rec comp_expression exp =
    match exp with
        | Ast.Do(commandes_l,_) ->
                let rec aux l =
                    match l with
                        |[] -> ()
                        |(commande,_)::q -> comp_command commande ; aux q
                in
                aux (commandes_l)
        | Ast.IfThenElse((cond,_),(exp1,_),(exp2,_)) -> begin 
            match cond with
                | Ast.Random(p,_) ->
                        let c = !i in i := c + 3;
                        fprintf oc "\tFlip %d label_%d label_%d\n" (p) (c) (c+1); 
                        fprintf oc "label_%d:\n" c;
                        comp_expression exp1;
                        fprintf oc "\tGoto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+1);
                        comp_expression exp2;
                        fprintf oc "\tGoto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+2);

                | Ast.Eq((direction,_),(valeur,_)) ->
                        let c = !i in i := c + 3;
                        fprintf oc "\tSense %s label_%d label_%d %s\n" (comp_direction direction) (c) (c+1) (comp_valeur valeur);
                        fprintf oc "label_%d:\n" c;
                        comp_expression exp1;
                        fprintf oc "\tGoto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+1);
                        comp_expression exp2;
                        fprintf oc "\tGoto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+2);

                | Ast.Neq((direction,_),(valeur,_)) -> 
                        let c = !i in i := c + 3;
                        fprintf oc "\tSense %s label_%d label_%d %s\n" (comp_direction direction) (c+1) (c) (comp_valeur valeur);
                        fprintf oc "label_%d:\n" c;
                        comp_expression exp1;
                        fprintf oc "\tGoto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+1);
                        comp_expression exp2;
                        fprintf oc "\tGoto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+2);
            end
        | Ast.While(cond,exp) ->            printf "wile"






let comp_program program =
    match program with
        | Ast.Program(expression_l,_) ->
                let rec aux l =
                    match l with
                        |[] -> ()
                        |(exp,_)::q -> comp_expression exp ; aux q
                in
                aux (expression_l)
                
        |_ -> printf "?"

let process_file filename =
  (* Ouvre le fichier et créé un lexer. *)
  let file = open_in filename in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (program, span) = Parser.parse_program lexer in
  printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program);
  comp_program program

(* Le point de départ du compilateur. *)
let _ =
  (* On commence par lire le nom du fichier à compiler passé en paramètre. *)
  if Array.length Sys.argv <= 1 then begin
    (* Pas de fichier... *)
    eprintf "no file provided.\n";
    exit 1
  end else begin
    try
      (* On compile le fichier. *)
      process_file (Sys.argv.(1))
    with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
  end
