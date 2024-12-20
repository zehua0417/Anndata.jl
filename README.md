# AnnData.jl

AnnData.jl is a Julia package that provides robust support for working with AnnData, a common data structure used in single-cell bioinformatics. This package is derived from the [Muon.jl](https://github.com/scverse/Muon.jl) library, but specifically focuses on handling AnnData objects, without including functionality for multi-omics data types.

By extracting the AnnData-specific components from Muon.jl, we aim to provide a lightweight and efficient package for users who only need to work with AnnData, while maintaining compatibility with Python's AnnData (via the `h5ad` file format).

## Features

- Load and save AnnData objects (`h5ad` files).
- Manipulate AnnData matrices, metadata, and annotations in Julia.
- Seamless interoperability with Python's AnnData ecosystem (e.g., Scanpy).

## Why AnnData.jl?

The [Muon.jl](https://github.com/scverse/Muon.jl) package is a comprehensive toolkit for multi-omics data analysis, but not all users require multi-omics support. AnnData.jl was created to focus solely on the core AnnData functionality, providing:

- A smaller dependency footprint.
- Simplified workflows for single-cell analysis using AnnData objects.

## todo

docs
