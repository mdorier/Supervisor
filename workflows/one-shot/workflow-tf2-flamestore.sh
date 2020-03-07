#!/bin/bash

# WORKFLOW SH

spack load -r stc

export THIS=$( readlink --canonicalize $( dirname $0 ) )

source $THIS/settings-flamestore.sh

PROJECT_ROOT=/projects/radix-io/flamestore
WORKSPACE=$PROJECT_ROOT/Supervisor/workflows/one-shot/flamestore-ws

export TURBINE_OUTPUT_ROOT=$THIS
export TURBINE_OUTPUT_FORMAT="out-%Q"
export TURBINE_JOBNAME=$JOB

export TURBINE_PRELAUNCH=<<ENDOFDIRECTIVE
export MPICH_GNI_NDREG_ENTRIES=1024
module swap PrgEnv-intel PrgEnv-gnu
source $PROJECT_ROOT/spack/share/spack/setup-env.sh
export MODULEPATH=$MODULEPATH:$PROJECT_ROOT/spack/share/spack/modules/cray-cnl6-mic_knl
spack env activate flamestore
spack load -r flamestore
ENDOFDIRECTIVE

export QUEUE PROJECT WALLTIME

let NODES=WORKERS+1

swift-t -m theta -n $NODES -e THIS $THIS/workflow-tf2-flamestore.swift --workspace=$WORKSPACE
