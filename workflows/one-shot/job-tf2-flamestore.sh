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

pdomain=flamestore
workspace=flamestore-ws
storagepath=/dev/shm
storagesize=1G

apstat -P | grep ${pdomain} || apmgr pdomain -c -u ${pdomain}

PROJECT_ROOT=/projects/radix-io/flamestore
source $PROJECT_ROOT/setup.sh
setup_flamestore_environment
#export MODULEPATH=$MODULEPATH:$PROJECT_ROOT/spack/share/spack/modules/cray-cnl6-mic_knl

set -x

# ########################################################################
# MASTER SERVER
# ########################################################################

echo "Starting FlameStore's master"
aprun -cc none -n 1 -N 1 -p ${pdomain} \
        flamestore run --master --debug --workspace=${workspace} > master.log 2>&1 &

echo "Waiting for FlameStore master to start up"
while [ ! -f ${workspace}/.flamestore/master.ssg.id ]; do sleep 10; done

# ########################################################################
# STORAGE SERVERS
# ########################################################################

echo "Start FlameStore workers"
aprun -cc none -n 1 -N 1 -p ${pdomain} \
        flamestore run --storage --format \
	               --path=${storagepath} --size=${storagesize} \
	               --debug --workspace=${workspace} > workers.log 2>&1 &

echo "FlameStore has started, waiting 30sec before running client"
sleep 30


# ########################################################################
# CLIENT APPLICATION
# ########################################################################

echo "Starting a client"

aprun -cc none -n 1 -N 1 -p ${pdomain} $THIS/run-nt3-tf2-flamestore.sh 0

echo "Restarting a client"

aprun -cc none -n 1 -N 1 -p ${pdomain} $THIS/run-nt3-tf2-flamestore.sh 1

# ########################################################################
# SHUTDOWN 
# ########################################################################

echo "Shutting down FlameStore"
aprun -cc none -n 1 -N 1 -p ${pdomain} \
        flamestore shutdown --workspace=${workspace} --debug

echo "Waiting for FlameStore to shut down"
apmgr pdomain -r -u ${pdomain}
