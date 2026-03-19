#!/bin/bash
# Submit snakemake workflow to JLab SLURM farm.
# Usage: ./run_jlab_slurm.sh <output_path>
# Example: ./run_jlab_slurm.sh /volatile/eic/$USER/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <output_path>"
    echo "Example: $0 /volatile/eic/\$USER/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1"
    exit 1
fi

export OUT_BASE="$1"
LOGS="${OUT_BASE}/logs"
mkdir -p "$LOGS"

uv run snakemake \
  --executor cluster-generic --jobs 2000 \
  --cluster-generic-submit-cmd "sbatch \
    --account=eic \
    --partition=production \
    --cpus-per-task={threads} \
    --mem=4000 \
    --time=01:00:00 \
    --output=${LOGS}/slurm-%j.out \
    --error=${LOGS}/slurm-%j.err" \
  --use-singularity \
  --singularity-args "--bind /volatile:/volatile --bind /cvmfs:/cvmfs"
