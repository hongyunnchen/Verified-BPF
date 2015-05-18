Set Implicit Arguments.

Require Import ADT.

Module Make (Import E : ADT).

  Require Import Semantics.
  Module Import SemanticsMake := Make E.

  Section TopSection.

    Require Import GoodModule.
    Require Import GLabelMap.
    Import GLabelMap.
    
    Open Scope bool_scope.
    Notation "! b" := (negb b) (at level 35).

    Require Import Compare_dec.

    Definition to_bool A B (b : {A} + {B}) := if b then true else false.

    Notation fst2 := (fun x => @fst _ _ (@fst _ _ x)).

    Require Import ListFacts3.
    Require Import GoodModuleFacts.

    Definition GoodToLink_bool (modules : list GoodModule) (imports : t ForeignFuncSpec) := 
      let imported_module_names := List.map fst2 (elements imports) in
      let module_names := List.map Name modules in
      ! sumbool_to_bool (zerop (length modules)) &&
        NoDup_bool string_bool module_names &&
        forallb (fun s => ! sumbool_to_bool (in_dec string_dec s module_names)) imported_module_names &&
        forallb GoodModuleName_bool imported_module_names.

    Require Import GeneralTactics.
    Require Import ListFacts1.
    
    Lemma GoodToLink_bool_sound : 
      forall modules imports,
        GoodToLink_bool modules imports = true ->
        modules <> nil /\
        List.NoDup (List.map Name modules) /\
        ListFacts1.Disjoint (List.map Name modules) (List.map fst2 (elements imports)) /\
        forall l, In l imports -> IsGoodModuleName (fst l).
    Proof.
      intros.
      unfold GoodToLink_bool in *; simpl in *.
      Require Import GeneralTactics.
      Require Import Bool.
      repeat (eapply andb_true_iff in H; openhyp).
      split.
      eapply negb_true_iff in H.
      unfold sumbool_to_bool in *.
      destruct (zerop _); intuition.
      subst; simpl in *; intuition.
      split.
      eapply NoDup_bool_string_eq_sound; eauto.
      split.
      unfold ListFacts1.Disjoint; intuition.
      eapply forallb_forall in H1; eauto.
      eapply negb_true_iff in H1.
      unfold sumbool_to_bool in *.
      destruct (in_dec _ _ _); intuition.
      intros.
      eapply forallb_forall in H0; eauto.
      eapply GoodModuleName_bool_sound; eauto.
      rewrite <- map_map.
      eapply in_map.
      Require Import GLabelMapFacts.
      eapply In_fst_elements_In; eauto.
    Qed.

  End TopSection.
(*
  Require Import RepInv.

  Module Make (Import M : RepInv E).

    Require Import Link.
    Module Import LinkMake := Make E M.
    Require Import GoodOptimizer.
    Module Import GoodOptimizerMake := Make E.
    Require Import AutoSep.

    Lemma result_ok_2 :
      forall modules imports,
        GoodToLink_bool modules imports = true ->
        forall opt (opt_g: GoodOptimizer opt),
          moduleOk (result modules imports opt_g).
    Proof.
      intros.
      eapply GoodToLink_bool_sound in H.
      Require Import GeneralTactics.
      openhyp.
      eapply result_ok; eauto.
    Qed.

  End Make.
*)
End Make.