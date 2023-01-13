module BioOntologies

using DataToolkit
using Graphs
using MetaGraphsNext

if !isdefined(Base, :get_extension)
    using Requires
end

include("obograph.jl")
include("obofromjson.jl")

export OboGraph, OboTerm, OboId, grow

function __init__()
    DataToolkit.init(@__MODULE__, force=true)
    DataToolkit.@addpkgs JSON3

    @static if !isdefined(Base, :get_extension)
        @require Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a" begin
            @require GraphMakie = "1ecd5474-83a3-4783-bb4f-06765db800d2" include("../ext/PlotExt.jl")
        end
    end
end

end
