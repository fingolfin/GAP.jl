# Replacement for the GAP kernel function ExecuteProcess
const use_orig_ExecuteProcess = Ref{Bool}(false)
function GAP_Error(args...)
    gapargs = [Obj(x) for x in args]
    GAP.Globals.Error(gapargs...)
end

function GAP_ExecuteProcess(dir::Any, prg::Any, in::Any, out::Any, args::Any)
    (dir isa GapObj && Wrappers.IsString(dir)) || GAP_Error("ExecuteProcess: <dir> must be a string (not the value '", dir, "')")
    (prg isa GapObj && Wrappers.IsString(prg)) || GAP_Error("ExecuteProcess: <prg> must be a string (not the value '", prg, "')")
    in isa Int || GAP_Error("ExecuteProcess: <in> must be a small integer (not the value '", in, "')")
    out isa Int || GAP_Error("ExecuteProcess: <out> must be a small integer (not the value '", out, "')")
    (args isa GapObj && Wrappers.IsList(args)) || GAP_Error("ExecuteProcess: <args> must be a small list (not the value '", args, "')")
    all(Wrappers.IsString, args) || GAP_Error("ExecuteProcess: <args> must be a list of strings")

    # convert Julia errors to GAP errors
    # TODO: we should probably do this in general
    try
        if use_orig_ExecuteProcess[]
            return GAP.Globals._ORIG_ExecuteProcess(dir, prg, in, out, args)
        end
        return GAP_ExecuteProcess(String(dir), String(prg), in::Int, out::Int, Vector{String}(args))
    catch
        GAP_Error("a julia exception was raised")
    end
end

function GAP_ExecuteProcess(dir::String, prg::String, fin::Int, fout::Int, args::Vector{String})
    # Note: the GAP kernel function `ExecuteProcess` also handles so-called
    # "window mode", for use in xgap and Gap.app -- we do not emulate this here.
    if fin < 0
        fin = Base.devnull
    else
        fin = ccall((:SyBufFileno, libgap), Int, (Culong, ), fin)
        if fin == -1
            error("fin invalid")
        end
        fin = RawFD(fin)
    end

    if fout < 0
        fout = Base.devnull
    else
        fout = ccall((:SyBufFileno, libgap), Int, (Culong, ), fout)
        if fout == -1
            error("fout invalid")
        end
        fout = RawFD(fout)
    end

# TODO: this hangs
#    ExecuteProcess("","",0,0,[]);

    # TODO: verify `dir` is a valid dir?
    cd(dir) do
        res = run(pipeline(ignorestatus(`$prg $args`), stdin=fin, stdout=fout))
        return res.exitcode == 255 ? GAP.Globals.Fail : res.exitcode
    end
end
