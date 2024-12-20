module Anndata

using Random
using SparseArrays
import LinearAlgebra: Adjoint
using HDF5
using DataFrames
using CategoricalArrays
using StructArrays
using PooledArrays
import CompressHashDisplace: FrozenDict
using FileIO

export readh5ad, writeh5ad, isbacked
export AnnData

ANNDATAVERSION = v"0.1.0"

import Pkg
# this executes only during precompilation
let
  pkg = Pkg.Types.read_package(joinpath(@__DIR__, "..", "Project.toml"))
  global VERSION = pkg.version
  global NAME = pkg.name * ".jl"
end

include("index.jl")
include("sparsedataset.jl")
include("transposeddataset.jl")
include("hdf5_io.jl")
include("alignedmapping.jl")
include("anndata.jl")
include("utils.jl")
end # module Anndata
