# pyhdme


This package is a simple wrapper for a subset of the [hdme](https://github.com/j-kieffer/hdme) library code into SageMath.
In particular:
From `modular.h`:
- `int siegel_direct_isog_Q(slong* nb, fmpz* all_I, fmpz* I, slong ell)` as `siegel_modeq_isog_invariants_Q_wrapper`
- `int siegel_2step_direct_isog_Q(slong* nb, fmpz* all_I, fmpz* I, slong ell)` as `siegel_modeq_2step_isog_invariants_Q_wrapper`

From `igusa.h`:
- `void igusa_IC_fmpz(fmpz* IC, fmpz* I)` as `igusa_clebsch_from_modular_igusa`
- `void igusa_from_IC_fmpz(fmpz* I, fmpz* IC)` as `modular_igusa_from_igusa_clebsch`
 

## Install



```
sage -pip install --upgrade  git+https://github.com/edgarcosta/pyhdme.git
```

If you don't have permissions to install it system wide, please add the flag ``--user`` to install it just for you.

```
sage -pip install --user --upgrade git+https://github.com/edgarcosta/pyhdme.git
```



## Examples

### A pair connected by an isogeny of degree 3^4
```
sage: from pyhdme import (modular_igusa_from_igusa_clebsch, igusa_clebsch_from_modular_igusa, siegel_modeq_isog_invariants_Q_wrapper, siegel_modeq_2step_isog_invariants_Q_wrapper)
sage: R.<x> = PolynomialRing(QQ)
sage: C = HyperellipticCurve(R([0, 0, -2, -1, 4, 4]), R([1]))
sage: inv = modular_igusa_from_igusa_clebsch(C.igusa_clebsch_invariants())
sage: inv
(-1856, 129536, -44, -2948)
sage: siegel_modeq_isog_invariants_Q_wrapper(inv, 3)
[]
sage: new_inv = siegel_modeq_2step_isog_invariants_Q_wrapper(inv, 3)
sage: new_inv
[[771904, 687149056, 260876, -197548868]]
sage: siegel_modeq_2step_isog_invariants_Q_wrapper(new_inv[0], 3)
[[-1856, 129536, -44, -2948]]
sage: igusa_clebsch_from_modular_igusa(new_inv[0])
(8979494, 6783693240016, 14337325843545179552, -7645420379865590722034096)
```


### An example of of square with isogenies of degree 3^4 and 5^4

```
sage: C = HyperellipticCurve(R([0, -1, -1]), R([1, 1, 1, 1]))
sage: inv = modular_igusa_from_igusa_clebsch(C.igusa_clebsch_invariants())
sage: inv
(1408, 49024, -277, -8864)
sage: siegel_modeq_isog_invariants_Q_wrapper(inv, 3)
[]
sage: siegel_modeq_isog_invariants_Q_wrapper(inv, 5)
[]
sage: new_inv3 = siegel_modeq_2step_isog_invariants_Q_wrapper(inv, 3)
sage: new_inv3
[[5482048, 12835476224, 277, -620480]]
sage: siegel_modeq_2step_isog_invariants_Q_wrapper(new_inv3[0], 3)
[[1408, 49024, -277, -8864]]
sage: new_inv5 = siegel_modeq_2step_isog_invariants_Q_wrapper(inv, 5)
sage: new_inv5
[[-4074752, 3079190656, -53383717, 155880885760]]
sage: siegel_modeq_2step_isog_invariants_Q_wrapper(new_inv5[0], 5)
[[1408, 49024, -277, -8864]]
sage: siegel_modeq_2step_isog_invariants_Q_wrapper(new_inv5[0], 3)
[[5786446528, 440253117070336, -3537013, 285292529056]]
sage: siegel_modeq_2step_isog_invariants_Q_wrapper(new_inv3[0], 5)
[[5786446528, 440253117070336, -3537013, 285292529056]]
```

