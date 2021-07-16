using GAP_jll

length(ARGS) >= 1 || error("must provide path of GAP override directory as first argument")
gapoverride = popfirst!(ARGS)


function add_jll_override(depot, pkgname, newdir)
    uuid = string(Base.identify_package("$(pkgname)_jll").uuid)
    mkpath(joinpath(depot, "artifacts"))
    open(joinpath(depot, "artifacts", "Overrides.toml"), "a") do f
        write(f, """
        [$(uuid)]
        $(pkgname) = "$(newdir)"
        """)
    end
end

tmpdepot = mktempdir(; cleanup=true)
@info "Created temporary depot at $(tmpdepot)"

# create override file for GAP_jll
add_jll_override(tmpdepot, "GAP", gapoverride)

# prepend our temporary depot to the depot list...
withenv("JULIA_DEPOT_PATH"=>tmpdepot*":") do
    # we need to make sure that precompilation is run again with the override in place
    # (just running Pkg.precompile() does not seem to suffice)
    run(`touch $(pathof(GAP_jll))`)

    # ... and start Julia, by default with the same project environment
    run(`$(Base.julia_cmd()) --project=$(Base.active_project()) $(ARGS)`)
end
