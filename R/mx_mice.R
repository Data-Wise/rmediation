#' Fit OpenMx model to multiply imputed datasets
#'
#' @description
#' This function fits an OpenMx model to each imputed dataset in a 'mids' object
#' from the 'mice' package. The function returns a list of OpenMx model fits.
#'
#' @param model An OpenMx model object.
#' @param mids A 'mids' object from the 'mice' package.
#' @param ... Additional arguments to be passed to 'mxRun'.
#' @return A list of OpenMx model fits.
#' @export
#' @examples
#' \dontrun{
#' # library(OpenMx)
#' # library(mice)
#' # Fit a model to multiply imputed datasets
#' data("HolzingerSwineford1939", package = "lavaan")
#' # Introduce missing data
#' df_complete <- na.omit(HolzingerSwineford1939)
#' amp <- mice::ampute(df_complete, prop = 0.2, mech = "MAR")
#' df_incomplete <- amp$amp
#' # Perform multiple imputation
#' imputed_data <- mice(df_incomplete, m = 3, method = "pmm", maxit = 5, seed = 12345)
#' # Simple SEM model specification with OpenMx
#' manifestVars <- paste0("x", 1:9)
#' latVar <- c("visual", "textual", "speed")
#' model <- mxModel("Simple SEM",
#'   type = "RAM",
#'   manifestVars = manifestVars,
#'   latentVars = latVar,
#'   mxPath(from = "visual", to = c("x1", "x2", "x3")),
#'   mxPath(from = "textual", to = c("x4", "x5", "x6")),
#'   mxPath(from = "speed", to = c("x7", "x8", "x9")),
#'   mxPath(from = manifestVars, arrows = 2),
#'   mxPath(from = latVar, arrows = 2, free = FALSE, values = 1.0),
#'   mxPath(from = "one", to = manifestVars, arrows = 1, free = TRUE, values = 1.0),
#'   mxPath(from = "one", to = latVar, arrows = 1, free = FALSE, values = 0),
#'   mxData(df_complete, type = "raw")
#' )
#' # Assuming mx_mice is correctly defined in your environment
#' fits <- mx_mice(model, imputed_data)
#' summary(fits[[1]])
#' }
#' @import mice
#' @importFrom OpenMx mxModel mxData mxRun omxLapply imxVerifyModel
#' @importFrom mice mice complete
#' @rdname mx_mice
#' @author Davood Tofighi \email{dtofighi@@gmail.com}



mx_mice <- function(model, mids, ...) {
  # Ensure 'mids' is a 'mids' object
  if (!inherits(mids, "mids")) {
    stop("'mids' must be a 'mids' object from the 'mice' package.")
  }
  # Ensure 'mxModel' is an OpenMx model object
  if (!inherits(model, "MxModel")) {
    stop("'mids' must be an 'MxModel' object from the 'OpenMx' package.")
  }

  # Assuming myModel is your mxModel object and imxVerifyModel() is a conceptual verification function
  # Note: This assumes imxVerifyModel() returns TRUE if the model is correct, otherwise FALSE
  verified <- OpenMx::imxVerifyModel(model)
  if (!verified) {
    stop("The mxModel object failed verification.")
  }

  # Extract the complete imputed datasets
  data_complete <- OpenMx::omxLapply(1:mids$m, function(i) mice::complete(mids, action = i))

  # Fit the OpenMx model to each imputed dataset
  mx_results <- OpenMx::omxLapply(data_complete, function(data) {
    # Update the model with the new data
    mxDataObj <- OpenMx::mxData(data, type = "raw")
    updatedModel <- OpenMx::mxModel(model, mxDataObj)

    # Fit the model
    fit <- OpenMx::mxRun(updatedModel)
    return(fit)
  })

  # Return list of OpenMx model fits
  return(mx_results)
}
