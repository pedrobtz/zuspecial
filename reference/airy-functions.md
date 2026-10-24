# Airy functions

The Airy functions \\Ai(z)\\, \\Bi(z)\\ and their derivatives, for real
or complex `z`, as `scipy.special.airy()` and `airye()` compute them.
Each call returns all four, as a named list, as SciPy returns a tuple.

## Usage

``` r
sc_airy(z)

sc_airye(z)
```

## Arguments

- z:

  Numeric or complex vector.

## Value

A list with elements `ai`, `aip`, `bi` and `bip`, each a double vector,
or a complex vector for complex `z`, with `z`'s dimensions or names.
`NA` in `z` gives `NA` in every element.

## Details

- `sc_airy()`: \\Ai\\, \\Ai'\\, \\Bi\\, \\Bi'\\.

- `sc_airye()`: the exponentially scaled forms, \\Ai(z) e^{\zeta}\\,
  \\Ai'(z) e^{\zeta}\\, \\Bi(z) e^{-\|\Re \zeta\|}\\ and \\Bi'(z)
  e^{-\|\Re \zeta\|}\\, with \\\zeta = \frac23 z^{3/2}\\.

## See also

<https://docs.scipy.org/doc/scipy/reference/generated/scipy.special.airy.html>

## Examples

``` r
sc_airy(c(-1, 0, 1))
#> $ai
#> [1] 0.5355609 0.3550281 0.1352924
#> 
#> $aip
#> [1] -0.01016057 -0.25881940 -0.15914744
#> 
#> $bi
#> [1] 0.1039974 0.6149266 1.2074236
#> 
#> $bip
#> [1] 0.5923756 0.4482884 0.9324359
#> 
sc_airye(10)$ai
#> [1] 0.1581237
sc_airy(1 + 1i)
#> $ai
#> [1] 0.06045831-0.1518896i
#> 
#> $aip
#> [1] -0.130628+0.1630676i
#> 
#> $bi
#> [1] 0.7166581+0.6198893i
#> 
#> $bip
#> [1] 0.07566284+0.783701i
#> 
```
