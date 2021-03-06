#' test of is.modis checks from is_product_checker
# -----------------------------------------------------------------------------------------

product_group <- "MODIS"
product1 <- "MODIS_MOD09A1_V6"
product2 <- "MODIS_MYD09A1_V6"
dummy_records <- data.frame("product" = c(product1, product2, "Sentinel-2", "some_other_product"), 
                            "product_group" = c(product_group, product_group, 
                                                "Sentinel", "some_other_product_group"),
                            "record_id" = c("MOD09A1.A2019241.h18v05.006", "MYD09A1.A2019241.h18v05.006",
                                            "S2B_MSIL12A_20190905T095031_N0208_R079_T33TWL_20190905T110359", 
                                            "s_omething_else"), stringsAsFactors = F)

# Test is.modis
should_be <- c(TRUE, TRUE, FALSE, FALSE)
value <- is.modis(dummy_records)
expect_equal(value, should_be)

# Test is.modis_terra
should_be <- c(TRUE, FALSE, FALSE, FALSE)
value <- is.modis_terra(dummy_records)
expect_equal(value, should_be)

# Test is.modis_aqua
should_be <- c(FALSE, TRUE, FALSE, FALSE)
value <- is.modis_aqua(dummy_records)
expect_equal(value, should_be)
