#!/bin/bash

singularity run \
	-B $PWD/ref:/app/ref:ro -B $PWD/results:/results:ro \
	singularity_cache/aryashta-twb-v0.8.4.img twb serve \
	--csv-dir /results/twb/filtered --bam-dir /results/alignments \
	--port 8001
