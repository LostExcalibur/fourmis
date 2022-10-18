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


let comp_direction dir =
    match dir with
        | Ast.Here ->               "Here"
        | Ast.Left ->               "Left"
        | Ast.Right ->              "Right"
        | Ast.Ahead ->              "Ahead"


let comp_command commande =
    match commande with
        | Ast.Nope ->               printf "no operation \n"
        | Ast.Move ->               printf "label_n:
                                                Move label_n \n"
        | Ast.Turn(direction,_) ->  printf "Turn %s\n" (comp_direction direction)
        | Ast.Pickup ->             printf "label_n:
                                                PickUp label_n"
        | Ast.Mark(i,_) ->            printf "Mark %d \n" i
        | Ast.Drop ->               printf "Drop \n"
        | Ast.Label(id,commande) -> printf "labellll"
        | Ast.Goto(id) ->           printf "gooo"


let comp_condition cond =
    match cond with
        | Ast.Eq(direction,valeur) ->       printf "égall"
        | Ast.Neq(direction,valeur) ->      printf "paégal"
        | Ast.Random(p) ->                  printf "random"


let comp_expression exp =
    match exp with
        | Ast.Do(commandes_l,_) ->
                let rec aux l =
                    match l with
                        |[] -> ()
                        |(commande,_)::q -> comp_command commande ; aux q
                in
                aux (commandes_l)
        | Ast.IfThenElse(cond,exp1,exp2) -> printf "ite"
        | Ast.While(cond,exp) ->            printf "wile"


let comp_valeur valeur =
    match valeur with
        | Ast.Friend ->             printf "amii"
        | Ast.Foe ->                printf "paami :-("
        | Ast.FriendWithFood ->     printf "amimangé"
        | Ast.FoeWithFood ->        printf "paamimangé"
        | Ast.Food ->               printf "mangéééé"
        | Ast.Rock ->               printf "cayou"
        | Ast.Marker(i) ->          printf "marqeur"
        | Ast.FoeMarker ->          printf "markeur méchant"
        | Ast.Home ->               printf "maison"
        | Ast.FoeHome ->            printf "maison méchant"




let comp_program program =
    match program with
        | Ast.Program(expression_l,_) ->
                let rec aux l =
                    match l with
                        |[] -> ()
                        |(exp,_)::q -> comp_expression (exp) ; aux q
                in
                aux (expression_l)
                
        |_ -> printf "?"

let process_file filename =
  (* Ouvre le fichier et créé un lexer. *)
  let file = open_in filename in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (program, span) = Parser.parse_program lexer in
  (* printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program) *)
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
