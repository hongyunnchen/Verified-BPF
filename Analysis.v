Require Import String.
Require Import Div2.
Require Import Bool.
Require Import List.
Require Import Program.
Require Vector.
Require Vectors.Fin.

Import ListNotations.

Require Import Word.
Require Import Parser.
Require Skipn.


(*
  "Each instruction performs some action on the pseudo-machine state, which
   consists of an accumulator, index register, scratch memory store, and
   implicit program counter."
       -OpenBSD man page
*)


Definition scratch_mem := Vector.t (option (Word.word 32)) 16.

Definition empty_mem : scratch_mem :=
  Vector.const (None : option (Word.word 32)) 16.

Definition get_fin (i:nat) : option (Vectors.Fin.t 16) :=
  match Vectors.Fin.of_nat i 16 with
    | inleft x => Some x
    | _ => None
  end.

Definition ne_ins := { l : list instr | l <> [] }.

Theorem cons_not_nil : forall A (x:A) (l:list A), (x :: l) <> [].
Proof.
  discriminate.
Qed.

Definition get_ne_ins (l:list instr) : option ne_ins :=
  match l with
      | [] => None
      | a :: rest => Some (exist _ (a :: rest) (cons_not_nil _ a rest))
    end.

Record vm_state : Type := make_state {
  acc : option imm;
  x_reg : option imm;
  ins : { l : list instr | l <> [] };
  pkt : list (Word.word 32);
  smem : scratch_mem
}.

Inductive end_state : Type :=
  | Ret : Word.word 32 -> end_state
  | Error : string -> end_state.

Inductive state : Type :=
  | ContState : vm_state -> state
  | End : end_state -> state.

Definition init_state (ins:ne_ins) : state :=
  ContState (make_state None None ins [] empty_mem).

Definition change_acc (s:vm_state) (ins:list instr) (new_acc:imm) : state :=
  match get_ne_ins ins with
    | None => End (Error "altering acc as last instr")
    | Some ne_l => 
        ContState (make_state (Some new_acc) (x_reg s) ne_l (pkt s) (smem s))
  end.

Definition change_x_reg (s:vm_state) (ins:list instr) (new_x:imm) : state :=
  match get_ne_ins ins with
    | None => End (Error "altering acc as last instr")
    | Some ne_l =>
        ContState (make_state (acc s) (Some new_x) ne_l (pkt s) (smem s))
  end.

Definition change_smem (s:vm_state) (ins:ne_ins) (i:nat) (v:Word.word 32) : option vm_state :=
  match get_fin i with
    | Some fin =>
        let new_mem := Vector.replace (smem s) fin (Some v) in
        Some (make_state (acc s) (x_reg s) ins (pkt s) new_mem)
    | None => None
  end.

Definition skip_n_ni (n:nat) (l:ne_ins) : option ne_ins :=
    match skipn n (` l) with
      | [] => None
      | a :: rest => Some (exist _ (a :: rest) (cons_not_nil _ a rest))
    end.

Definition jump (s:vm_state) (n:word 32) : state :=
  match skip_n_ni (wordToNat n) (ins s) with
    | Some ins' =>
        ContState (make_state (acc s) (x_reg s) ins' (pkt s) (smem s))
    | None =>
        End (Error "jumped out of bounds")
  end.

Definition ne_hd : forall (l:list instr), l <> [] -> instr.
  refine (fun l p =>
  match l return ((l <> []) -> instr) with
    | [] => fun H => _
    | (a :: rest) => fun H => a
  end p).
Proof.
  intuition.
Qed.

Definition step (s:vm_state) : state :=
  let i := ne_hd (` (ins s)) (proj2_sig (ins s)) in
  let rest := tl (` (ins s)) in
  match i with
    | SoloInstr s_op =>
        match s_op with
          | RetA =>
              match acc s with
                | None => End (Error "Returned uninitialized acc")
                | Some v => End (Ret v)
              end
          | XStoreA =>
              match acc s with
                | Some acc' =>
                    change_x_reg s rest acc'
                | None =>
                    End (Error "storing acc to uninitialized x reg")
              end
          | AStoreX =>
              match x_reg s with
                | Some x' =>
                    change_acc s rest x'
                | None =>
                    End (Error "storing x reg to uninitialized acc")
              end
              | AddX =>
                        match acc s, x_reg s with
                            | Some acc', Some x' =>
                                change_acc s rest ((acc') ^+ x')
                            | None, _ =>
                                End (Error "Adding to uninitialized acc")
                            | _, None =>
                                End (Error "Adding uninitialized x reg")
                        end
                    | SubX =>
                        match acc s, x_reg s with
                            | Some acc', Some x' =>
                                change_acc s rest ((acc') ^- x')
                            | None, _ =>
                                End (Error "Subtracting to uninitialized acc")
                            | _, None =>
                                End (Error "Subtracting uninitialized x reg")
                        end
                    | MulX =>
                        match acc s, x_reg s with
                            | Some acc', Some x' =>
                                change_acc s rest ((acc') ^* x')
                            | None, _ =>
                                End (Error "Multiplying to uninitialized acc")
                            | _, None =>
                                End (Error "Multiplying uninitialized x reg")
                        end
                    | DivX =>
                        End (Error "*** fill in ***")
                    | AndX =>
                        match acc s, x_reg s with
                            | Some acc', Some x' =>
                                change_acc s rest ((acc') ^& x')
                            | None, _ =>
                                End (Error "And-ing to uninitialized acc")
                            | _, None =>
                                End (Error "And-ing uninitialized x reg")
                        end
                    | OrX =>
                        match acc s, x_reg s with
                            | Some acc', Some x' =>
                                change_acc s rest ((acc') ^| x')
                            | None, _ =>
                                End (Error "Or-ing to uninitialized acc")
                            | _, None =>
                                End (Error "Or-ing uninitialized x reg")
                        end
                    | SLX =>
                        End (Error "no shifts available yet")
                    | SRX =>
                        End (Error "no shifts available yet")
                    | LdXHdrLen =>
                        End (Error "*** fill in ***")
                    | LdLen =>
                        let pkt_len := Word.natToWord 32 (length (pkt s)) in
                        change_acc s rest pkt_len
                    | LdXLen =>
                        let pkt_len := Word.natToWord 32 (length (pkt s)) in
                        change_x_reg s rest pkt_len
                end
            | ImmInstr i_op i =>
                match i_op with
                    | RetK =>
                        End (Ret i)
                    | LdImm =>
                        change_acc s rest i
                    | AddImm =>
                        match acc s with
                            | Some acc' =>
                                change_acc s rest ((acc') ^+ i)
                            | None =>
                                End (Error "Adding to uninitialized acc")
                        end
                    | SubImm =>
                        match acc s with
                            | Some acc' =>
                                change_acc s rest ((acc') ^- i)
                            | None =>
                                End (Error "Subtracting to uninitialized acc")
                        end
                    | MulImm =>
                        match acc s with
                            | Some acc' =>
                                change_acc s rest ((acc') ^* i)
                            | None =>
                                End (Error "Multiplying to uninitialized acc")
                        end
                    | DivImm =>
                        End (Error "no div available for word (yet)")
                    | AndImm =>
                        match acc s with
                            | Some acc' =>
                                change_acc s rest ((acc') ^& i)
                            | None =>
                                End (Error "And-ing to uninitialized acc")
                        end
                    | OrImm =>
                        match acc s with
                            | Some acc' =>
                                change_acc s rest ((acc') ^| i)
                            | None =>
                                End (Error "Or-ing to uninitialized acc")
                        end
                    | SLImm =>
                        End (Error "no shifts available yet")
                    | SRImm =>
                        End (Error "no shifts available yet")
                    | Neg =>
                        match acc s with
                            | Some acc' =>
                                change_acc s rest (wneg acc')
                            | None =>
                                End (Error "Adding to uninitialized acc")
                        end
                    | JmpImm =>
                        jump s i
                    | LdXImm =>
                        change_x_reg s rest i
                end
            | MemInstr m_op m_addr =>
                match m_op with
                    | LdMem =>
                        End (Error "*** fill in ***")
                    | LdXMem =>
                        End (Error "*** fill in ***")
                    | Store =>
                        End (Error "*** fill in ***")
                    | StoreX =>
                        End (Error "*** fill in ***")
                end
            | PktInstr p_op p_addr =>
                match p_op with
                    | LdWord =>
                        End (Error "*** fill in ***")
                    | LdHalf =>
                        End (Error "*** fill in ***")
                    | LdByte =>
                        End (Error "*** fill in ***")
                    | LdOfstWord =>
                        End (Error "*** fill in ***")
                    | LdOfstHalf =>
                        End (Error "*** fill in ***")
                    | LdXByte =>
                        End (Error "*** fill in ***")
                end
            (* "All conditionals use unsigned comparison conventions." *)
            | BrInstr b_op ofst1 ofst2 =>
                match b_op with
                    | JGTX =>
                         End (Error "*** fill in ***")
                        (*
                        match acc s, x_reg s with
                            | Some acc', Some x' =>
                                if wlt x' acc' then jump ofst1 else jump ofst2
                            | None, _ =>
                                End (Error "Testing uninitialized acc")
                            | _, None =>
                                End (Error "Testing uninitialized x reg")
                        end
                                *)
                    | JGEX =>
                        End (Error "*** fill in ***")
                    | JEqX =>
                        End (Error "*** fill in ***")
                    | JAndX =>
                        End (Error "*** fill in ***")
                end
            | ImmBrInstr i_b_op i ofst1 ofst2 =>
                match i_b_op with
                    | JGTImm =>
                        End (Error "*** fill in ***")
                    | JGEImm =>
                        End (Error "*** fill in ***")
                    | JEqImm =>
                        End (Error "*** fill in ***")
                    | JAndImm =>
                        End (Error "*** fill in ***")
                end
  end.

Definition size (s:state) : nat :=
  match s with
    | End _ => 0
    | ContState cs => length (` (ins cs))
  end.

Definition t (l:list instr) (p:l <> []) : ne_ins := (exist _ l p).
Print t.

Lemma impl_subset : forall (l:list instr) (p:l <> []),
  p -> length l = length (` (exist _ l p)).

Definition is_cs (s:state) : Prop :=
  match s with
    | End _ => False
    | ContState _ => True
  end.

Lemma cs_gz : forall (s:state), is_cs s -> gt (size s) 0.
Proof.
  intros.
  destruct s.
  simpl. intuition.

Program Fixpoint prog_eval (s: state) { measure (size s) } : end_state :=
  match s with
    | End (e_s) => e_s
    | ContState cs => prog_eval (step cs)
  end.
(*
Lemma end_less : forall a b, lt (size (End a)) (size (ContState b)).
  simpl. intuition.*)

Next Obligation.
  induction (step cs).
  simpl. 
  destruct cs. simpl.
  destruct v. simpl.
  Case .

(*
   Used to prove that offsets stay on word (and hence instruction)
   boundaries.
*)

Definition word_aligned sz (w : Word.word sz) : bool :=
    let n := Word.wordToNat w in
        (negb (Word.mod2 n)) && (negb (Word.mod2 (div2 n))).
