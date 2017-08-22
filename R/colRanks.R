### ============================================================================
### colRanks
###

### ----------------------------------------------------------------------------
### Non-exported methods
###

#' `colRanks()` block-processing internal helper
#' @inherit matrixStats::colRanks
#' @importFrom methods is
.DelayedMatrix_block_colRanks <-
  function(x, rows = NULL, cols = NULL,
           ties.method = c("max", "average", "min"), dim. = dim(x),
           preserveShape = FALSE, ...) {
    # Check input type
    ties.method <- match.arg(ties.method)
    stopifnot(is(x, "DelayedMatrix"))
    stopifnot(!x@is_transposed)
    DelayedArray:::.get_ans_type(x)

    # Subset
    x <- ..subset(x, rows, cols)

    # Compute result
    val <- DelayedArray:::colblock_APPLY(x = x,
                                         APPLY = matrixStats::colRanks,
                                         ties.method = ties.method,
                                         dim. = dim(x),
                                         preserveShape = preserveShape,
                                         ...)
    if (length(val) == 0L) {
      return(numeric(ncol(x)))
    }
    # NOTE: Return value of matrixStats::colRanks() has no names
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
#' @rdname colRanks
#' @template common_params
#' @export
setMethod("colRanks", "DelayedMatrix",
          function(x, rows = NULL, cols = NULL,
                   ties.method = c("max", "average", "min"), dim. = dim(x),
                   preserveShape = FALSE, force_block_processing = FALSE, ...) {
            ties.method <- match.arg(ties.method)
            if (!hasMethod("colRanks", class(seed(x))) ||
                force_block_processing) {
              message2("Block processing", get_verbose())
              return(
                .DelayedMatrix_block_colRanks(x = x,
                                              rows = rows,
                                              cols = cols,
                                              ties.method = ties.method,
                                              dim. = dim.,
                                              preserveShape = preserveShape,
                                              ...))
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
                return(colRanks(x = x,
                                rows = rows,
                                cols = cols,
                                ties.method = ties.method,
                                dim. = dim.,
                                preserveShape = preserveShape,
                                force_block_processing = TRUE,
                                ...))
              }
            }

            colRanks(x = simple_seed_x,
                     rows = rows,
                     cols = cols,
                     ties.method = ties.method,
                     dim. = dim.,
                     preserveShape = preserveShape,
                     ...)
          }
)

# ------------------------------------------------------------------------------
# Seed-aware methods
#

#' @importFrom methods setMethod
#' @export
setMethod("colRanks", "matrix", matrixStats::colRanks)