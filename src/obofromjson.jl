function obofromjson(jsonsource::IO; id::String="", name::String="", description::String="")
    DataToolkit.@use JSON3
    data = JSON3.read(jsonsource)
    de_url(hp_url::String) = replace(hp_url, r"^.*/([A-Za-z]+)_" => s"\1:")
    graph = OboGraph(Symbol(id), name, description)
    function terminfo(term) # term::JSON3.Object
        id = parse(OboId, de_url(term[:id]))
        if !isnothing(id)
            label = get(term, :lbl, nothing)
            OboTerm(id, label, get(term, :meta, Dict{Symbol, Any}()) |> copy)
        else
            missing
        end
    end
    terms = filter(t -> haskey(t, :type), data[:graphs][1][:nodes]) |>
        ts -> filter(t -> t.type == "CLASS", ts) .|>
        terminfo |> skipmissing |> collect
    for term in terms
        add_vertex!(graph, term.id, term)
    end
    for edge in data[:graphs][1][:edges]
        from, to = parse(OboId, edge[:obj]), parse(OboId, edge[:sub])
        if haskey(graph.vertex_properties, from) && haskey(graph.vertex_properties, to)
            add_edge!(graph, from, to, Symbol(edge[:pred]))
        else
            @warn "Could not apply edge $edge"
        end
    end
    graph
end
