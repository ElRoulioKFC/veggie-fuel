# Running VeggieFuel on the MUST Cluster

This guide walks you through running VeggieFuel on the [MUST data centre](https://doc.must-datacentre.fr/) — the HTCondor-based HPC cluster at Université Savoie Mont Blanc / CNRS/IN2P3 in Annecy.

If you've never used a computing cluster before, don't worry. This guide is written for you.

---

## What's in this folder

| File | What it does |
|------|-------------|
| `setup_r.sh` | One-time setup: installs R packages on shared storage |
| `run_single.sh` | Runs the meal planner + amino check (single job) |
| `run_single.sub` | HTCondor submit file for a single job |
| `run_simulation.R` | Monte Carlo: randomly samples foods, checks amino coverage |
| `run_batch.sh` | Wrapper for one simulation (called by HTCondor) |
| `run_batch.sub` | HTCondor submit file for 50 parallel simulations |
| `collect_results.R` | Combines all simulation results into one summary |
| `collect_results.sh` | Wrapper for collect step (called by HTCondor/DAGMan) |
| `collect_results.sub` | HTCondor submit file for the collection step |
| `dag_workflow.dag` | DAGMan workflow: run 50 sims → collect results |
| `logs/` | HTCondor output/error/log files land here |

---

## Step 1: Connect to a UI server

You need SSH access to one of the MUST "UI" (User Interface) servers. These are the machines where you prepare and submit jobs.

```bash
# LAPP users:
ssh your_username@lappui7.in2p3.fr
# or
ssh your_username@lappui9.in2p3.fr

# USMB users:
ssh your_username@lappusmb7.in2p3.fr
```

You'll land in your home directory (something like `/home1/your_username/` or `/home3/your_username/`).

> See: [MUST documentation — Getting Started](https://doc.must-datacentre.fr/getting_started/)

---

## Step 2: Clone the repo to shared storage

Your home directory is on a NAS with limited space — it's not the right place for project data. Instead, use the shared Ceph/MUSTFS storage that's accessible from all worker nodes:

- **LAPP users**: `/lapp_data/YOUR_GROUP/`
- **USMB users**: `/uds_data/YOUR_LAB/`

```bash
# LAPP example:
cd /lapp_data/YOUR_GROUP/
git clone https://github.com/YOUR_USER/veggie-fuel.git
cd veggie-fuel

# USMB example:
cd /uds_data/YOUR_LAB/
git clone https://github.com/YOUR_USER/veggie-fuel.git
cd veggie-fuel
```

Replace `YOUR_GROUP` / `YOUR_LAB` with your actual group or lab name (ask your supervisor if you're not sure).

> Why shared storage? Because when HTCondor runs your job on a worker node, that node needs to read your files. The `/lapp_data/` and `/uds_data/` directories are mounted on all nodes. Your home directory might not be.

---

## Step 3: Check if R is available

```bash
which R
R --version
```

**If R is found**, great — skip to step 4.

**If R is NOT found**, you have two options:

### Option A: CVMFS (recommended — available on all MUST nodes)

CVMFS provides pre-built software that's available cluster-wide:

```bash
source /cvmfs/sft.cern.ch/lcg/views/LCG_105/x86_64-el9-gcc12-opt/setup.sh
which R     # should now work
R --version
```

Add this line to your `~/.bashrc` so it's loaded automatically:

```bash
echo 'source /cvmfs/sft.cern.ch/lcg/views/LCG_105/x86_64-el9-gcc12-opt/setup.sh' >> ~/.bashrc
```

### Option B: Conda

If you have conda/mamba installed:

```bash
conda create -n veggiefuel r-base r-essentials -c conda-forge
conda activate veggiefuel
```

> See: [MUST documentation — Software](https://doc.must-datacentre.fr/software/)

---

## Step 4: Install R packages

Run the setup script once. It will:
- Create an R library directory on shared storage
- Set `R_LIBS_USER` in your `~/.bashrc`
- Install all required packages (dplyr, readr, tidyr, ggplot2, scales, here, lpSolve)

```bash
bash must/setup_r.sh
```

The script will ask for your group/lab name. After it finishes, reload your shell:

```bash
source ~/.bashrc
```

---

## Step 5: Test locally (quick sanity check)

Before submitting to HTCondor, make sure everything works on the UI server:

```bash
# Run the tests
Rscript tests/test_amino.R
Rscript tests/test_weekly.R

# Try a quick simulation
Rscript must/run_simulation.R 42
cat output/sim_42.csv
```

If the tests pass and `sim_42.csv` has data, you're ready to submit jobs.

---

## Step 6: Submit a single job

First, edit `must/run_single.sub` — you need to set two things:

1. **`initialdir`** — change it to your project path:
   ```
   initialdir = /lapp_data/YOUR_GROUP/veggie-fuel
   ```

2. **Accounting group** — uncomment and edit one line:
   ```
   +wishedAcctGroup = "group_lapp.YOUR_GROUP"
   ```

Then submit:

```bash
condor_submit must/run_single.sub
```

You'll see something like:
```
Submitting job(s).
1 job(s) submitted to cluster 12345.
```

To override the athlete weight (e.g., 55 kg):

```bash
export VEGGIEFUEL_WEIGHT=55
condor_submit must/run_single.sub
```

---

## Step 7: Submit 50 simulation jobs

Same idea — edit `must/run_batch.sub` to set `initialdir` and your accounting group, then:

```bash
condor_submit must/run_batch.sub
```

This submits 50 independent jobs. Each one randomly samples foods into 6 meals with random portions and checks amino acid coverage. Each job takes just a few seconds.

---

## Step 8: Monitor your jobs

```bash
# See your running/queued jobs
condor_q

# More detail
condor_q -long

# See all cluster activity
condor_status

# Watch a specific job's output in real-time
tail -f must/logs/sim_0.out

# Check the batch log
cat must/logs/batch.log
```

**Job states you'll see:**

| State | Meaning |
|-------|---------|
| `I` (Idle) | Waiting for a worker node |
| `R` (Running) | Currently executing |
| `H` (Held) | Something went wrong — check the error log |
| `C` (Completed) | Finished |

> See: [MUST documentation — Batch Jobs](https://doc.must-datacentre.fr/batch/basic/)

---

## Step 9: Use DAGMan for the full workflow

Instead of manually submitting the batch and then the collection, DAGMan can chain them automatically:

```bash
condor_submit_dag must/dag_workflow.dag
```

This will:
1. Run all 50 simulations in parallel
2. Wait for them all to finish
3. Automatically run `collect_results.R` to combine the results

Monitor with:

```bash
condor_q                                    # see jobs
cat must/dag_workflow.dag.dagman.out        # DAGMan progress
```

> See: [MUST documentation — DAGMan](https://doc.must-datacentre.fr/batch/dagman/)

---

## Step 10: Retrieve results

After the jobs finish, your results are in:

```bash
# Single job output
cat output/trail_day_plan.csv
cat output/kayak_day_plan.csv
cat output/rest_day_plan.csv

# Simulation results
cat output/all_simulations.csv

# Or view the top 10 simulations
Rscript must/collect_results.R
```

To copy results to your laptop:

```bash
# From your laptop (not the cluster):
scp your_username@lappui7.in2p3.fr:/lapp_data/YOUR_GROUP/veggie-fuel/output/all_simulations.csv .
```

---

## Common errors and fixes

### "R: command not found"

R isn't in your PATH. Load it via CVMFS:
```bash
source /cvmfs/sft.cern.ch/lcg/views/LCG_105/x86_64-el9-gcc12-opt/setup.sh
```

### "there is no package called 'dplyr'" (on worker node)

Your `R_LIBS_USER` isn't reaching the worker. Check:
1. Is `getenv = True` in your submit file? (It should be.)
2. Is `R_LIBS_USER` exported in your `~/.bashrc`?
3. Did you run `bash must/setup_r.sh`?

### Job is "Held" (H state)

```bash
condor_q -held        # see why
condor_release <job_id>  # release it to retry
```

Common reasons: executable not found, permission denied (forgot `chmod +x`), or memory exceeded.

### "Permission denied" on shell scripts

Make them executable:
```bash
chmod +x must/*.sh
```

### "No such file or directory" for data/foods.csv

Your `initialdir` in the submit file doesn't point to the project root. Fix it:
```
initialdir = /lapp_data/YOUR_GROUP/veggie-fuel
```

### Job killed (exceeded memory)

The default memory request is 2 GB. VeggieFuel is lightweight, so this shouldn't happen. If it does, increase it:
```
request_memory = 4096
```

Note: MUST kills jobs that use more than 1.5x their requested memory.

### Jobs sitting idle for a long time

Check cluster load:
```bash
condor_status -total
```

If the cluster is busy, your jobs will wait. Flash queue jobs (`+isFlash = True`) get priority for short runs.

### DAGMan errors

Check the DAGMan log:
```bash
cat must/dag_workflow.dag.dagman.out
```

If a parent job failed, DAGMan won't run the child. Fix the parent job and resubmit the DAG — DAGMan uses a rescue file to skip already-completed jobs.

---

## Need help?

- **MUST documentation**: https://doc.must-datacentre.fr/
- **MUST support**: support-must@lapp.in2p3.fr
- **Grafana monitoring**: https://app.must-datacentre.fr/grafana/
