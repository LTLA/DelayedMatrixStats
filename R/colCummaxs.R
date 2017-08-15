### ============================================================================
### colCummaxs
###

###-----------------------------------------------------------------------------
### Non-exported methods
###

#' `colCummaxs()` block-processing internal helper
#' @inherit matrixStats::colCummaxs
#' @importFrom methods is
.DelayedMatrix_block_colCummaxs <- function(x, rows = NULL, cols = NULL,
                                            dim. = dim(x), ...) {
  # Check input type
  stopifnot(is(x, "DelayedMatrix"))
  stopifnot(!x@is_transposed)
  DelayedArray:::.get_ans_type(x)

  # Subset
  x <- ..subset(x, rows = rows, cols = cols)

  # Compute result
  val <- DelayedArray:::colblock_APPLY(x,
                                       matrixStats::colCummaxs,
                                       dim. = dim(x),
                                       ...)
  if (length(val) == 0L) {
    return(numeric(ncol(x)))
  }
  # NOTE: Return value of matrixStats::colCummaxs() has no names
  unname(do.call(cbind, val))
}

### ----------------------------------------------------------------------------
### Exported methods
###

# ------------------------------------------------------------------------------
# General method
#

#' @importFrom DelayedArray seed
#' @importFrom methods hasMethod is
#' @rdname colCummaxs
#' @template common_params
#' @export
setMethod("colCummaxs", "DelayedMatrix",
          function(x, rows = NULL, cols = NULL, dim. = dim(x),
                   force_block_processing = FALSE, ...) {
            if (!hasMethod("colCummaxs", class(seed(x))) ||
                force_block_processing) {
              message2("Block processing", get_verbose())
              return(.DelayedMatrix_block_colCummaxs(x, rows, cols, dim., ...))
            }

            message2("Has seed-aware method", get_verbose())
            if (DelayedArray:::is_pristine(x)) {
              message2("Pristine", get_verbose())
              simple_seed_x <- seed(x)
            } else {
              message2("Coercing to seed class", get_verbose())
              # TODO: do_transpose trick
              simple_seed_x <- try(from_DelayedArray_to_simple_seed_class(x),
                                   silent = TRUE)
              if (is(simple_seed_x, "try-error")) {
                message2("Unable to coerce to seed class", get_verbose())
                return(colCummaxs(x, rows, cols, dim.,
                                  force_block_processing = TRUE, ...))
              }
            }

            colCummaxs(simple_seed_x, rows, cols, dim., ...)
          }
)

# ------------------------------------------------------------------------------
# Seed-aware methods
#

#' @importFrom methods setMethod
#' @export
setMethod("colCummaxs", "matrix", matrixStats::colCummaxs)