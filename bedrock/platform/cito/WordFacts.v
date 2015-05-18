Require Import AutoSep.
Require Import Arith.

Set Implicit Arguments.

Local Open Scope nat.

Lemma fold_4_mult : forall n, n + (n + (n + (n + 0))) = 4 * n.
  intros; ring.
Qed.

Lemma fold_4_mult_2 : 4 * 2 = 8.
  eauto.
Qed.

Lemma fold_4_mult_1 : 4 * 1 = 4.
  eauto.
Qed.

Lemma wplus_0 : forall w : W, w ^+ $0 = w.
  intros; rewrite wplus_comm; eapply wplus_unit.
Qed.

Ltac rewrite_natToW_plus :=
  repeat match goal with
           | H : context [ natToW (_ + _) ] |- _ => rewrite natToW_plus in H
           | |- context [ natToW (_ + _) ] => rewrite natToW_plus
         end.

Lemma wplus_wminus : forall (a b : W), a ^+ b ^- b = a.
  intros; words.
Qed.

Lemma wordToNat_natToW_le : forall n, wordToNat (natToW n) <= n.
  unfold natToW; intros.
  edestruct wordToNat_natToWord as [ ? [ ] ].
  rewrite H.
  generalize dependent (x * pow2 32); intros.
  omega.
Qed.

Lemma wle_goodSize_le : forall a b, (natToW a <= natToW b)%word -> goodSize a -> a <= b.
  intros; eapply le_wordToN in H; eauto; eapply le_trans; eauto; eapply wordToNat_natToW_le.
Qed.

Lemma wordToNat_eq_eq : forall x y : W, wordToNat x = wordToNat y -> x = y.
  intros.
  assert (natToW (wordToNat x) = natToW (wordToNat y)).
  congruence.
  unfold natToW in *.
  repeat erewrite natToWord_wordToNat in *.
  eauto.
Qed.
