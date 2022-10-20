open Printf
open Str

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
        | Ast.Marker(i,_) ->        "Marker " ^ (string_of_int i)
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
        | Ast.Unmark(i,_) ->        fprintf oc "  Unmark %d \n" i

let comp_condition (cond: Ast.condition) (c: int) (oc: out_channel) : unit =
    match cond with
        | Ast.Eq((direction,_),(valeur,_)) ->       
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c) (c+1) (comp_valeur valeur)
        | Ast.Neq((direction,_),(valeur,_)) ->
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c+1) (c) (comp_valeur valeur)
        | Ast.Random(p,_) ->
                        fprintf oc "  Flip %d label_%d label_%d\n" (p) (c) (c+1)
        | _ -> failwith "cas impossible"


let rec comp_expression (exp: Ast.expression) (oc: out_channel) : unit =
    match exp with
        | Ast.Break(c,_) -> fprintf oc "  Goto label_%d\n" c 
        | Ast.Do(commande,_) -> comp_command commande oc

        | Ast.MoveElse(exp_l,_) ->
            let comp_with_out = (fun x -> comp_expression x oc) in begin
                let c = !i in i := c + 2;
                fprintf oc "  Move label_%d\n" c;
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" c;
                List.iter comp_with_out (List.map unwrap_expr exp_l);
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" (c+1);
            end

        | Ast.PickElse(exp_l,_) ->
            let comp_with_out = (fun x -> comp_expression x oc) in begin
                let c = !i in i := c + 2;
                fprintf oc "  Pickup label_%d\n" c;
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" c;
                List.iter comp_with_out (List.map unwrap_expr exp_l);
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" (c+1);
            end
        
        | Ast.IfThenElse((Ast.True,_),(exp1,_),_) ->
            let rec aux l =
                match l with
                    |[] -> ()
                    |(exp,_)::q -> comp_expression exp oc; aux q
            in 
            fprintf oc "  Goto label_%d\n" !i;
            fprintf oc "label_%d:\n" !i;
            incr i;
            aux (exp1);
            fprintf oc "  Goto label_%d\n" !i
        
        | Ast.IfThenElse((Ast.Et((cond1,span1),(cond2,span2)),_),(exp1,span3),(exp2,span4)) -> 
            comp_expression (Ast.IfThenElse((cond1,span1),([(Ast.IfThenElse((cond2,span2),(exp1,span3),(exp2,span4)),span2)],span2),(exp2,span4))) oc
        
        | Ast.IfThenElse((Ast.Ou((cond1,span1),(cond2,span2)),_),(exp1,span3),(exp2,span4)) -> 
            comp_expression (Ast.IfThenElse((cond1,span1),(exp1,span3),([(Ast.IfThenElse((cond2,span2),(exp1,span3),(exp2,span4)),span2)],span2))) oc

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
        
        | Ast.While((cond,span1),(exp,span2)) -> 
            let c = !i in
            fprintf oc "  Goto label_%d\n" c;
            fprintf oc "label_%d:\n" c;
            incr i;
            comp_expression (Ast.IfThenElse((cond,span1),(exp,span2),([(Ast.Break (c,span1),span1)],span1))) oc;
        
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
                fprintf oc "debut:\n";
                List.iter (fun x -> comp_expression x oc) (List.map unwrap_expr expression_l);
                fprintf oc "  Goto debut\n"
                

let process_file (filename: string) (output: string) : unit =
  (* Ouvre le fichier et créé un lexer. *)
    let file = open_in filename and out = open_out output in
    let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
    let (program, _) = Parser.parse_program lexer in
    (* printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program); *)
    comp_program program out;
    close_out out

let post_replace (motif: string) (nouveau: string) : string -> string = 
    Str.global_replace (Str.regexp motif) nouveau 

let post_trouver_labels_inutiles (nom: string) : (string * string) list  = 
    let ic = open_in nom and label_regex = Str.regexp "\([a-zA-Z][a-zA-Z0-9_]*\):" and goto_regex = Str.regexp "Goto \([a-zA-Z][a-zA-Z0-9_]*\)" and result = ref [] in
    try while true do
        let ligne = input_line ic in 
        (* On a un label de défini, on regarde si la prochaine ligne est un goto *)
        if Str.string_match label_regex ligne 0 then
            let prochaine_ligne = input_line ic and label_dp = (matched_group 1 ligne) in
            (* On a un label suivi d'un goto, on va pouvoir opti *)
            if Str.string_match goto_regex prochaine_ligne 2 then
                result := (label_dp, matched_group 1 prochaine_ligne)::!result
    done; 
    !result
    with
    End_of_file -> !result

let rec post_mauvais_label (nom: string) (data: (string * string) list) : bool = match data with
    | [] -> false
    | (n, _)::q -> n = nom || post_mauvais_label nom q 


let post_regexp_string (data: (string * string) list) : string = 
  let rec aux l = match l with
    [] -> ""
  | (label1_nom1, label1_nom2)::[label2_nom1, label2_nom2] -> label1_nom1 ^ ":\n  Goto " ^ label1_nom2 ^ "\n\|" ^ label2_nom1 ^ ":\n  Goto " ^ label2_nom2 ^ "\n"
  | (nom1, nom2)::q -> nom1 ^ ":\n  Goto " ^ nom2 ^ "\n\|" ^ (aux q)
  in "\(" ^ (aux data) ^ "\)"

let rec post_print_labels (data: (string * string) list) : unit = 
  match data with
    [] -> ()
  | (nom1, nom2)::q -> printf "%s:\n  %s\n" nom1 nom2; post_print_labels q


let post_remplacer_labels (data: (string * string) list) (filename_out: string) (filename_opti: string) : unit = 
  let ic = open_in filename_out in
  let content = In_channel.really_input_string ic (in_channel_length ic) in 
  close_in ic; 
  let rec aux l s = match l with
      [] -> ()
    | (nom1, nom2)::q -> s := post_replace (nom1 ^ "$") nom2 !s (* ; printf "%s\n\n" !s *); aux q s
  and contenu = ref (post_replace (post_regexp_string data) "" (Option.get content)) and out_file = open_out filename_opti in begin
    (* post_print_labels (List.rev data); *)
    aux (List.rev data) contenu;
    fprintf out_file "%s" !contenu;
    close_out out_file
  end

(* Le point de départ du compilateur. *)
let _ =
  let argc = Array.length Sys.argv in 
  (* On commence par lire le nom du fichier à compiler passé en paramètre. *)
  if argc < 2 then begin
    (* Pas de fichier... *)
    eprintf "Usage :\n\t<%s> entree sortie\n" Sys.argv.(0);
    exit 1
  end else begin
    try
      (* On compile le fichier. *)
      let name = if argc = 3 then Sys.argv.(2) else "cervo.brain" in
      process_file Sys.argv.(1) name;
      let post_test_filename = name in
      let labels = post_trouver_labels_inutiles post_test_filename in
      post_remplacer_labels labels post_test_filename "opti.brain";

    with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
  end
