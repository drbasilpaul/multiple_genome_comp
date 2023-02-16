#!/bin/sh
##this script is to compare multiple mammalian genomes

set -o nounset -o errexit -o xtrace

########################################
# parameters
########################################
readonly CACTUS_IMAGE= cactus_v2.0.1.sif
readonly JOBSTORE_IMAGE=jobStore.img # cactus jobStore; will be created if it doesn't exist
readonly SEQFILE=mga.txt
readonly OUTPUTHAL=fourgenomes.hal
# extra options to Cactus
#readonly CACTUS_OPTIONS='--root mr' # NOTE: specific to evolverMammals.txt; change/remove for other input seqFile

########################################
# ... don't modify below here ...
########################################

readonly CACTUS_SCRATCH=/scratch/cactus-${SLURM_JOB_ID}

if [ ! -e "${JOBSTORE_IMAGE}" ]
then
  restart=''
  mkdir -p -m 777 ${CACTUS_SCRATCH}/upper ${CACTUS_SCRATCH}/work
  truncate -s 2T "${JOBSTORE_IMAGE}"
  singularity exec ${CACTUS_IMAGE} mkfs.ext3 -d ${CACTUS_SCRATCH} "${JOBSTORE_IMAGE}"
else
  restart='--restart'
fi

# Use empty /tmp directory in the container
mkdir -m 700 -p ${CACTUS_SCRATCH}/tmp

# the toil workDir must be on the same file system as the cactus jobStore
singularity exec --overlay ${JOBSTORE_IMAGE} ${CACTUS_IMAGE} mkdir -p /cactus/workDir
srun -n 1 /usr/bin/time -v singularity exec --cleanenv \
                           --overlay ${JOBSTORE_IMAGE} \
                           --bind ${CACTUS_SCRATCH}/tmp:/tmp \
                           --env PYTHONNOUSERSITE=1 \
                           ${CACTUS_IMAGE} \
  cactus ${CACTUS_OPTIONS-} ${restart-} --workDir=/cactus/workDir --binariesMode local /cactus/jobStore "${SEQFILE}" "${OUTPUTHAL}"

# /tmp would eventually be purged, but just in case the
# next job to run on this node needs lots of /space...

rm -rf ${CACTUS_SCRATCH} jobStore.img
