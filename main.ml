open Pervasives
open Array
open Sys
open Lex
open Lexing
open Parser
open Bpf

let get_opcode (instr) =
    match instr with
    | SoloInstr opcode -> opcode
    | ImmInstr (opcode, imm) -> opcode
    | OffsetInstr (opcode, offset) -> opcode
    | ImmBrInstr (opcode, imm, b1, b2) -> opcode
    | BrInstr (opcode, b1, b2) -> opcode
    | LenInstr opcode -> opcode

let rec fold_unit_list (u_list) =
    match u_list with
    | _ :: rest -> fold_unit_list rest
    | [] -> ()

let () =
    let cin =
      if Array.length Sys.argv > 1
      then open_in Sys.argv.(1)
      else stdin
    in
    let lexbuf = Lexing.from_channel cin in
    let pinstrs = Parser.pinstrs Lex.bpf_lex lexbuf in
    fold_unit_list (List.map print_endline (List.map get_opcode pinstrs))