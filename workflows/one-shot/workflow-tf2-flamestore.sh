#!/bin/bash

# WORKFLOW SH

export THIS=$( readlink --canonicalize $( dirname $0 ) )

source $THIS/settings-flamestore.sh

PROJECT_ROOT=/projects/radix-io/flamestore
WORKSPACE=$PROJECT_ROOT/Supervisor/workflows/one-shot/flamestore-ws

source $PROJECT_ROOT/setup.sh
setup_flamestore_environment
#export MODULEPATH=$MODULEPATH:$PROJECT_ROOT/spack/share/spack/modules/cray-cnl6-mic_knl
spack load -r stc

FLAMESTORE_INCLUDE=`spack location -i flamestore`/include

export PROJECT_ROOT
export TURBINE_OUTPUT_ROOT=$THIS
export TURBINE_OUTPUT_FORMAT="out-%Q"
export TURBINE_JOBNAME=$JOB

TURBINE_PRELAUNCH="
export MPICH_GNI_NDREG_ENTRIES=1024
source $PROJECT_ROOT/setup.sh
setup_flamestore_environment
"

export QUEUE PROJECT WALLTIME TURBINE_PRELAUNCH

let NODES=WORKERS+1

swift-t -m theta -n $NODES -e THIS -e TURBINE_PRELAUNCH -I $FLAMESTORE_INCLUDE \
		$THIS/workflow-tf2-flamestore.swift --workspace=$WORKSPACE
