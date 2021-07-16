# set up a directory with GAP compiled against Julia and then "installed"
# for use by the `run_with_override.jl` script
@info "Install needed packages"
using Pkg
Pkg.develop(path=dirname(dirname(@__FILE__)))
Pkg.add(["GMP_jll", "GAP_lib_jll", "GAP_jll"])
Pkg.instantiate()
using GMP_jll


length(ARGS) >= 1 || error("must provide path of GAP source directory as first argument")
length(ARGS) >= 2 || error("must provide path of destination directory as second argument")
gap_prefix = popfirst!(ARGS)
prefix = popfirst!(ARGS)

# TODO: we duplicate some code from GAP.jl's src/setup.jl ; perhaps we could
# just include that file here?

include("../src/setup.jl")


gmp_prefix = Setup.gmp_artifact_dir()
juliabin = joinpath(Sys.BINDIR, Base.julia_exename())

# TODO: should the user be allowed to provide a tmp_gap_build_dir ? that might
# be handy for incremental updates
# TODO: refuse to run when tmp_gap_build_dir exists / prompt user whether to delete
# it (but do NOT automatically delete it, in case user pointed it at a bad place)
tmp_gap_build_dir = mktempdir(; cleanup = true)
cd(tmp_gap_build_dir)

@info "Configuring GAP in $(tmp_gap_build_dir) for $(prefix)"
@show run(`$(gap_prefix)/configure
    --prefix=$(prefix)
    --with-gmp=$(gmp_prefix)
    --with-gc=julia
    --with-julia=$(juliabin)
    `)

@info "Building GAP in $(tmp_gap_build_dir)"

# first build the version of GAP without gac generated code
run(`make -j$(Sys.CPU_THREADS) build/gap-nocomp`)

# cheating: the following assumes that GAP in gap_prefix was already compiled...
# we copy some generated files, so that we don't have to re-generate them,
# which involves launching GAP, which requires libgmp from GMP_jll, which requires
# fiddling with DYLD_FALLBACK_LIBRARY_PATH / LD_LIBRARY_PATH ....
for f in ["c_oper1.c", "c_type1.c"]
    cp(joinpath(gap_prefix, "build", f), joinpath("build", f))
end

# complete the build
run(`make -j$(Sys.CPU_THREADS)`)


@info "Installing GAP to $(prefix)"

# install GAP binaries, headers, libraries
run(`make install-bin install-headers install-libgap`)

# manually copy config.h for now
cp("build/config.h", joinpath(prefix, "include", "gap", "config.h"))

# get rid of *.la files, they just cause trouble
#rm $(prefix)/lib/*.la

# get rid of the wrapper shell script, which is useless for us
#mv("$(prefix)/bin/gap.real", "$(prefix)/bin/gap"; force=true)

# install gac and sysinfo.gap
mkpath(joinpath(prefix, "share", "gap"))
for f in ["gac", "sysinfo.gap"]
    cp(f, joinpath(prefix, "share", "gap", f))
end

# We deliberately do NOT install the GAP library, documentation, etc. because
# they are identical across all platforms; instead, we use another platform
# independent artifact to ship them to the user.
