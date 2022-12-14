(*
              ///((/////                   *&&&&&&&&              %&&&&&&&&    
           //(/////((//////              /&&&     *&&&          &&&&     %&&&  
         /(//^     ^//(//(///            &&&                   #&&             
       ///^,        //////////           &&&                    &&&            
                //////////(///            &&&&&&         *%&(    &&&&&&%       
              //////(///////////          &&&&&&      &&&&&&&&&&%   *&&&&&&&   
              ^^^////////(//^////        &&&        %&&#       &&&        &&&* 
              ^^^/(/////////^////        &&&        &&&        #&&         &&% 
           ^^^  ////////(////^^^^        (&&&     *&&&          &&&%     #&&&  
        ^^^^^^^^/(////((////^ ^^^^         (&&&&&&&&      ____    &&&&&&&&                     __     _  __   __
      .^^^///////////////////                            |  __ \                              |__ \ / _ \__ \|__ \       
      /^///////,..//////^//////^                         | |__) | __ ___  _ __ ___   ___         ) | | | | ) |  ) |     
  ////////////#////////    ^^^^^                         |  ___/ '__/ _ \| '_ ` _ \ / _ \       / /| | | |/ /  / /   
   /////((((////////        ^^^^                         | |   | | | (_) | | | | | | (_) |     / /_| |_| / /_ / /_ 
    ////////                                             |_|   |_|  \___/|_| |_| |_|\___/     |____|\___/____|____|
*)
open Printf
open Str

type macro = string * (Ast.expression list)
type file_include = (string * CodeMap.Span.t) 

let i = ref 0
let macros: macro list ref = ref [] 
let includes: file_include list ref = ref []

(* Fonctions utilitaires pour rajouter des messages d'erreur utilisables... *)
let ouvrir_in_check (filename: string) : in_channel =
  try open_in filename
  with
  | Sys_error(e) -> eprintf "Ne peut pas ouvrir le fichier \"%s\" %s\n" filename e; exit 1 

let ouvrir_out_check (filename: string) : out_channel = 
  try open_out filename
  with
  | Sys_error(e) -> eprintf "Ne peut pas ouvrir le fichier \"%s\" %s\n" filename e; exit 1 

(* Fonction pour v??rifier si un fichier a d??j?? ??t?? include *)
let fichier_deja_include (filename: string) : bool = 
  let rec parcours l = match l with
      [] -> false
    | (nom, _)::q -> nom = filename || (parcours q)
  in parcours !includes

let ajouter_include (incl: file_include) : unit = 
  includes := incl::(!includes) 


(* Fonction pour v??rifier si une macro a d??j?? ??t?? d??finie *)
let macro_existe (m: string) : bool = 
    let rec parcours l = match l with 
        [] -> false
        | (nom, _)::q -> nom = m || (parcours q)
    in parcours !macros

(* On a voulu rajouter un check pour interdire les macros r??cursives, mais il faudrait encore traverser un arbre donc on a pas eu le temps... ^^' *)
let ajouter_macro (m: macro) : unit = match m with 
  | (nom, _) when macro_existe nom -> eprintf "La macro \"%s\" est d??j?? d??finie\n" nom; exit 1
    | (_, _) -> macros := (m)::(!macros)

(* Cette fonction renvoit la macro correspondant au nom pass??, et fail si elle n'existe pas *)
let trouver_macro (m: string) : macro = 
    let rec parcours l = match l with 
      | [] -> eprintf "La macro \"%s\" n'existe pas\n" m; exit 1
        | (nom, liste)::q -> if nom = m then (nom, liste) else parcours q
    in parcours !macros

(* Fonction utilitaire pour se d??barasser des Span.located *)
let unwrap_expr (e: Ast.expression CodeMap.Span.located) : Ast.expression = 
    match e with 
    | (expr, _) -> expr 

(* Cette fonction v??rifie que le fichier n'a pas d??j?? ??t?? include, pour emp??cher les cycles *)
let process_include (filename: string) : Ast.expression CodeMap.Span.located list = 
  if fichier_deja_include filename then (
    eprintf "Erreur : fichier %s d??j?? include\n" filename;
    exit 1
  );
  let file = ouvrir_in_check filename in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (Program(liste, _), _) = Parser.parse_program lexer in
  liste
 

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


(* Seul d??tail, on a rajout?? un check pour interdire la compilation de mark 100, qui serait incorrect *)
let comp_command (commande: Ast.command) (oc: out_channel) : unit =
    match commande with
        | Ast.Nope ->               ()
        | Ast.Move ->
                fprintf oc "  Move label_%d\n  Goto label_%d\nlabel_%d:\n" !i !i !i;
                incr i

        | Ast.Turn(direction,_) ->  fprintf oc  "  Turn %s\n" (comp_lr direction)
        | Ast.Pickup ->
                fprintf oc "  PickUp label_%d\n  Goto label_%d\nlabel_%d:\n" !i !i !i;
                incr i
        | Ast.Mark(i, loc) ->          if i > 5 || i < 0 then (eprintf "%tOn ne peut faire mark i que pour 0 <= i <= 5\n" (CodeMap.Span.print loc); exit 1) else fprintf oc "  Mark %d\n" i
        | Ast.Drop ->               fprintf oc "  Drop\n"
        | Ast.Unmark(i, loc) ->        if i > 5 || i < 0 then (eprintf "%tOn ne peut faire mark i que pour 0 <= i <= 5\n" (CodeMap.Span.print loc); exit 1) else fprintf oc "  Unmark %d\n" i
        | Ast.Wait(n,_) ->
            for _ = 1 to n do
                fprintf oc "  Turn Left\n";
                fprintf oc "  Turn Right\n"
            done

let comp_condition (cond: Ast.condition) (c: int) (oc: out_channel) : unit =
    match cond with
        | Ast.Eq((direction,_),(valeur,_)) ->       
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c) (c+1) (comp_valeur valeur)
        | Ast.Neq((direction,_),(valeur,_)) ->
            fprintf oc "  Sense %s label_%d label_%d %s\n" (comp_direction direction) (c+1) (c) (comp_valeur valeur)
        | Ast.Random(p,_) ->
                        fprintf oc "  Flip %d label_%d label_%d\n" (p) (c) (c+1)
        | _ -> failwith "cas impossible"


let rec comp_expression (exp: Ast.expression) (oc: out_channel) (include_dir: string) : unit =
    match exp with
        | Ast.Break(c,_) -> fprintf oc "  Goto label_%d\n" c 
        | Ast.Do(commande,_) -> comp_command commande oc

        | Ast.MoveElse(exp_l,_) ->
          let comp_with_out = (fun x -> comp_expression x oc include_dir) in begin
                let c = !i in i := c + 2;
                fprintf oc "  Move label_%d\n" c;
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" c;
                List.iter comp_with_out (List.map unwrap_expr exp_l);
                fprintf oc "  Goto label_%d\n" (c+1);
                fprintf oc "label_%d:\n" (c+1);
            end

        | Ast.PickElse(exp_l,_) ->
          let comp_with_out = (fun x -> comp_expression x oc include_dir) in begin
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
                    |(exp,_)::q -> comp_expression exp oc include_dir; aux q
            in 
            fprintf oc "  Goto label_%d\n" !i;
            fprintf oc "label_%d:\t\t\t fin if true\n" !i;
            incr i;
            aux (exp1);
        
        | Ast.IfThenElse((Ast.Et((cond1,span1),(cond2,span2)),_),(exp1,span3),(exp2,span4)) -> 
          comp_expression (Ast.IfThenElse((cond1,span1),([(Ast.IfThenElse((cond2,span2),(exp1,span3),(exp2,span4)),span2)],span2),(exp2,span4))) oc include_dir
        
        | Ast.IfThenElse((Ast.Ou((cond1,span1),(cond2,span2)),_),(exp1,span3),(exp2,span4)) -> 
          comp_expression (Ast.IfThenElse((cond1,span1),(exp1,span3),([(Ast.IfThenElse((cond2,span2),(exp1,span3),(exp2,span4)),span2)],span2))) oc include_dir

        | Ast.IfThenElse((cond,_),(exp1,_),(exp2,_)) ->
          let comp_with_out = (fun x -> comp_expression x oc include_dir) in begin
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
            i:=!i+2;
            comp_expression (Ast.IfThenElse((cond,span1),(exp,span2),([(Ast.Break (c+1,span1),span1)],span1))) oc include_dir;
            fprintf oc "  Goto label_%d\n" c;
            fprintf oc "label_%d:\n" (c+1)
        
        | Ast.Macro((nom, _), (liste, _)) -> begin 
            if macro_existe nom then
                eprintf "Erreur : macro d??j?? d??finie : %s\n" nom
            else
                ajouter_macro (nom, (List.map unwrap_expr liste))
        end
        | Ast.Call(nom, _) -> if not (macro_existe nom) then failwith "BaTaMakroExistePa" else let (_, instructions) = trouver_macro nom in List.iter (fun x -> comp_expression x oc include_dir) instructions
        | Ast.Include(nom_fichier, endroit) -> begin
            let expressions = process_include (include_dir ^ nom_fichier ^ ".fml") in
            ajouter_include (include_dir ^ nom_fichier ^ ".fml", endroit);
          List.iter (fun x -> comp_expression x oc include_dir) (List.map unwrap_expr expressions) 
        end


let comp_program (program: Ast.program) (oc: out_channel) (include_dir: string) : unit =
    match program with
        | Ast.Program(expression_l,_) ->
                fprintf oc "debut:\n";
                List.iter (fun x -> comp_expression x oc include_dir) (List.map unwrap_expr expression_l);
                fprintf oc "  Goto debut\n"
 

let process_file (filename: string) (output: string) (include_dir: string) : unit =
  (* Ouvre le fichier et cr???? un lexer. *)
  let file = ouvrir_in_check filename in
    let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
    let (program, _) = Parser.parse_program lexer in
    (* printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program); *)
  let out = ouvrir_out_check output in  
  comp_program program out include_dir;
  close_out out


(* Fonction utilitaire currifi??e pour remplacer toutes les occurences d'un motif par un autre *)
let post_replace (motif: string) (nouveau: string) : string -> string = 
    Str.global_replace (Str.regexp motif) nouveau 


(* Cette fonction parcours le fichier et recherche les labels inutiles, c'est ?? dire de la forme : 
 * label_x:
 *   Goto label_y
 * On peut ainsi remplacer toutes les occurences de label_x par label_y, et supprimer ces deux lignes du fichier 
 * *)
let post_trouver_labels_inutiles (nom: string) : (string * string) list  = 
  let ic = ouvrir_in_check nom and label_regex = Str.regexp "\\([a-zA-Z][a-zA-Z0-9_]*\\):" and goto_regex = Str.regexp "Goto \\([a-zA-Z][a-zA-Z0-9_]*\\)" and result = ref [] in
    try while true do
        let ligne = input_line ic in 
        (* On a un label de d??fini, on regarde si la prochaine ligne est un goto *)
        if Str.string_match label_regex ligne 0 then
            let prochaine_ligne = input_line ic and label_dp = (matched_group 1 ligne) in
            (* On a un label suivi d'un goto, on va pouvoir opti *)
            if Str.string_match goto_regex prochaine_ligne 2 then
                result := (label_dp, matched_group 1 prochaine_ligne)::!result
    done; 
    close_in ic;
    !result
    with
      End_of_file -> close_in ic; !result


(* Regexp, est ce que quelqu'un va essayer de lire cette fonction ?
 * Dans le doute, ??a renvoit une regexp qui match tous les ??l??ments de data, 
 * avec le premier ??l??ment de chaque paire ??tant un nom de label et le deuxi??me
 * le code ?? ce label *)
let post_regexp_string (data: (string * string) list) : string = 
  let rec aux l = match l with
    [] -> ""
    | (label1_nom1, label1_nom2)::[label2_nom1, label2_nom2] -> label1_nom1 ^ ":\n.*" ^ label1_nom2 ^ "\n\\|" ^ label2_nom1 ^ ":\n.*" ^ label2_nom2 ^ "\n"
    | (nom1, nom2)::q -> nom1 ^ ":\n.*" ^ nom2 ^ "\n\\|" ^ (aux q)
  in "\\(" ^ (aux data) ^ "\\)" 

(* 
let rec post_print_labels (data: (string * string) list) : unit = 
  match data with
    [] -> ()
  | (nom1, nom2)::q -> printf "%s:\n  %s\n" nom1 nom2; post_print_labels q
*)


(* Cette fonction est cruciale pour ??tre sur du bon fonctionnement de l'optimisation, elle permet de r??soudre les probl??mes de cycles de remplacement de labels *)
let rec post_replace_dest (nom1: string) (nom2: string) (data: (string * string) list) : (string * string) list = match data with 
    [] -> []
  | (n1, n2)::q -> (n1, if n2 = nom1 then nom2 else n2)::(post_replace_dest nom1 nom2 q)

(* Cette fonction remplace les labels inutiles par le label ??quivalent, et supprime les d??finitions de labels inutiles.
 * Le param??tre data contient des paires de la forme (label_x, label_y), telles que les occurences de label_x doivent ??tre remplac??es par label_y *)
let post_remplacer_labels_inutiles (data: (string * string) list) (filename_in: string) (filename_out: string) : unit = 
  let ic = ouvrir_in_check filename_in in
  let content = really_input_string ic (in_channel_length ic) in 
  close_in ic; 
  (* fonction auxiliaire qui va passer sur tous les labels et les remplacer par l'??l??ment correspondant *)
  let rec aux l s = match l with
      [] -> ()
    | (nom1, nom2)::q -> s := post_replace (nom1 ^ "\\($\\| \\)") (nom2 ^ " ") !s; aux (post_replace_dest nom1 nom2 q) s
  and contenu = ref (post_replace (post_regexp_string data) "" content) and out_file = ouvrir_out_check filename_out in begin
    aux (List.rev data) contenu;
    fprintf out_file "%s" !contenu;
    close_out out_file
  end

(* Cette fonction parcours le fichier pour trouver les labels de la forme 
 * label_x:
 *   Flip ... ou Sense ...
 * En effet, comme ces deux instructions vont effectuer un branchement dans tous les cas, on peut inline label_x et remplacer les occurences de Goto label_x par l'instruction 
 * Cependant on ne peut pas supprimer la d??finition du label, ?? cause des Move par exemple *)
let post_trouver_labels_inline (nom: string) : (string * string) list = 
  let ic = ouvrir_in_check nom and label_regex = Str.regexp "\\([a-zA-Z][a-zA-Z0-9_]*\\):" and flip_sense_regex = Str.regexp "\\(Flip\\|Sense\\).*" and result = ref [] in
    try while true do
        let ligne = input_line ic in 
        (* On a un label de d??fini, on regarde si la prochaine ligne est un Sense ou un Flip *)
        if Str.string_match label_regex ligne 0 then
            let prochaine_ligne = input_line ic and label_dp = (matched_group 1 ligne) in
            (* On a un label suivi d'un Flip ou d'un Sense, on va pouvoir opti *)
            if Str.string_match flip_sense_regex prochaine_ligne 2 then
                result := (label_dp, matched_string prochaine_ligne)::!result
    done; 
    close_in ic;
    !result
    with
      End_of_file -> close_in ic; !result

(* Cette fonction inline les labels qui peuvent l'??tre, de la m??me mani??re que post_remplacer_labels_inutiles *)
let post_inline_labels (data: (string * string) list) (filename_in: string) (filename_out: string) : unit = 
 let ic = ouvrir_in_check filename_in in
  let content = ref (really_input_string ic (in_channel_length ic)) in 
  close_in ic; 
  let rec aux l s = match l with
      [] -> ()
    | (nom1, nom2)::q -> s := post_replace ("Goto " ^ nom1 ^ "\\($\\| \\)") nom2 !s; aux q s
  and out_file = ouvrir_out_check filename_out in begin
    aux data content;
    fprintf out_file "%s" !content;
    close_out out_file
  end

let print_usage () : unit = 
  eprintf "Usage :\n\t%s <entree> [-o sortie | -O sortie_opti]\n" Sys.argv.(0);
  eprintf "\tSi ni sortie ni sortie_opti ne sont pr??cis??s, sortie est mise ?? cervo.brain et on n'optimise pas\n"; 
  exit 1

let process_cli (input_file: string ref) (output_file: string ref) (opti_file: string ref) (include_dir: string ref) : unit = 
  let speclist = [("-o", Arg.Set_string output_file, "Nom du fichier de sortie");
                  ("-O", Arg.Set_string opti_file, "Optimise le code, et d??finit le nom du fichier de sortie");
                  ("-I", Arg.Set_string include_dir, "D??finit le dossier o?? rechercher les fichiers ?? include")] 
    in let add_input (filename: string) : unit = match !input_file with  
        "" -> input_file := filename
      | _ -> failwith "" 
    in Arg.parse speclist add_input "Usage :\n\t%s <entree> [-o sortie | -O sortie_opti] [-I dossier d'includes, par d??faut vaut ./]\n"

(* Le point de d??part du compilateur. *)
let _ =
  let name_in = ref "" and name_out = ref "" and name_opti = ref "" and include_dir = ref "" in
  process_cli name_in name_out name_opti include_dir; 
  if !name_in = "" then ( 
    eprintf "Pas de fichier d'entr??e fourni\n"; print_usage ();
  );
  
  if !name_out <> "" && !name_opti <> "" then (
  eprintf "sortie et sortie_opti ne peuvent ??tre utilis??s en m??me temps\n"; print_usage (); 
  )
  else if !name_opti = "" && !name_out = "" then (
    name_out := "cervo.brain"
  );

  if !name_opti <> "" && !name_out = "" then 
    name_out := !name_opti; 

  try
    process_file !name_in !name_out !include_dir;
    if !name_opti <> "" then (
    let labels = post_trouver_labels_inutiles !name_out in
    post_remplacer_labels_inutiles labels !name_out !name_opti; 
    post_inline_labels (post_trouver_labels_inline !name_opti) !name_opti !name_opti;
  ); 
  with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
