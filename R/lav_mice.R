#' Fit SEM Model to Each Dataset in a MIDS Object Without Pooling
#'
#' Fits a SEM model to each dataset in a `mids` object without pooling the results.
#' This function is an extension for the [lavaan::sem()] function to handle [mice::mids] objects from the [mice] package.
#' It allows for both a SEM model syntax as a character string or a pre-fitted [lavaan] model object.
#'
#' @param model Either a character string representing the SEM model to be fitted or a pre-fitted [lavaan] model object.
#' @param mids A `mids` object from the [mice] package.
#' @param ... Additional arguments to be passed to [lavaan::sem()].
#' @return A list of [lavaan] model fits, one for each imputed dataset.
#' @examples
#' \dontrun{
#' # library(mice)
#' # library(lavaan)
#' # Load Holzinger and Swineford (1939) dataset
#' data("HolzingerSwineford1939", package = "lavaan")
#' # Introduce missing data
#' df_complete <- na.omit(HolzingerSwineford1939)
#' amp <- mice::ampute(df_complete, prop = 0.2, mech = "MAR")
#' data_with_missing <- amp$amp
#'
#' # Perform multiple imputation
#' imputed_data <- mice::mice(data_with_missing, m = 3, maxit = 5, seed = 12345, printFlag = FALSE)
#'
#' # fit the Holzinger and Swineford (1939) example model
#' HS_model <- " visual  =~ x1 + x2 + x3
#'              textual =~ x4 + x5 + x6
#'              speed   =~ x7 + x8 + x9 "
#' # Fit the SEM model without running
#' fit_HS <- lavaan::sem(HS_model, data = data_with_missing, do.fit = FALSE)
#' # Fit the SEM model without pooling to each imputed dataset
#' fit_list1 <- lav_mice(HS_model, imputed_data)
#' # 'fit_list1' now contains a list of lavaan objects, one for each imputed dataset
#' # Fit the SEM model without pooling to each imputed dataset using a pre-fitted model object
#' fit_list2 <- lav_mice(fit_HS, imputed_data)
#' # 'fit_list2' now contains a list of lavaan objects, one for each imputed dataset
#' }
#' @export
#' @import mice
#' @importFrom lavaan sem
#' @importFrom mice mice complete pool
#' @importFrom stats update
#' @author Davood Tofighi \email{dtofighi@@gmail.com}

lav_mice <- function(model, mids, ...) {
  # Ensure 'mids' is a 'mids' object from the 'mice' package
  if (!inherits(mids, "mids")) {
    stop("'mids' must be a 'mids' object from the 'mice' package.")
  }

  # Ensure 'model' is either a character string or a lavaan model object

  if (is_valid_lav_syntax(model, mids$data)) {
    stop("The model is not a valid lavaan model syntax.")
  }
  # Determine if 'model' is a character string or a lavaan model
  is_lav_object <- inherits(model, "lavaan")

  # Extract complete imputed datasets
  data_complete <-
    lapply(1:mids$m, function(i) {
      mice::complete(mids, action = i)
    })

  # Fit SEM model to each imputed dataset or update the model with new data
  sem_results <- lapply(data_complete, function(data) {
    if (is_lav_object) {
      # Update the model with new data
      updated_model <- update(model, data = data)
      return(updated_model)
    } else {
      # Fit the model as a character string
      return(lavaan::sem(model, data = data, ...))
    }
  })

  # Return list of SEM model fits
  return(sem_results)
}
