#' Fitting piecewise structural equation models
#'
#' \code{psem} is used to unite a list of structural equations into a single
#' structural equation model.
#'
#' \code{psem} takes a list of structural equations, which can be model objects
#' of classes: \code{lm, glm, gls, pgls, sarlm, lme, glmmPQL, lmerMod,
#' merModLmerTest, glmerMod}.
#'
#' It also takes objects of class \code{formula, formula.cerror}, corresponding
#' to additional variables to be included in the tests of directed separation
#' (\code{X ~ 1}) or correlated errors (\code{X1 \%~~\% X2}).
#'
#' The function optionally accepts data objects of classes: \code{matrix,
#' data.frame, SpatialPointsDataFrame, comparative.data}, or these are derived
#' internally from the structural equations.
#'
#' @param \dots A list of structural equations.
#' @param data A \code{data.frame} used to fit the equations.
#' @return Returns an object of class \code{psem}.
#' @author Jon Lefcheck <jlefcheck@@bigelow.org>
#' @seealso \code{\link{summary.psem}}, \code{\link{\%~~\%}}
#' 
#' @export
#' 
psem <- function(..., data) {

  x <- list(...)

  x <- formatpsem(x)

  class(x) <- "psem"
  
  x
  
}

#' Format for psem
#' 
#' @keywords internal
#' 
formatpsem <- function(x) {

  idx <- which(sapply(x, function(y) any(class(y) %in% c("matrix", "data.frame", "SpatialPointsDataFrame", "comparative.data"))))

  if(sum(idx) == 0) idx <- which(names(x) == "data")

  if(sum(idx) > 0) {

    if(is.null(names(x))) names(x) <- 1:length(x)

    names(x)[idx] <- "data"

    x$data <- x$data

  } else {

    x$data <- GetData(x)

  }

  if(any(is.na(names(x)))) {

    idx. <- which(is.na(names(x)))

    names(x)[idx.] <- idx.

  }

  # if(any(sapply(x$data, is.na))) stop("NAs detected in the dataset! Remove before running `psem`.", call. = FALSE)

  # if(any(sapply(x$data, class) == "factor"))
  #
  #   stop("Some predictors in the model are factors. Respecify as binary or ordered numeric!", call. = FALSE)

  evaluateClasses(x)

  formulaList <- listFormula(x, formulas = 1)

  if(any(duplicated(sapply(formulaList, function(y) all.vars.merMod(y)[1]))))

    stop("Duplicate responses detected in the model list. Collapse into single multiple regression!", call. = FALSE)

  x

}

#' Convert list to psem object
#' 
#' @param object any \code{R} object
#' @param Class the name of the class to which \code{object} should be coerced
#' 
#' @export
#' 
as.psem <- function(object, Class = "psem") { 
  
  object <- formatpsem(object)
  
  class(object) <- Class
  
  object
  
}

#' Evaluate model classes and stop if unsupported model class
#' 
#' @keywords internal
#' 
evaluateClasses <- function(modelList) {

  classes <- unlist(sapply(modelList, class))

  classes <- classes[!duplicated(classes)]

  model.classes <- c(
    "character",
    "matrix", "data.frame", "SpatialPointsDataFrame", "comparative.data",
    "formula", "formula.cerror",
    "lm", "glm", "gls", "negbin",
    "lme", "glmmPQL",
    "lmerMod", "merModLmerTest", "glmerMod",
    "sarlm",
    "pgls", "phylolm", "phyloglm"
  )

  if(!all(classes %in% model.classes))

    stop(
      paste0(
        "Unsupported model class in model list: ",
        paste0(classes[!classes %in% model.classes], collapse = ", "),
        ". See 'help(piecewiseSEM)' for more details."),
      call. = FALSE
    )

}

#' Print psem
#' 
#' @param x an object of class pse,
#' @param ... further arguments passed to or from other methods
#' 
#' @method print psem
#' 
#' @export
#' 
print.psem <- function(x, ...) {

  formulas <- listFormula(x)

  formulas_print <- sapply(1:length(formulas), function(i) {

    if(class(formulas[[i]]) == "formula.cerror")

      paste0("Correlated error: ", paste(formulas[[i]])) else

        paste0(class(x[[i]])[1], ": ", deparse(formulas[[i]]))

  } )

  data_print <- if(!is.null(x$data)) head(x$data) else head(GetData(x))

  class_print <- paste0("class(", class(x), ")")

  cat("Structural Equations:\n")

  cat(paste(formulas_print, collapse = "\n"))

  cat("\n\nData:\n")

  print(data_print)

  cat(paste("...with ", dim(x$data)[1], " more rows"))

  cat("\n\n")

  print(class_print)

}

#' Update psem model object with additional values.
#' 
#' @param object a psem object to update
#' @param ... additional arguments to update
#' 
#' @method update psem
#' 
#' @export
#' 
update.psem <- function(object, ...) {

  l <- list(...)

  for(i in l) {

    if(all(class(i) %in% c("matrix", "data.frame", "SpatialPointsDataFrame", "comparative.data"))) {

      idx <- which(names(object) == "data")

      if(length(idx) == 0) object$data = i else

        object[[idx]] <- i

      object <- lapply(object, function(j) {

        if(!any(class(j) %in% c("matrix", "data.frame", "SpatialPointsDataFrame", "comparative.data", "formula", "formula.cerror")))

          update(j, data = i) else j

      } )

    } else if(all(class(i) %in% c("character", "formula", "formula.cerror"))) {

      if(length(all.vars.merMod(i)) == 1 | class(i) %in% "formula.cerror") {

        idx <- which(names(object) == "data")

        object <- append(object[-idx], list(i, data = object[[idx]]))

      } else {

        resp <- sapply(object, function(y) if(!any(class(y) %in% c("matrix", "data.frame", "SpatialPointsDataFrame", "comparative.data")))

          all.vars.merMod(y)[1] else "")

        idx <- which(resp == all.vars.merMod(i)[1])

        object[[idx]] <- update(object[[idx]], i)

      }

    } else {

      object[[length(object) + 1]] <- i

    }

  }

  evaluateClasses(object)

  class(object) <- "psem"

  return(object)

}

# New operators for latent, composite variables

# `%~=%`

# `%~+%`
