module PlotExt

@info "Loading PlotExt"

using BioOntologies

using Graphs, MetaGraphsNext

if isdefined(Base, :get_extension)
    using GraphMakie, ..Makie
else
    using ..GraphMakie, ..Makie
end

const Colorant = Makie.Colors.Colorant

export growplot, growplot!

function obographplot!(ax::Union{Axis, Axis3}, graph::OboGraph, args...;
                       showid::Bool=true, showlabel::Bool=true,
                       basecolors::Vector{<:Union{<:Colorant, Symbol}}=[:black],
                       ncolors::Vector{<:Union{<:Colorant, Symbol}}=
                           Iterators.take(Iterators.flatten(Iterators.repeated(
                               basecolors)), nv(graph)) |> collect,
                       nlabels_distance=8.0,
                       node_size = fill(14.0, nv(graph)),
                       edge_width = fill(2.0, ne(graph)),
                       node_color=ncolors, nlabels_color=ncolors,
                       kwargs...)
    hidedecorations!(ax)
    hidespines!(ax)
    nlabels = fill("", nv(graph))
    for (id, (idx, term)) in graph.vertex_properties
        nlabels[idx] = string(
            if showid string(id) else "" end,
            if showid && showlabel "\n" else "" end,
            if showlabel something(term.label, "-") else "" end)
    end
    p = graphplot!(ax, graph.graph; nlabels, nlabels_distance, node_size,
                   edge_width, node_color, nlabels_color, kwargs...)
    deregister_interaction!(ax, :rectanglezoom)
    register_interaction!(ax, :nodehover, NodeHoverHighlight(p))
    # register_interaction!(ax, :edgehover, EdgeHoverHighlight(p))
    register_interaction!(ax, :edrag, EdgeDrag(p))
    register_interaction!(ax, :ndrag, NodeDrag(p))
    p
end

GraphMakie.graphplot!(ax::Axis, graph::OboGraph, args...; kwargs...) =
    obographplot!(ax, graph, args...; kwargs...)

function GraphMakie.graphplot(graph::OboGraph, args...; kwargs...)
    fig = Figure()
    ax = Axis(fig[1,1])
    p = graphplot!(ax, graph, args...; kwargs...)
    Makie.FigureAxisPlot(fig, ax, p)
end

function growplot!(ax::Union{Axis, Axis3}, g::OboGraph, ids::Vector{<:Union{<:OboId, Int}},
                   dist::Number=Inf; dir::Symbol=:in,
                   color::Union{Symbol, <:Colorant, <:Vector}=:teal,
                   bcolor::Union{Symbol, <:Colorant}=:grey,
                   kwargs...)
    oids = if eltype(ids) <: OboId
        ids
    else OboId.(g.graph_data.id, ids) end
    vcolors = if color isa Vector
        @assert length(color) >= length(ids)
        color
    else fill(color, length(ids)) end
    subgraph = grow(g, ids, dist; dir)
    ncolors = Vector{Union{Symbol, Colorant}}(fill(bcolor, nv(subgraph)))
    coloridx = 0
    for (v, id) in sort(collect(subgraph.vertex_labels), by=last)
        if id in oids
            ncolors[v] = vcolors[(coloridx+=1)]
        end
    end
    graphplot!(ax, subgraph; ncolors, kwargs...)
end

function growplot(args...; kwargs...)
    fig = Figure()
    ax = Axis(fig[1,1])
    p = growplot!(ax, args...; kwargs...)
    Makie.FigureAxisPlot(fig, ax, p)
end

end
