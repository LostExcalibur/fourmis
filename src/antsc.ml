open Printf

type macro = string * (Ast.expression list)

let i = ref 0
let macros: macro list ref = ref [] 


let macro_existe (m: string) : bool = 
    let rec parcours l = match l with 
        [] -> false
        | (nom, _)::q -> nom = m || (parcours q)
    in parcours !macros


let ajouter_macro (m: macro) : unit = 
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


let comp_direction (dir: Ast.direction) : string =
    match dir with
        | Ast.Here ->               "Here"
        | Ast.Left ->               "LeftAhead"
        | Ast.Right ->              "RightAhead"
        | Ast.Ahead ->              "Ahead"


let comp_lr (dir: Ast.lr) : string =
    match dir with
        | Ast.TurnL ->              "Left"
        | Ast.TurnR ->              "Right"
 

let comp_valeur (valeur: Ast.valeur) : string =
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

let comp_command (commande: Ast.command) (oc: out_channel) : unit =
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


let comp_condition (cond: Ast.condition) (c: int) (oc: out_channel) : unit =
    match cond with
        | Ast.Eq((direction,_),(valeur,_)) ->       
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c) (c+1) (comp_valeur valeur)
        | Ast.Neq((direction,_),(valeur,_)) ->
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c+1) (c) (comp_valeur valeur)
        | Ast.Random(p,_) ->
                        fprintf oc "  Flip %d label_%d label_%d\n" (p) (c) (c+1)


let rec comp_expression (exp: Ast.expression) (oc: out_channel) : unit =
    match exp with
        | Ast.Do(commande,_) -> comp_command commande oc

        | Ast.Moveelse(exp_l,_) ->
            let comp_with_out = (fun x -> comp_expression x oc) in begin
                let c = !i in i := c + 2;
                fprintf oc "  Move label_%d\n" c;
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" c;
                List.iter comp_with_out (List.map unwrap_expr exp_l);
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" (c+1);
            end

        | Ast.Pickelse(exp_l,_) ->
            let comp_with_out = (fun x -> comp_expression x oc) in begin
                let c = !i in i := c + 2;
                fprintf oc "  Pickup label_%d\n" c;
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" c;
                List.iter comp_with_out (List.map unwrap_expr exp_l);
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" (c+1);
            end

        | Ast.IfThenElse((cond,_),(exp1,_),(exp2,_)) ->
            let comp_with_out = (fun x -> comp_expression x oc) in begin
                let c = !i in i := c + 3;
                        comp_condition cond c oc;
                        fprintf oc "label_%d:\n" c;
                        List.iter comp_with_out (List.map unwrap_expr exp1);
                        fprintf oc "  Goto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+1);
                        List.iter comp_with_out (List.map unwrap_expr exp2);
                        fprintf oc "  Goto label_%d\n" (c+2);
                        fprintf oc "label_%d:\n" (c+2)
            end
        | Ast.While((cond,_),(exp,_)) ->
                        let c = !i in i := c + 3;
                        fprintf oc "  Goto label_%d\n" c;
                        fprintf oc "label_%d:\n" c;
                        comp_condition cond (c+1) oc;
                        fprintf oc "label_%d:\n" (c+1);
                        List.iter (fun x -> comp_expression x oc) (List.map fst exp);
                        fprintf oc "  Goto label_%d\n" c;
                        fprintf oc "label_%d:\n" (c+2)
        | Ast.Macro((nom, _), (liste, _)) -> begin 
            if macro_existe nom then
                failwith "Macro déjà définie"
            else
                ajouter_macro (nom, (List.map unwrap_expr liste))
        end
        | Ast.Call(nom, _) -> if not (macro_existe nom) then failwith "BaTaMakroExistePa" else let (_, instructions) = trouver_macro nom in List.iter (fun x -> comp_expression x oc) instructions 


let comp_program (program: Ast.program) (oc: out_channel) : unit =
    match program with
        | Ast.Program(expression_l,_) ->
                (* TODO : Refactor possible en List.map unwrap_expr puis List.iter comp_expression *)
                let rec aux l =
                    match l with
                        |[] -> ()
                        |(exp,_)::q -> comp_expression exp oc; aux q
                in
                fprintf oc "debut:\n";
                aux (expression_l);
                fprintf oc "  Goto debut\n"
                

let process_file (filename: string) (output: string) : unit =
  (* Ouvre le fichier et créé un lexer. *)
    let file = open_in filename and out = open_out output in
    let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
    let (program, span) = Parser.parse_program lexer in
    printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program);
    comp_program program out


(* Le point de départ du compilateur. *)
let _ =
  let argc = Array.length Sys.argv in 
  (* On commence par lire le nom du fichier à compiler passé en paramètre. *)
  if argc <= 2 then begin
    (* Pas de fichier... *)
    eprintf "Usage :\n\t<%s> entree sortie\n" Sys.argv.(0);
    exit 1
  end else begin
    try
      (* On compile le fichier. *)
      process_file Sys.argv.(1) (if argc = 3 then Sys.argv.(2) else "cervo.brain")

    with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
  end
