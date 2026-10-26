# Floating-point error handling

xsf, like `scipy.special`, reports conditions such as a pole or a loss
of precision through error codes rather than R conditions. These
functions choose what each code does, after `scipy.special.geterr()`,
`seterr()` and `errstate()`: `"ignore"` it, `"warn"` with a warning of
class `zuspecial_warning` and `zuspecial_<code>`, or `"raise"` an error
of class `zuspecial_error` and `zuspecial_<code>_error`. Each code is
signalled once per call, with the number of elements that raised it and
the first one's index.

## Usage

``` r
sc_geterr()

sc_seterr(
  all = NULL,
  singular = NULL,
  underflow = NULL,
  overflow = NULL,
  slow = NULL,
  loss = NULL,
  no_result = NULL,
  domain = NULL,
  arg = NULL,
  other = NULL,
  memory = NULL
)

sc_errstate(expr, ...)
```

## Arguments

- all:

  Action for every code, `memory` included, applied before the named
  ones.

- singular, underflow, overflow, slow, loss, no_result, domain, arg,
  other, memory:

  Action for that code: `"ignore"`, `"warn"` or `"raise"`. `NULL` leaves
  it unchanged.

- expr:

  An expression to evaluate under the temporary actions.

- ...:

  Actions passed to `sc_seterr()` for the duration of `expr`.

## Value

`sc_geterr()` returns a named character vector with one action per code.
`sc_seterr()` returns the previous state, invisibly. `sc_errstate()`
returns the value of `expr`.

## Details

The defaults are SciPy's: every code is ignored except `memory`, which
raises. The state lives in the option `zuspecial.errstate`, so parallel
workers start from the defaults. Set it with `sc_seterr()`; a value set
directly is completed from the defaults, and refused if malformed.

## See also

<https://docs.scipy.org/doc/scipy/reference/generated/scipy.special.seterr.html>

## Examples

``` r
sc_geterr()
#>  singular underflow  overflow      slow      loss no_result    domain       arg 
#>  "ignore"  "ignore"  "ignore"  "ignore"  "ignore"  "ignore"  "ignore"  "ignore" 
#>     other    memory 
#>  "ignore"   "raise" 
sc_errstate(sc_gamma(-1), singular = "warn")
#> Warning: sc_gamma: singular in 1 element, first at index 1.
#> [1] NaN
```
