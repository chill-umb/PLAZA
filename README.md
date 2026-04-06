# PLAZA

This repository contains the experimental infrastructure for the paper "PLAZA: Proximity & Lifetime-Aware Zone Allocation for LSM Engines on ZNS SSDs".

## Setup

Follow the instructions at [ConfZNS++](https://github.com/stonet-research/confznsplusplus) to install ConfZNS++ and create a ZNS-enabled virtual machine.
Configure SSD and Zone size as needed for your experiment.
Inside the virtual machine:
- Use [zonedstorage.io](https://zonedstorage.io/docs/distributions/overview) as reference to install ZNS libraries for your VM's distro.
- Clone this repository into the VM's home directory.
- In scripts/zenfs_mkfs_clean.sh, replace all occurences of /home/afschy to /home/username , where username is the VM's current user.
- Run the following:
```bash
./fetch_all.sh
./recompile.sh
```
- In experiment.sh, replace all occurences of /home/afschy with /home/username

## Setting experiment parameters
Experiment parameters are defined in lines 7 to 24 of experiment.sh; modify the values to create an unique experiment.
- ssd_size_gb: Size of the SSD in GB, should be same as the actual size defined when running the ConfZNS++ VM.
- zone_size_mb: Size of each zone in MB, should be same as the actual size defined when running the ConfZNS++ VM.
- file_size_mb: The target size of each SST file.
- size_ratio: LSM parameter, the ratio betweeen the maximum size of level-i and level-i+1
- files_in_l0: How many files can reside in Level-0 of the LSM tree.
- level_count: How many levels the LSM tree will have.
- workload_dist: User-defined identifier for this specific experiment setup. Can be set to any alphanumeric string with hyphens.
- key_size_b: The size of each input key in bytes
- value_size_b: The size of each input value in bytes
- entry_count: How many key-value pairs to insert in this experiment
- workload_size_gb: The size of the workload in GB, Automatically computed
- compaction_pri: The compaction policy of the LSM tree. 3 is the default for RocksDB.
- gc_interval: After how many seconds the garbage collection thread is woken up.
- reserve_count: How many zones are kept in reserve for garbage collection. Those zones can't be used for storing new files.
- gc_start_level: The percentage of free space of the SSD, under which garbage collection becomes active.
- gc_stop_level: The percentage of the SSD's capacity that the garbage collector wants to make empty. Can be set to a number greater than gc_start_level to use our improved GC. Can also be set to "no" to use the default GC.
- gc_slope: The aggresiveness of the default GC. Can be set to any integer greater than 0 in order to use the default GC. Can also be set to "no" to use the improved GC.

Note that one of gc_stop_level and gc_slope has to be a number, and one of the has to be "no". Both of them can't be numbers, and both of them can't be "no".

Each experiment will run multiple times, once for each file placement policy. Currently, experimenting with 6 file placement policies are avaiable.

## Running experiments with db_bench
Run experiment.sh for a single experiment.
Run automate.sh for running with 5 different gc thresholds: 5, 10, 15, 20, 25, combined with 2 gc deltas: 2 and 10; for a total of 10 combinations.

```bash
sudo ./experiment.sh
```
or
```bash
sudo ./automate.sh
```

## Running experiments with tectonic
In experiment.sh,
- Comment out lines 71, 74-77
- Uncomment lines 72, 79-81

To run a tectonic workload:
- go into the lib/tectonic directory
- Compile tectonic
- Run tectonic and create a workload file
- Rename the file to workload.txt
- Move workload.txt to the repository's root directory

```bash
sudo ./experiment.sh
```
or
```bash
sudo ./automate.sh
```

## Results
A directory will be created inside /home/username which will contain all results. The directory's name will encode the first 13 experiment parameters. The directory will have one or more sub-directories, and their names will encode the last 4 experiment parameters. Each sub-directory will contain one sub-directory for each file placement policy in line-26. Those sub-directories will contain all log files generated for a single run of the experiment with that file placement policy.

Copy scripts/report_gen.sh into the first directory, and run. Some .csv files will be created. gc_movement.csv will contain the total movement caused by GC for all policies and all gc thresholds. time.csv will contain the runtime, and reset_count.csv will contain the reset count. report_gen.sh aggregates results for all sub-directories.

For example, if the created directory's name is:
```
s32_z128_fs32_r10_fl0-4_lc4_ws13_wd-random-row_ks16_vs4096_ec3500000_cp3_gcint10
```
It contains the following sub-directories:
```
rsvz-10_gcstart-10_gcstop-20_gcslp-no
rsvz-10_gcstart-15_gcstop-25_gcslp-no
rsvz-10_gcstart-20_gcstop-30_gcslp-no
```
To generate .csv report files:
```bash
cd ~/s32_z128_fs32_r10_fl0-4_lc4_ws13_wd-random-row_ks16_vs4096_ec3500000_cp3_gcint10
cp ~/PLAZA/scripts/report_gen.sh .
chmod +x report_gen.sh
./report_gen.sh
```