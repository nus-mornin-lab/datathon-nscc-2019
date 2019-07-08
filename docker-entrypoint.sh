#!/bin/sh

. ${CONDA_PREFIX}/etc/profile.d/conda.sh
conda activate base

exec "$@"
