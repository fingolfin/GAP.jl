#!/bin/sh
set -ex

JULIA=julia
#JULIA="julia +1.6"
#JULIA=$HOME/Projekte/Julia/julia.release-1.8/julia
#JULIA=$HOME/Projekte/Julia/julia.release-1.10/julia
#JULIA=$HOME/Projekte/Julia/julia.master/julia

export GAPROOT=$HOME/Projekte/GAP/gap
#export GAPROOT=$HOME/Projekte/GAP/gap.spielwiese
DSTDIR=/tmp/gap_jll_override

rm -rf $DSTDIR override

$JULIA --proj=override etc/setup_override_dir.jl $GAPROOT $DSTDIR --debug
$JULIA --proj=override etc/run_with_override.jl $DSTDIR -e 'using GAP' -i
