### ============================================================================
### colAvgsPerRowSet
###

### ----------------------------------------------------------------------------
### Non-exported methods
###

#' `colAvgsPerRowSet()` block-processing internal helper
#' @inherit matrixStats::colAvgsPerRowSet
#' @importFrom methods is
.DelayedMatrix_block_colAvgsPerRowSet <- function(X, W = NULL, cols = NULL, S,
                                                  FUN = colMeans, tFUN = FALSE,
                                                  ...) {
  # Check input type
  stopifnot(is(X, "DelayedMatrix"))
  if (is(W, "DelayedMatrix")) {
    warning("'W' will be realised in-memory as a matrix")
    W <- as.matrix(W)
  }
  if (is(S, "DelayedMatrix")) {
    warning("'S' will be realised in-memory as a matrix")
    S <- as.matrix(S)
  }
  stopifnot(!X@is_transposed)
  DelayedArray:::.get_ans_type(X)

  # Subset
  X <- ..subset(X, cols = cols)

  # Compute result
  val <- DelayedArray:::colblock_APPLY(x = X,
                                       APPLY = matrixStats::colAvgsPerRowSet,
                                       W = W,
                                       S = S,
                                       FUN = FUN,
                                       tFUN = tFUN,
                                       ...)
  if (length(val) == 0L) {
    return(numeric(ncol(X)))
  }
  # NOTE: Return value of matrixStats::colAvgsPerRowSet() has names
  do.call(cbind, val)
}

### ----------------------------------------------------------------------------
### Exported methods
###

# ------------------------------------------------------------------------------
# General method
#

#' @importFrom DelayedArray seed
#' @importFrom methods hasMethod is
#' @rdname colAvgsPerRowSet
#' @template common_params
#' @export
setMethod("colAvgsPerRowSet", "DelayedMatrix",
          function(X, W = NULL, cols = NULL, S, FUN = colMeans, tFUN = FALSE,
                   force_block_processing = FALSE, ...) {
            if (!hasMethod("colAvgsPerRowSet", class(seed(X))) ||
                force_block_processing) {
              message2("Block processing", get_verbose())
              return(.DelayedMatrix_block_colAvgsPerRowSet(X = X,
                                                           W = W,
                                                           cols = cols,
                                                           S = S,
                                                           FUN = FUN,
                                                           tFUN = tFUN,
                                                           ...))
            }

            message2("Has seed-aware method", get_verbose())
            if (DelayedArray:::is_pristine(X)) {
              message2("Pristine", get_verbose())
              simple_seed_X <- seed(X)
            } else {
              message2("Coercing to seed class", get_verbose())
              # TODO: do_transpose trick
              simple_seed_X <- try(from_DelayedArray_to_simple_seed_class(X),
                                   silent = TRUE)
              if (is(simple_seed_X, "try-error")) {
                message2("Unable to coerce to seed class", get_verbose())
                return(colAvgsPerRowSet(X = X,
                                        W = W,
                                        cols = cols,
                                        S = S,
                                        FUN = FUN,
                                        tFUN = tFUN,
                                        force_block_processing = TRUE,
                                        ...))
              }
            }

            colAvgsPerRowSet(X = simple_seed_X,
                             W = W,
                             cols = cols,
                             S = S,
                             FUN = FUN,
                             tFUN = tFUN,
                             ...)
          }
)

# ------------------------------------------------------------------------------
# Seed-aware methods
#

#' @importFrom methods setMethod
#' @export
setMethod("colAvgsPerRowSet", "matrix", matrixStats::colAvgsPerRowSet)
