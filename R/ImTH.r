#' quantifying intratumor immune heterogeneity
#'
#' @param data A data.frame of proportions of immune cell types across samples.
#' @param type A character vector indicating the type of "CIBERSORT", "custom".
#'
#' @returns A data frame containing sample IDs and intratumor immune heterogeneity scores -- ImTH score
#' @export
#'
#' @examples
#' # Example usage:
#' # result_bulk <- ImTH(data, type = "CIBERSORT")
#' # result_sc <- ImTH(data, type = "custom")

ImTH <- function(data, type = c("CIBERSORT", "custom")) {

  # Validate input
   if (nrow(data) == 0) {
  stop("Input data is empty")
  }

  if (missing(type)) {
    stop("The type parameter must be specified. You can choose: 'CIBERSORT' or 'custom'")
  }


  type <- match.arg(type)

  # Process based on input type
  if (type == "CIBERSORT") {
    # Default cell groups (22 immune cell types)
      cell_groups <- list(
        "B cells" = c("B cells naive", "B cells memory"),
        "T cells CD4" = c("T cells CD4 naive", "T cells CD4 memory resting", "T cells CD4 memory activated"),
        "NK cells" = c("NK cells resting", "NK cells activated"),
        "Macrophages" = c("Macrophages M0", "Macrophages M1", "Macrophages M2"),
        "Dendritic cells" = c("Dendritic cells resting", "Dendritic cells activated"),
        "Mast cells" = c("Mast cells resting", "Mast cells activated"),
        "Plasma cells" = c("Plasma cells"),
        "T cells CD8" = c("T cells CD8"),
        "T cells follicular helper" = c("T cells follicular helper"),
        "T cells regulatory (Tregs)" = c("T cells regulatory (Tregs)"),
        "T cells gamma delta" = c("T cells gamma delta"),
        "Monocytes" = c("Monocytes"),
        "Eosinophils" = c("Eosinophils"),
        "Neutrophils" = c("Neutrophils")
      )

    # Check for missing cell types
    missing_cells <- setdiff(unlist(cell_groups), colnames(data))
    if (length(missing_cells) > 0) {
      warning("Missing expected cell types: ", paste(missing_cells, collapse = ", "))
    }

    # Calculate grouped sums
    cell_totals <- lapply(cell_groups, function(group) {
      cols <- intersect(group, colnames(data))
      if (length(cols) > 0) rowSums(data[, cols, drop = FALSE]) else rep(0, nrow(data))
    })

    combined_matrix <- do.call(cbind, cell_totals)

  } else {  # single-cell or spatial transcriptomics data in which the cell composition of each spot has been inferred by deconvolution
    combined_matrix <- data  # Use all cell types directly
  }

    # Check the range of cell proportions
    if (any(combined_matrix < 0 | combined_matrix > 1)) {
        stop("All cell proportion values must be within the range of 0 to 1")
    }

    # Check the proportions of immune cell types and normalize them
    row_sums <- rowSums(combined_matrix)
    if (!all(abs(row_sums - 1) < 1e-6)) {
    warning(
        "Some samples exhibited total immune cell proportions that did not sum to 1. ",
        "These have been automatically scaled to sum to 1. ",
        "Please confirm this is appropriate for your data."
    )
        combined_matrix <- combined_matrix / row_sums
    }

  # Calculate ImTH score
  calculate_entropy <- function(x) {
    x <- x[x > 0]  # Remove zeros
    if (length(x) == 0) return(NA)
    -sum(x * log2(x))
  }

  scores <- apply(combined_matrix, 1, calculate_entropy)

  # Output results of ImTH scores for all samples
  result <- data.frame(
    Sample = rownames(combined_matrix),
    ImTH_Score = as.numeric(scores),
    stringsAsFactors = FALSE
  )

  return(result)
}
