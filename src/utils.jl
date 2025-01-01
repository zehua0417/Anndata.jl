function minimum_unsigned_type_for_n(n::Number)
  local mintype::Type
  for type in [UInt8, UInt16, UInt32, UInt64, UInt128]
    mval = typemax(type)
    if mval >= n
      mintype = type
      break
    end
  end
  return mintype
end

backed_matrix(obj::Union{HDF5.File, HDF5.Group}) = SparseDataset(obj)
backed_matrix(obj::HDF5.Dataset) = TransposedDataset(obj)

function hdf5_object_name(obj::Union{HDF5.File, HDF5.Group, HDF5.Dataset})
  name = HDF5.name(obj)
  return name[(last(findlast("/", name)) + 1):end]
end

isbacked(ad::AbstractAnnData) = !isnothing(file(ad))

@inline function convertidx(
  idx::Union{AbstractUnitRange, Colon, AbstractVector{<:Integer}, AbstractVector{Bool}},
  ref::AbstractIndex{<:AbstractString},
)
  return idx
end
@inline function convertidx(idx::Number, ref::AbstractIndex{<:AbstractString})
  return idx:idx
end
@inline convertidx(
  idx::Union{AbstractString, AbstractVector{<:AbstractString}},
  ref::AbstractIndex{<:AbstractString},
) = ref[idx, true]

@inline function Base.checkbounds(::Type{Bool}, A::AbstractAnnData, I...)
  Base.checkbounds_indices(
    Bool,
    axes(A),
    Tuple(i isa AbstractString || i isa AbstractVector{<:AbstractString} ? (:) : i for i in I),
  )
end

@inline function Base.checkbounds(A::AbstractAnnData, I...)
  checkbounds(Bool, A, I...) || throw(BoundsError(A, I))
  nothing
end

Base.copy(d::AnnDataView) = parent(d)[parentindices(d)...]

function Base.sort!(idx::AbstractArray, vals::AbstractArray...)
    if !issorted(idx)
        ordering = sortperm(idx)
        permute!(idx, ordering)
        for v in vals
            permute!(v, ordering)
        end
    end
end
