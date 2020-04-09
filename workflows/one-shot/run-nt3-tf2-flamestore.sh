#!/bin/bash -l
# Need -l to reset modules ...
set -eu

# RUN NT3

PROJECT_ROOT=/projects/radix-io/flamestore

echo $( basename $0 )
hostname

# Modules start
module unload cray-python/3.6.5.3
module load   datascience/tensorflow-2.0
# Modules end

which python
export MPICH_GNI_NDREG_ENTRIES=1024

source $PROJECT_ROOT/setup.sh
setup_flamestore_environment
#export MODULEPATH=$MODULEPATH:$PROJECT_ROOT/spack/share/spack/modules/cray-cnl6-mic_knl
# Report original source directory
echo THIS=$THIS

BENCHMARKS=$( readlink --canonicalize $THIS/../../../Benchmarks )
NT3=$BENCHMARKS/Pilot1/NT3/nt3_baseline_keras2.py

set -x
python $NT3 --epochs 1 --restart ${1:-0}
