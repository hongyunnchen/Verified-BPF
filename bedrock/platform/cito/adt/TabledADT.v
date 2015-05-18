Set Implicit Arguments.

Require Import String.

Inductive ADTScheme :=
| Primitive : string -> ADTScheme
| Product : ADTScheme -> ADTScheme -> ADTScheme.

Require Import AutoSep.

Record ADTEntry :=
  {
    Model : Type;
    RepInv : W -> Model -> HProp;
    RepInvGood : forall p a, RepInv p a ===> p =?> 1 * any
  }.

Require Import StringMap.
Import StringMap.

Definition PrimitiveTable := t ADTEntry.

Definition Empty_adt : ADTEntry :=
  {|
    Model := Empty_set;
    RepInv := fun _ a => match a with end;
    RepInvGood := fun _ a => match a with end
  |}.

Definition product_adt (a b : ADTEntry) : ADTEntry.
  refine (
      {|
        Model := (Model a * Model b)%type;
        RepInv := _;
        RepInvGood := _
      |}).
  Admitted.

Section TableSection.

  Variable primitive_table : PrimitiveTable.

  Fixpoint interp_adt (ty : ADTScheme) : ADTEntry :=
    match ty with
      | Primitive name => 
        match find name primitive_table with
          | Some adt => adt
          | None => Empty_adt
        end
      | Product a b => product_adt (interp_adt a) (interp_adt b)
    end.

  Record ADTValue :=
    {
      Ty : ADTScheme;
      Value : Model (interp_adt Ty)
    }.

End TableSection.

Module Type ADTTable.

  Parameter primitive_table : PrimitiveTable.

End ADTTable.

Require Import ADT.

Module TabledADT (Import T : ADTTable) <: ADT.

  Definition ADTValue := ADTValue primitive_table.

End TabledADT.

Module Make (Import T : ADTTable).
  
  Module Import A := TabledADT T.

  Require Import RepInv.

  Module TabledADTRepInv <: RepInv A.

    Definition rep_inv p a := RepInv (interp_adt primitive_table (Ty a)) p (Value a).
    
    Definition rep_inv_ptr p a := RepInvGood (interp_adt primitive_table (Ty a)) p (Value a).

    Definition RepInv := W -> ADTValue -> HProp.

  End TabledADTRepInv.

End Make.