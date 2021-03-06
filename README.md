# getSpatialData <a href="http://jxsw.de/getSpatialData"><img align="right" src="https://raw.githubusercontent.com/16EAGLE/AUX_data/master/data/gSD_hex.png" /></a>

[![CRAN version](https://www.r-pkg.org/badges/version/getSpatialData)](https://CRAN.R-project.org/package=getSpatialData)
[![Build Status](https://travis-ci.org/16EAGLE/getSpatialData.svg?branch=master)](https://travis-ci.org/16EAGLE/getSpatialData) 
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/16EAGLE/getSpatialData?branch=master&svg=true)](https://ci.appveyor.com/project/16EAGLE/getSpatialData)
[![Lifecycle:maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)

## Introduction

`getSpatialData` is an R package in an early development stage that ultimately aims to enable homogeneous and reproducible workflows to query, preview, analyze, select, order and download various kinds of spatial datasets from open sources.

The package enables generic access to multiple data distributors with a common syntax for **159** products.

Among others `getSpatialData` supports these products: *Sentinel-1*, *Sentinel-2*, *Sentinel-3*, *Sentinel-5P*, *Landsat 8 OLI*, *Landsat ETM*, *Landsat TM*, *Landsat MSS*, *MODIS (Terra & Aqua)* and *SRTM DEMs*. For this, `getSpatialData` facilitates access to multiple services implementing clients to public APIs of *ESA Copernicus Open Access Hub*, *USGS EarthExplorer*, *USGS EROS ESPA*, *Amazon Web Services (AWS)*, *NASA DAAC LAADS* and *NASA CMR search*. A full list of all supported products can be found below.

`getSpatialData` offers to quickly overview the data catalogues for a custom place and time period.
For an efficient handling of available earth observation data, it specifically calculates the cloud coverage of records
in an area of interest based on light preview images. Furthermore, `getSpatialData` is able
to automatically select records based on cloud cover and temporal user requirements.

## Installation

To install the current beta version, use `devtools`:

```R
devtools::install_github("16EAGLE/getSpatialData")
```

## Workflow

The `getSpatialData` workflow to query, preview, analyse, select, order and download spatial data is designed to be as reproducible as possible and is made of six steps: 

1. **querying** products of interest (see `get_products()`) for available records by an area of interest (AOI) and time (see `get_records()`),
2. **previewing** geometries and previews of the obtained records (see `get_previews()`, `view_records()` and `view_previews()`),
3. **analysing** records by deriving scene and AOI cloud distribution and coverage directly from preview imagery (see `calc_cloudcov()`),
4. **selecting** records based on user-defined measures (see `select_unitemporal()`, `select_bitemporal()` and `select_timeseries()`),
5. **ordering** datasets that are not available for immediate download (on-demand) but need to be ordered or restored before download (see `check_availability()` and `order_data()`), and lastly
6. **downloading** the full datasets for those records that have been selected in the process, solely based on meta and preview-dervied data.

For all steps, `getSpatialData` supports local chaching to reduce bandwith usage and uneccasary downloads.

This approach is implemented by the following functions (sorted by the order in which they would be typically used):

#### Logging in

* `login_CopHub()` logs you in at the ESA Copernicus Open Access Hub using your credentials (register once at https://scihub.copernicus.eu/).
* `login_USGS()` logs you in at the USGS EROS Registration System (ERS) using your credentials (register once at https://ers.cr.usgs.gov/register/).
* `login_earthdata()` logs you in at the NASA Earth Data User Registration System (URS) using your credentials (register once at https://urs.earthdata.nasa.gov/users/new)
* `services()` displays the status of all online services used by `getSpatialData`. 

#### Defining session settings

* `set_aoi()`, `view_aoi()` and `get_aoi()` set, view and get a session-wide area of interest (AOI) that can be used by all `getSpatialData` functions.
* `set_archive()` and `get_archive()` set and get a session-wide archive directory that can be used by all `getSpatialData` functions.

#### Retrieving and visualizing records

* `get_products()` obtains the names of all products available using `getSpatialData`. Currently, `getSpatialData` supports **159** products, including *Sentinel*, *Landsat*, *MODIS* and *SRTM* products.
* `get_records()` queries a service for available records using basic input search parameters such as product name, AOI and time range and returns an `sf data.frame` containing meta data and the geometries of each record.
* `view_records()` and `plot_records()` display the footprint geometries of each record on a map.

#### Analysing previews

* `get_previews()` downloads and georeferences preview images for visual inspection or automatic analysis and saves them to disk.
* `view_previews()` and `plot_previews()` load and display georeferenced previews acquired using `get_previews()`.
* `get_cloudcov_supported()` tells you for which products preview-based cloud coverages can be calculated using `calc_cloudcov()`.
* `calc_cloudcov()` calculates the AOI cloud cover and optionally saves raster cloud masks, all based on preview images.

#### Selecting records

Automatic remote sensing records selection is possible both for optical and SAR products.
`select_*` functionalities also support fusion of multiple optical products.
The selection is based on aoi cloud cover of optical records and temporal characterstics.
For optical records `select_*` uses preview cloud masks from `calc_cloudcov()` to create timestamp-wise mosaics.
It aims at cloud-free mosaics while ensuring user-defined temporal and product constraints.
* `get_select_supported()` tells you for which products automatic record selection is supported.
* `select_unitemporal()` selects remote sensing records *uni-temporally*
* `select_bitemporal()` selects remote sensing records *bi-temporally*
* `select_timeseries()` selects remote sensing records for a *time series*
* `is.*()`, such as `is.sentinel()`, `is.landsat()`, `is.modis()` and more to simplify filtering of records.

#### Checking, ordering and downloading records

* `check_availability()` checks for each record whether it is available for direct download (can be downloaded instantly) or not (and thus must be ordered before download).
* `order_data()` oders datasets that are not available for immediate download (on-demand) but need to be ordered or restored before download.
* `get_data()` downloads the full datasets per records.

#### Writing and reading

* `get_records_drivers()` provides the driver names that can be used in `write_records()`.
* `write_records()` writes records, e.g. as `GeoJSON`, for later use.
* `read_records()` reads records that have been written through `write_records()`.
* `read_previews()` reads georeferences preview images downloaded using `get_previews()`.

## Get started

```R
library(getSpatialData)

 # use example aoi
set_aoi(aoi_data[[1]])
view_aoi()

# define archive directory
set_archive("/path/to/archive/dir")

# login
login_CopHub() # login Copernicus Open Access Hub
login_USGS() # login USGS

# print available products
get_products()
products <- c("Sentinel-2", "LANDSAT_8_C1")

# get available records
records <- get_records(c("2020-05-01", "2020-05-15"), products = products) 

# for Sentinel-2 use only Level 2A
sub <- c(which(is.sentinel2_L2A(records)), which(is.landsat8())) 
records_sub <- records[sub, ] # subset

# get preview images
records_previews <- get_previews(records_sub) 

# view previews with basemap
view_previews(records_previews) 

# calc cloudcov in your aoi
records_cloudcov <- calc_cloudcov(records_previews) 
records_selected <- select_unitemporal(records_cloudcov) # select records for single timestamp
```

## Supported products

## Contribution

We are happy about any kind of contribution, from feature ideas, ideas on possible data sources, technical ideas or other to bug fixes, code suggestions or larger code contributions! Open an issue to start a discussion: <https://github.com/16eagle/getSpatialData/issues> 

## Mentioned

`getSpatialData` has been mentioned here:

Kwok, R., 2018. Ecology’s remote-sensing revolution. Nature 556, 137. https://doi.org/10.1038/d41586-018-03924-9



