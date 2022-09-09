# distutils: language=c
# clang c
# Copyright 2022 Edgar Costa
# See LICENSE file for license details.

from sage.libs.flint.types cimport fmpz, slong
from sage.libs.flint.fmpz_vec cimport _fmpz_vec_clear, _fmpz_vec_init
from cysignals.signals cimport sig_on, sig_off
from memory_allocator cimport MemoryAllocator
from sage.libs.flint.fmpz cimport fmpz_init, fmpz_clear, fmpz_get_mpz, fmpz_set_mpz, fmpz_print
from sage.rings.integer cimport Integer
from sage.rings.rational cimport Rational
#from cython.long cimport PyLong_FromLongLong
from sage.libs.gmp.mpz cimport mpz_get_si, mpz_set_si
from sage.all import (
    ZZ,
    QQ,
    ceil,
    gcd,
    vector,
    prod,
)


"""
    We call the following vector of invariants the Igusa modular invariants:
    psi4 = I4/4
    psi6 = I6prime/4 (Streng's notation) = = ((I2*I4-3*I6)/2)/4
    chi10 = -I10/2^12
    chi12 = I12/2^15

    They correspond to the Siegel modular forms with the following
    normalized q-expansions:
    psi4 = 1 + 240(q1+q2) + ...
    psi6 = 1 - 504(q1+q1) + ...
    chi10 = (q3 - 2 + q3^-1) + ...
    chi12 = (q3 + 10 + q3^-1) + ...

    This normalization differs slightly from Igusa's, who divides
    further chi10 and chi12 by 4 and 12, respectively.

"""


from libc.stdio cimport printf
cdef print_vector(fmpz* elt, n):
    printf("(")
    for i in range(n):
        fmpz_print(&elt[i])
        if i != n-1:
            printf(", ");
    printf(")\n")

def rescale(c, I, weights):
    return vector([c**i * j for i, j in zip(weights, I)])

def canonicalize_rational_invariants(I, weights):
    assert len(I) == len(weights)
    I = [QQ(elt) for elt in I]
    weights = [ZZ(w) for w in weights] # for the divisions below
    # make it integral
    for i, w in enumerate(weights):
        if I[i] == 0:
            continue
        b, p = I[i].denominator().perfect_power()
        I = rescale(b**ceil(p/w), I, weights)
    assert all(elt.denominator() == 1 for elt in I)
    I = [ZZ(elt) for elt in I]
    d = gcd( j**(30/w) for w, j in zip(weights, I))
    c = prod( p**(-(e//30)) for p, e in d.factor())
    I = rescale(c, I, weights)
    oddw = [i for i, w in enumerate(weights) if w % 2 == 1]
    if len(oddw) > 0 and I[oddw[0]] < 0:
        I = rescale(-1, I, weights)
    return tuple(I)

def canonicalize_igusa_clebsch_invariants(I):
    return canonicalize_rational_invariants(I, [1,2,3,5])


def igusa_clebsch_from_modular_igusa(M):
#    M4, M6, M10, M12 = M
#    I4 = M4*4
#    I10 = -M10*2**12
#    I12 = M12*2**15
#    I2 = I12/I10
#    I6prime = M6*4 # = (I2*I4-3*I6)/2
#    I6 = (I2*I4 - I6prime*2)/3
#    return canonicalize_igusa_clebsch_invariants((I2, I4, I6, I10))
    cdef fmpz *cM
    cM = _fmpz_vec_init(4)
    for i in range(4):
        fmpz_set_mpz(&cM[i], Integer(M[i]).value)
    sig_on()
    igusa_IC_fmpz(cM, cM);
    sig_off()
    I = [Integer(0) for _ in range(4)]
    for i in range(4):
        fmpz_get_mpz((<Integer>I[i]).value, &cM[i])
    _fmpz_vec_clear(cM, 4)
    return tuple(I)

def modular_igusa_from_igusa_clebsch(I):
    cdef fmpz *cI
    cI = _fmpz_vec_init(4)
    for i in range(4):
        fmpz_set_mpz(&cI[i], Integer(I[i]).value)
    sig_on()
    igusa_from_IC_fmpz(cI, cI)
    sig_off()
    M = [Integer(0) for _ in range(4)]
    for i in range(4):
        fmpz_get_mpz((<Integer>M[i]).value, &cI[i])
    _fmpz_vec_clear(cI, 4)
    return tuple(M)




def generic_wrapper(
    steps,
    modular_igusa_invariants,
    ell,
    verbose=False
):
    cdef int cverbose = int(verbose)
    for elt in [set_modeq_verbose, set_hecke_verbose]:
        elt(cverbose)
    assert steps in [1,2]
    assert len(modular_igusa_invariants) == 4
    ell = ZZ(ell)
    assert ell.is_prime()

    cdef fmpz *cM;
    cM = _fmpz_vec_init(4)
    for i in range(4):
        fmpz_set_mpz(&cM[i], Integer(modular_igusa_invariants[i]).value)

    cdef slong nb_roots
    cdef slong cell = mpz_get_si((<Integer>ell).value)

    # init output array
    max_nb_roots = (ell**3 + ell**2 + ell + 1)**steps
    cdef fmpz *all_isog_M
    all_isog_M = _fmpz_vec_init(4 * max_nb_roots);

    sig_on()
    if steps == 1:
        assert siegel_direct_isog_Q(&nb_roots, all_isog_M, cM, cell) == 1
    elif steps == 2:
        assert siegel_2step_direct_isog_Q(&nb_roots, all_isog_M, cM, cell) == 1
    sig_off()

    nb_roots_python = Integer(0)
    mpz_set_si(nb_roots_python.value, nb_roots)
    #nb_roots_python = PyLong_FromLongLong(nb_roots)
    assert nb_roots_python <= max_nb_roots, f"{nb_roots_python} > {max_nb_roots}"

    res = []
    for i in range(nb_roots_python):
        r = [Integer(0) for _ in range(4)]
        for j in range(4):
            fmpz_get_mpz((<Integer>r[j]).value, &all_isog_M[i*4 + j])
        res.append(r)

    _fmpz_vec_clear(cM, 4);
    _fmpz_vec_clear(all_isog_M, 4 * max_nb_roots);

    return res


def siegel_modeq_2step_isog_invariants_Q_wrapper(
      modular_igusa_invariants,
      ell,
      verbose=False
):
    r"""
    Given the modular Igusa invariants `psi_4, psi_6, chi_{10}, chi_{12}`
    of an abelian surface compute the same invariants of surfaces (ell,ell,ell^2)-isogenous

    INPUT:

    - ``modular_igusa_invariants`` -- the modular Igusa invariants `psi_4, psi_6, chi_{10}, chi_{12}` of an albelian surface
    - ``ell`` -- a prime number

    OUTPUT:

    - A list of Igusa-Clebsch invariants of abelian surfaces  (ell,ell,ell^2)-isogenous


    Examples::


    """
    return generic_wrapper(2, modular_igusa_invariants, ell, verbose=verbose)

def siegel_modeq_isog_invariants_Q_wrapper(
      modular_igusa_invariants,
      ell,
      verbose=False
):
    r"""
    Given the modular Igusa invariants `psi_4, psi_6, chi_{10}, chi_{12}`
    of an abelian surface compute the same invariants of surfaces (ell,ell)-isogenous

    INPUT:

    - ``modular_igusa_invariants`` -- the modular Igusa invariants `psi_4, psi_6, chi_{10}, chi_{12}` of an albelian surface

    - ``ell`` -- a prime number

    OUTPUT:

    - A list of Igusa-Clebsch invariants of abelian surfaces (ell, ell)-isogenous

    Examples::


    """
    return generic_wrapper(1, modular_igusa_invariants, ell, verbose=verbose)

