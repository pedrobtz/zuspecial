# zuspecial: Special Functions from 'SciPy' for Real and Complex Arguments

Evaluates the special functions of mathematical physics and statistics,
including gamma, beta, error, Bessel, Airy, hypergeometric, elliptic and
zeta functions, for real and complex arguments, using the same kernels
as the 'SciPy' library's 'scipy.special' module
(<https://docs.scipy.org/doc/scipy/reference/special.html>). Functions
keep 'SciPy' names and argument order so that code translates directly
between 'Python' and 'R', and results agree with 'SciPy' to within its
own test tolerances. 'SciPy' is described in Virtanen et al. (2020)
[doi:10.1038/s41592-019-0686-2](https://doi.org/10.1038/s41592-019-0686-2)
. A registered C interface lets other packages call the functions from
compiled code.

## See also

Useful links:

- <https://github.com/pedrobtz/zuspecial>

- <https://pedrobtz.github.io/zuspecial/>

- Report bugs at <https://github.com/pedrobtz/zuspecial/issues>

## Author

**Maintainer**: Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Authors:

- Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Other contributors:

- SciPy (bundled xsf library) \[copyright holder\]

- Stephen L. Moshier (Cephes code in the bundled xsf library)
  \[copyright holder\]

- Massachusetts Institute of Technology (Faddeeva code in the bundled
  xsf library) \[copyright holder\]

- The Regents of the University of California (qd code in the bundled
  xsf library) \[copyright holder\]

- Shanjie Zhang (specfun code in the bundled xsf library) \[copyright
  holder\]

- Jianming Jin (specfun code in the bundled xsf library) \[copyright
  holder\]

- John Maddock (Boost-derived code in the bundled xsf library)
  \[copyright holder\]

- Xiaogang Zhang (Boost-derived code in the bundled xsf library)
  \[copyright holder\]

- Benjamin Sobotta (Owen's T code in the bundled xsf library)
  \[copyright holder\]

- Pauli Virtanen (code in the bundled xsf library) \[copyright holder\]

- Yosef Meller (Lambert W code in the bundled xsf library) \[copyright
  holder\]

- Christian Lorentzen (Wright Bessel code in the bundled xsf library)
  \[copyright holder\]

- Eric W. Moore (elliptic integral code in the bundled xsf library)
  \[copyright holder\]

- Albert Steppi (ndtri_exp, ported from SciPy) \[copyright holder\]

- Piers Lawrence (Wright omega function, ported from SciPy) \[copyright
  holder\]

- NumPy developers (complex power, ported from NumPy) \[copyright
  holder\]

- Donald E. Amos (author of the AMOS Bessel code in the bundled xsf
  library) \[contributor\]

- Steven G. Johnson (author of the Faddeeva code in the bundled xsf
  library) \[contributor\]

- Yozo Hida (author of the qd code in the bundled xsf library)
  \[contributor\]

- David H. Bailey (double-double package the bundled qd code is based
  on) \[contributor\]

- Keith Briggs (double-double package the bundled qd code borrows from)
  \[contributor\]

- Josh Wilson (code in the bundled xsf library) \[contributor\]

- Matt Haberland (complex zeta code in the bundled xsf library)
  \[contributor\]
