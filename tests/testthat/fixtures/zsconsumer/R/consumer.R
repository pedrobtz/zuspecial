zsc_info <- function() .Call(zsc_info_c)
zsc_gamma <- function(x) .Call(zsc_gamma_c, as.double(x))
zsc_jv_c <- function(v, z) .Call(zsc_jv_c_c, as.double(v), as.complex(z))
zsc_all <- function(abc) .Call(zsc_all_c, as.double(abc))
