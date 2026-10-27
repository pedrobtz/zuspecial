# argument errors read well

    Code
      sc_beta(1:2, 1:3)
    Condition
      Error in `sc_beta()`:
      ! Arguments must have length one or a common length; got `a` 2, `b` 3.
    Code
      sc_beta(matrix(1:6, 2), matrix(1:6, 3))
    Condition
      Error in `sc_beta()`:
      ! Array arguments must have the same dimensions.
    Code
      sc_gamma("a")
    Condition
      Error in `sc_gamma()`:
      ! `z` must be numeric or complex, not of type character.
    Code
      sc_beta("a", 1)
    Condition
      Error in `sc_beta()`:
      ! `a` must be numeric, not of type character.
    Code
      sc_gamma(Sys.Date())
    Condition
      Error in `sc_gamma()`:
      ! `z` must be numeric or complex, not an object of class <Date>.
    Code
      sc_expn(c(1, 1.5), 1)
    Condition
      Error in `sc_expn()`:
      ! `n` must hold whole numbers within integer range; element 2 is 1.5.
    Code
      sc_spherical_jn(1, 1, derivative = NA)
    Condition
      Error in `sc_spherical_jn()`:
      ! `derivative` must be `TRUE` or `FALSE`.

# errstate errors read well

    Code
      sc_seterr(domain = "loud")
    Condition
      Error in `sc_seterr()`:
      ! `domain` must be one of "ignore", "warn" or "raise".
    Code
      sc_errstate(1, "warn")
    Condition
      Error in `sc_errstate()`:
      ! Actions in `...` must be named `all` or an error code.

---

    Code
      sc_geterr()
    Condition
      Error:
      ! The option `zuspecial.errstate` must be a named character vector of "ignore", "warn" or "raise", one per error code; set it with `sc_seterr()`.

# floating-point conditions count elements

    Code
      sc_errstate(sc_gamma(-1), singular = "warn")
    Condition
      Warning in `sc_gamma()`:
      sc_gamma: singular in 1 element, first at index 1.
    Output
      [1] NaN
    Code
      sc_errstate(sc_gamma(c(1, -1, -2)), singular = "warn")
    Condition
      Warning in `sc_gamma()`:
      sc_gamma: singular in 2 elements, first at index 2.
    Output
      [1]   1 NaN NaN

---

    Code
      sc_errstate(sc_gamma(c(1, -1)), singular = "raise")
    Condition
      Error in `sc_gamma()`:
      ! sc_gamma: singular in 1 element, first at index 2.

# an internal error says so

    Code
      zsp_eval("gamma", list(x = 1), outputs = c("a", "b", "c"))
    Condition
      Error:
      ! Internal error: no loop for signature `d3`.

