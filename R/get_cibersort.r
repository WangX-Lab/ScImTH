#' character the fractions of tumor-infiltrating immune cells
#'
#' @param user_file  the path of gene expression data.frame.
#' @param perm  Number of replacements.
#' @param QN  Quantile normalization
#'
#' @returns  Impute a data.frame of Cell fractions.
#' @export
#'
#' @examples
#' # user_file = 'path/Cibersort_ucs.txt'
#' # result <- get_cibersort(user_file,perm = 1000, QN = TRUE)

get_cibersort <- function(user_file, perm = 1000, QN = TRUE) {

  sig_matrix_file <- system.file("extdata", "LM22.txt", package = "ScImTH")

  #Check whether the resource file exists
  if (!file.exists(sig_matrix_file)) {
    stop("Signature matrix file (LM22.txt) not found in package extdata directory")
  }


  # Run CIBERSORT analysis
  result <- CIBERSORT(
    sig_matrix = sig_matrix_file,
    mixture_file = user_file,
    perm = perm,
    QN = QN
  )

  return(result)
}

