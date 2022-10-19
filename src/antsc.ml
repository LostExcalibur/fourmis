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

type macro = string * (Ast.expression list)


let i = ref 0
let macros: macro list ref = ref [] 
let oc = open_out "cervo.brain"


let macro_existe (m: string) : bool = 
    let rec parcours l = match l with 
        [] -> false
        | (nom, _)::q -> nom = m || (parcours q)
    in parcours !macros


let ajouter_macro (m: macro) = 
    match m with 
    | (nom, _) when macro_existe nom -> failwith "Macro déjà définie"
    | _ -> macros := (m)::(!macros) 


let trouver_macro (m: string) : macro = 
    let rec parcours l = match l with 
        | [] -> failwith "BaTaMakroExistePa"
        | (nom, liste)::q -> if nom = m then (nom, liste) else parcours q
    in parcours !macros


let unwrap_expr (e: Ast.expression CodeMap.Span.located) : Ast.expression = 
    match e with 
    | (expr, _) -> expr 


let comp_direction dir =
    match dir with
        | Ast.Here ->               "Here"
        | Ast.Left ->               "LeftAhead"
        | Ast.Right ->              "RightAhead"
        | Ast.Ahead ->              "Ahead"


let comp_lr dir =
    match dir with
        | Ast.TurnL ->              "Left"
        | Ast.TurnR ->              "Right"
 

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
        | Ast.Nope ->               ()
        | Ast.Move ->
                fprintf oc "  Move label_%d \n  Goto label_%d\nlabel_%d:\n " !i !i !i;
                incr i
        | Ast.Turn(direction,_) ->  fprintf oc  "  Turn %s\n" (comp_lr direction)
        | Ast.Pickup ->
                fprintf oc "  PickUp label_%d\n  Goto label_%d\nlabel_%d:\n" !i !i !i;
                incr i
        | Ast.Mark(i,_) ->          fprintf oc "  Mark %d \n" i
        | Ast.Drop ->               fprintf oc "  Drop \n"


let comp_condition cond c =
    match cond with
        | Ast.Eq((direction,_),(valeur,_)) ->       
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c) (c+1) (comp_valeur valeur)
        | Ast.Neq((direction,_),(valeur,_)) ->
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c+1) (c) (comp_valeur valeur)
        | Ast.Random(p,_) ->
                        fprintf oc "  Flip %d label_%d label_%d\n" (p) (c) (c+1)


let rec comp_expression exp =
    match exp with
        | Ast.Do(commande,_) -> comp_command commande
        | Ast.IfThenElse((cond,_),(exp1,_),(exp2,_)) -> 
                        let c = !i in i := c + 3;
                        comp_condition cond c;
                        fprintf oc "label_%d:\n" c;
                        List.iter comp_expression (List.map fst exp1);
                        fprintf oc "  Goto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+1);
                        List.iter comp_expression (List.map fst exp2);
                        fprintf oc "  Goto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+2)
            
        | Ast.While((cond,_),(exp,_)) ->
                        let c = !i in i := c + 3;
                        fprintf oc "  Goto label_%d\n" c;
                        fprintf oc "label_%d:\n" c;
                        comp_condition cond (c+1);
                        fprintf oc "label_%d:\n" (c+1);
                        List.iter comp_expression (List.map fst exp);
                        fprintf oc "  Goto label_%d\n" c;
                        fprintf oc "label_%d:\n" (c+2)
        | Ast.Macro((nom, _), (liste, _)) -> begin 
            if macro_existe nom then
                failwith "Macro déjà définie"
            else
                ajouter_macro (nom, (List.map unwrap_expr liste))
        end
        | Ast.Call(nom, _) -> if not (macro_existe nom) then failwith "BaTaMakroExistePa" else let (_, instructions) = trouver_macro nom in List.iter comp_expression instructions 


let comp_program program =
    match program with
        | Ast.Program(expression_l,_) ->
                let rec aux l =
                    match l with
                        |[] -> ()
                        |(exp,_)::q -> comp_expression exp ; aux q
                in
                fprintf oc "debut:\n";
                aux (expression_l);
                fprintf oc "  Goto debut\n"
                

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
