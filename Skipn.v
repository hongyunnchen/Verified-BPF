Require Import List.

Require String. Open Scope string_scope.

Ltac move_to_top x :=
  match reverse goal with
  | H : _ |- _ => try move x after H
  end.

Tactic Notation "assert_eq" ident(x) constr(v) :=
  let H := fresh in
  assert (x = v) as H by reflexivity;
  clear H.

Tactic Notation "Case_aux" ident(x) constr(name) :=
  first [
    set (x := name); move_to_top x
  | assert_eq x name; move_to_top x
  | fail 1 "because we are working on a different case" ].

Tactic Notation "Case" constr(name) := Case_aux Case name.
Tactic Notation "SCase" constr(name) := Case_aux SCase name.
Tactic Notation "SSCase" constr(name) := Case_aux SSCase name.
Tactic Notation "SSSCase" constr(name) := Case_aux SSSCase name.
Tactic Notation "SSSSCase" constr(name) := Case_aux SSSSCase name.
Tactic Notation "SSSSSCase" constr(name) := Case_aux SSSSSCase name.
Tactic Notation "SSSSSSCase" constr(name) := Case_aux SSSSSSCase name.
Tactic Notation "SSSSSSSCase" constr(name) := Case_aux SSSSSSSCase name.


Theorem skipn_head : forall  A (n:nat) (a:A) (l:list A),
  length (skipn (S n) (a :: l)) = length (skipn n l).
Proof.
  simpl.
  destruct l.
  Case "nil".
    intuition.
  Case "(a :: l)".
    intuition.
Qed.


Theorem skipn_succ : forall A (n:nat) (l:list A),
length (skipn n l) >= length (skipn (S n) l).
Proof.
  intros.
  generalize dependent n.
  induction l; simpl; intros.
  apply Le.le_0_n.
  unfold ge in *.
  destruct n.
  simpl; intuition.
  specialize (IHl n).
  rewrite IHl.
  rewrite skipn_head.
  reflexivity.
Qed.


Theorem skipn_dec : forall A (n:nat) (l:list A),
  length (skipn n l) <= length l.
Proof.
  intros.
  induction n.
  Case "0".
    simpl. intuition.
  Case "a :: l".
    transitivity (length (skipn n l)).
    apply skipn_succ.
    apply IHn.
Qed.