#!/bin/bash
OUT_BASE="/volatile/eic/romanov/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1"
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