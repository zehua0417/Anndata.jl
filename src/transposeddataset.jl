# Julia stores arrays in column-major order, whereas NumPy stores arrays in row-major order.
# Both languages save arrays to HDF5 following their memory layout, so arrays that were saved
# using h5py are transposed in Julia and vice versa. To guarantee compatibility for backed files,
# we need an additional translation layer that transposes array accesses

struct TransposedDataset{T, N} <: AbstractArray{T, N}
  dset::HDF5.Dataset

  function TransposedDataset(dset::HDF5.Dataset)
    return new{eltype(dset), ndims(dset)}(dset)
  end
end

function Base.getproperty(dset::TransposedDataset, s::Symbol)
  if s === :id
    return getfield(dset, :dset).id
  elseif s === :file
    return getfield(dset, :dset).file
  elseif s === :xfer
    return getfield(dset, :dset).xfer
  else
    return getfield(dset, s)
  end
end

HDF5.filename(dset::TransposedDataset) = HDF5.filename(dset.dset)
HDF5.copy_object(
  src_obj::TransposedDataset,
  dst_parent::Union{HDF5.File, HDF5.Group},
  dst_path::AbstractString,
) = copy_object(src_obj.dset, dst_parent, dst_path)
HDF5.isvalid(dset::TransposedDataset) = isvalid(dset.dset)
function HDF5.readmmap(dset::TransposedDataset, ::Type{T}) where {T}
  return HDF5.readmmap(dset.dset, T)'
end
HDF5.ismmappable(dset::TransposedDataset) = HDF5.ismmappable(dset.dset)
HDF5.iscontiguous(dset::TransposedDataset) = HDF5.iscontiguous(dset.dset)

Base.to_index(A::HDF5.Dataset, I::AbstractUnitRange{<:Unsigned}) =
  Base.to_index(A, UnitRange{Int}(I)) # hyperslab only supports Int indexes
Base.ndims(dset::TransposedDataset) = ndims(dset.dset)
Base.size(dset::TransposedDataset) = reverse(size(dset.dset))
Base.size(dset::TransposedDataset, d::Integer) = size(dset.dset, ndims(dset.dset) - d + 1)

Base.lastindex(dset::TransposedDataset) = length(dset)
Base.lastindex(dset::TransposedDataset, d::Int) = size(dset, d)
HDF5.datatype(dset::TransposedDataset) = datatype(dset.dset)
Base.read(dset::TransposedDataset) = read_matrix(dset.dset)

Base.getindex(dset::TransposedDataset, i::Integer) =
  getindex(dset.dset, to_indices(dset, (CartesianIndices(dset)[i],)))
function Base.getindex(dset::TransposedDataset, I::Vararg{<:Integer, N}) where {N}
  mat = getindex(dset.dset, reverse(I)...)
  return ndims(mat) == 1 ? mat : mat'
end
function Base.getindex(dset::TransposedDataset{T, N}, I...) where {T, N}
  @boundscheck checkbounds(dset, I...)
  I = to_indices(dset, I)
  emptydims = Vector{UInt8}()
  for (j, i) in enumerate(I)
    if !(i isa Colon) && isempty(i) # Colon doesn't support isempty
      push!(emptydims, j)
    end
  end
  if !isempty(emptydims)
    dims = collect(size(dset))
    dims[emptydims] .= UInt8(0)
    @inbounds return Array{T, N}(undef, dims...)[I...]
  end

  # HDF5.Dataset doesn't support indexing with integer arrays
  vectordims = findall(x -> !(x isa AbstractRange) && x isa AbstractVector{<:Integer}, I)
  @inbounds if length(vectordims) > 0
    dims = Vector{Int}(undef, length(I))
    for (i, j) in enumerate(I)
      dims[i] = (j isa Colon) ? size(dset, i) : length(j) # Colon doesn't support length
    end
    _ndims = length(dims)
    mat = Array{T, N}(undef, dims...)
    outidx = Vector{Union{Colon, Int}}(undef, _ndims)
    dims_todrop = Vector{Int}()
    for (i, j) in enumerate(I)
      if j isa Number
        push!(dims_todrop, i)
        outidx[i] = 1
      else
        outidx[i] = (:)
      end
    end
    outidx[vectordims] .= 0
    inidx = Vector{Union{typeof.(I)..., (eltype(I[i]) for i in vectordims)...}}(undef, _ndims)
    inidx .= reverse(I)

    for ix in Iterators.product((1:length(I[i]) for i in vectordims)...)
      for (i, j) in enumerate(ix)
        outidx[vectordims[i]] = j
        inidx[_ndims - vectordims[i] + 1] = I[vectordims[i]][j]
      end
      mat[outidx...] = dset.dset[inidx...]
    end
    return dropdims(mat, dims=Tuple(dims_todrop))
  else
    mat = getindex(dset.dset, reverse(I)...)
    return ndims(mat) == 1 ? mat : mat'
  end
end
Base.setindex!(dset::TransposedDataset, v, i::Int) =
  setindex!(dset.dset, v, ndims(dset.dset) - i + 1)
function Base.setindex!(dset::TransposedDataset, v, I::Vararg{Int, N}) where {N}
  if ndims(v) > 1
    v = copy(v')
  end
  setindex!(dset.dset, v, reverse(I)...)
end
function Base.setindex!(dset::TransposedDataset, v, I...)
  if ndims(v) > 1
    v = copy(v')
  end
  setindex!(dset.dset, v, reverse(I)...)
end

Base.eachindex(dset::TransposedDataset) = CartesianIndices(size(dset))

function Base.show(io::IO, dset::TransposedDataset)
  if isvalid(dset)
    print(
      io,
      "Transposed HDF5 dataset: ",
      HDF5.name(dset.dset),
      " (file: ",
      dset.file.filename,
      " xfer_mode: ",
      dset.xfer.id,
      ")",
    )
  else
    print(io, "Transposed HDF5 datset: (invalid)")
  end
end

function Base.show(io::IO, ::MIME"text/plain", dset::TransposedDataset)
  if get(io, :compact, false)::Bool
    show(io, dset)
  else
    print(io, HDF5._tree_icon(HDF5.Dataset), " ", dset)
  end
end
