#!/bin/bash -l
set -eu
# JOB SH

echo $( basename $0 )
hostname

source /opt/modules/default/init/bash
module load modules
PATH=/opt/cray/elogin/eproxy/2.0.14-4.3/bin:$PATH # For aprun
module load alps

export MPICH_GNI_NDREG_ENTRIES=1024

module swap PrgEnv-intel PrgEnv-gnu
pdomain=flamestore
workspace=flamestore-ws
storagepath=/dev/shm
storagesize=1G

apstat -P | grep ${pdomain} || apmgr pdomain -c -u ${pdomain}

PROJECT_ROOT=/projects/radix-io/flamestore

source $PROJECT_ROOT/spack/share/spack/setup-env.sh
export MODULEPATH=$MODULEPATH:$PROJECT_ROOT/spack/share/spack/modules/cray-cnl6-mic_knl

# find nodes in job.  We have to do this so that we can manually specify 
# in each aprun so that server ranks consitently run on node where we
# set up storage space
declare -a nodes=($(python print_nids.py));

set -x
spack env activate flamestore
spack load -r flamestore

# ########################################################################
# MASTER SERVER
# ########################################################################

echo "Starting FlameStore's master"
aprun -cc none -n 1 -N 1 -p ${pdomain} -L ${nodes[0]} \
        flamestore run --master --debug --workspace=${workspace} > master.log 2>&1 &

echo "Waiting for FlameStore master to start up"
while [ ! -f ${workspace}/.flamestore/master.ssg.id ]; do sleep 10; done

# ########################################################################
# STORAGE SERVERS
# ########################################################################

echo "Formating storage space on workers"
aprun -cc none -n 1 -N 1 -L ${nodes[1]} \
        flamestore format --path=${storagepath} --size=${storagesize} --debug

echo "Start FlameStore workers"
aprun -cc none -n 1 -N 1 -p ${pdomain} -L ${nodes[1]} \
        flamestore run --storage=${storagepath}/flamestore.pmem --debug --workspace=${workspace} > workers.log 2>&1 &

echo "FlameStore has started, waiting 30sec before running client"
sleep 30


# ########################################################################
# CLIENT APPLICATION
# ########################################################################

aprun -cc none -n 1 -N 1 -p ${pdomain} $THIS/run-nt3-tf2-flamestore.sh

# ########################################################################
# SHUTDOWN 
# ########################################################################

echo "Shutting down FlameStore"
aprun -cc none -n 1 -N 1 -p ${pdomain} -L ${nodes[2]} \
        flamestore shutdown --workspace=${workspace} --debug

echo "Waiting for FlameStore to shut down"
apmgr pdomain -r -u ${pdomain}
