using Graphs, MetaGraphsNext

struct OboId{type, V}
    val::V
end

OboId{type}(val::V) where {type, V} = OboId{type, V}(val)
OboId(type::Symbol, val) = OboId{type}(val)

function Base.parse(::Type{OboId}, id::AbstractString)
    type, val = if startswith(id, "http")
        tv = split(last(split(id, '/')), '_')
        ifelse(length(tv) == 2, tv, ("", ""))
    elseif occursin(':', id)
        split(id, ':')
    else
        "", ""
    end
    if !isempty(type)
        try parse(Int, val) catch err
            @info "" id val
        end
        OboId{Symbol(type)}(@something(tryparse(Int, val), val))
    end
end

Base.string(id::OboId{type}) where {type} =
    string(type, ':', string(id.val))

function Base.show(io::IO, ::MIME"text/plain", id::OboId{type}) where {type}
    if get(io, :compact, false)
        print(io, string(id))
    else
        print(io, "OboId(", type, ':', id.val, ")")
    end
end

function Base.show(io::IO, id::OboId{type}) where {type}
    if get(io, :compact, false)
        show(io, MIME("text/plain"), id)
    else
        print(io, "OboId(:", type, ", ", sprint(show, id.val), ")")
    end
end

Base.isless(a::OboId{Ta}, b::OboId{Tb}) where {Ta, Tb} =
    Ta < Tb || a.val < b.val

struct OboTerm{type}
    id::OboId{type}
    label::Union{String, Nothing}
    attrs::Dict{Symbol, Any}
end

function Base.show(io::IO, ::MIME"text/plain", term::OboTerm)
    print(io, "OboTerm(", string(term.id))
    if !isnothing(term.label)
        print(io, ", ")
        show(io, term.label)
    end
    function showvals(indent::Int, val::Dict)
        if haskey(val, :pred)
            print(io, '{')
            show(io, val[:pred])
            print(io, " => ")
        end
        if haskey(val, :val)
            show(val[:val])
        end
        vkeys = setdiff(collect(keys(val)), (:val, :pred))
        for vkey in vkeys
            vval = val[vkey]
            print(io, ",\n", ' '^indent)
            show(io, vkey)
            print(io, " => ")
            if vval isa Dict
                showvals(indent + 2, vval)
            elseif vval isa Vector{<:Dict}
                print(io, '[')
                for vvval in vval
                    showvals(indent + 2, vvval)
                    vvval === last(vval) || print(io, ",\n", ' '^(indent+2))
                end
                print(io, ']')
            else
                show(io, vval)
            end
        end
        haskey(val, :pred) && print(io, '}')
    end
    if !isempty(term.attrs)
        showvals(2, term.attrs)
    end
    print(io, ")")
end

struct OboInfo
    id::Symbol
    name::String
    description::String
end

const OboGraph = MetaDiGraph{Int, OboId, SimpleDiGraph{Int}, OboTerm, Symbol, OboInfo, Returns{Int}, Int}

OboGraph(id::Symbol, name::String="", description::String="") =
    MetaGraph(DiGraph{Int}(), Label = OboId, VertexData = OboTerm, EdgeData = Symbol,
              graph_data = OboInfo(id, name, description), weight_function = Returns(1),
              default_weight = 1)

Base.show(io::IO, ::MIME"text/plain", og::OboGraph) =
    print(io, "OboGraph{", og.graph_data.id, "}(", nv(og), " terms and ", ne(og), " edges)")

"""
    grow(g::OboGraph, vertices::Vector{Int}, dist::Number=Inf; dir::Symbol=:in)
    grow(g::OboGraph, vertices::Vector{<:OboId}, dist::Number=Inf; dir::Symbol=:in)
Grow a subgraph of `g` by obtaining the `neighborhod` (up to `dist` edges away,
in the direction `dir`) of each vertex of `vertices` (either an index, or an
`OboId`) and forming an induced subgraph.
"""
grow(g::OboGraph, inds::Vector{Int}, dist::Number=Inf; dir::Symbol=:in) =
    induced_subgraph(g, (neighborhood(g, i, dist; dir) for i in inds) |>
        Iterators.flatten |> unique) |> first

grow(g::OboGraph, ids::Vector{<:OboId}, dist::Number=Inf; dir::Symbol=:in) =
    grow(g, map(id -> first(g.vertex_properties[id]), ids), dist; dir)

grow(g::OboGraph, id::Union{<:OboId, Int}, dist::Number=Inf; dir::Symbol=:in) =
    grow(g, [id], dist; dir)
