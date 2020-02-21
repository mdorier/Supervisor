#!/bin/bash

# WORKFLOW SH

spack load -r stc

export THIS=$( readlink --canonicalize $( dirname $0 ) )

source $THIS/settings.sh

export TURBINE_OUTPUT_ROOT=$THIS
export TURBINE_OUTPUT_FORMAT="out-%Q"
export TURBINE_JOBNAME=$JOB

export QUEUE PROJECT WALLTIME

let NODES=WORKERS+1

swift-t -m theta -n $NODES -e THIS $THIS/workflow.swift
