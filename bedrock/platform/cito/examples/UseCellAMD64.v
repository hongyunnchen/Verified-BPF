Require Import UseCellDriver AMD64_gas.

Module M.
  Definition heapSize := 1024.
End M.

Module E := Make(M).

Definition compiled := moduleS E.m1.
Recursive Extraction compiled.