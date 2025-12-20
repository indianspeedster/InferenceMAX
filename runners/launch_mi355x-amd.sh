#!/usr/bin/env bash

# === Workflow-defined Env Vars ===
# IMAGE
# MODEL
# TP
# HF_HUB_CACHE
# ISL
# OSL
# MAX_MODEL_LEN
# RANDOM_RANGE_RATIO
# CONC
# GITHUB_WORKSPACE
# RESULT_FILENAME
# HF_TOKEN
# FRAMEWORK

HF_HUB_CACHE_MOUNT="/nfsdata/hf_hub_cache-1/"  # Temp solution
PORT=8888

server_name="bmk-server"

# Determine framework suffix for benchmark script
FRAMEWORK_SUFFIX=$([[ "$FRAMEWORK" == "atom" ]] && printf '_atom' || printf '')

if [[ "$MODEL" == "amd/DeepSeek-R1-0528-MXFP4-Preview" || "$MODEL" == "deepseek-ai/DeepSeek-R1-0528" ]]; then
  if [[ "$OSL" == "8192" ]]; then
    export NUM_PROMPTS=$(( CONC * 20 ))
  else
    export NUM_PROMPTS=$(( CONC * 50 ))
  fi
else
  export NUM_PROMPTS=$(( CONC * 10 ))
fi

set -x
docker run --rm --ipc=host --shm-size=16g --network=host --name=$server_name \
--privileged --cap-add=CAP_SYS_ADMIN --device=/dev/kfd --device=/dev/dri --device=/dev/mem \
--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
-v $HF_HUB_CACHE_MOUNT:$HF_HUB_CACHE \
-v $GITHUB_WORKSPACE:/workspace/ -w /workspace/ \
-e HF_TOKEN -e HF_HUB_CACHE -e MODEL -e TP -e CONC -e MAX_MODEL_LEN -e PORT=$PORT -e NUM_PROMPTS \
-e ISL -e OSL -e PYTHONPYCACHEPREFIX=/tmp/pycache/ -e RANDOM_RANGE_RATIO -e RESULT_FILENAME  \
--entrypoint=/bin/bash \
$IMAGE \
benchmarks/"${EXP_NAME%%_*}_${PRECISION}_mi355x${FRAMEWORK_SUFFIX}_docker.sh"

if ls gpucore.* 1> /dev/null 2>&1; then
  echo "gpucore files exist. not good"
  rm -f gpucore.*
fi
