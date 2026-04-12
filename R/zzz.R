#' @importFrom data.table :=
#' @keywords internal
NULL

.datatable.aware <- TRUE

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(
    "M", "P", "B",
   "FamilyIndex", "IndividualID", "Role", "Role_BMP" 
 ))
}
