#! /usr/bin/env bash

# GasMD script from https://github.com/andymlau/gasMD
# Written by Andy M Lau 2021

set -eu

if [ $# -ne 4 ]; then
  echo "$0: Usage: ./run_pdb2gmx_autoCharge.sh <input.pdb; path> <n_charges; int> <n_samples; int> <out_dir; path>"
fi

progdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
scripts="${progdir}/scripts"
chargeroulette="${scripts}/charge_roulette.py"
autoassign="${scripts}/__auto_assign.exp"
py="$(which python)"

input=$(readlink -f $1)
ncharges=$2
nsamples=$3
output=$(readlink -f $4)

# Some checks
if test ! -f $input; then
  echo "Input file ${input} does not exist. Please check path. "
  exit 0
else
  if test ! -s $input; then
    echo "Input file ${input} is empty. Please check input."
    exit 0
  fi
fi

if test ! -d $output; then
  mkdir -p $output
  echo "Output files will be saved to ${output}"
else
  echo "Found output files at ${output}. Stopping."
  # exit 0
fi

# Run charge roulette
echo -e "\nRunning charge_roulette.py"
echo "  - Will sample $ncharges charges from $(basename $input) $nsamples times."

$py $chargeroulette -i $input -n $ncharges -s $nsamples -o $output

charges="$output/$(basename ${input%.pdb})_samples.txt"
if test -f $charges; then
  echo "  - The following charges will be assigned: (sample_no,LYS,ARG,HIS):"
  sed 's/^/    /' $charges
else
  echo "Error: charge_roulette.py output not found."
  exit 0
fi

# Iterate over each charge set
while read -r line; do
  no=$(cut -d"," -f1 <<< $line)
  lys=$(cut -d"," -f2 <<< $line)
  arg=$(cut -d"," -f3 <<< $line)
  his=$(cut -d"," -f4 <<< $line)
  jobdir="${output}/sample_${no}"

  # For each charge set, generate the pdb2gmx run script to direct the output files
  # and the expect script inside a new folder

  if test ! -d $jobdir; then
    mkdir -p $jobdir
  fi

  # Generate runscript
  runscript=$(readlink -f "${jobdir}/run_pdb2gmx.sh")
  echo "source /usr/local/gromacs/bin/GMXRC" > $runscript
  echo "gmx pdb2gmx -f ${input} -o ${jobdir}/charge_set_${no}_out.pdb -v -heavyh -ff oplsaa -p ${jobdir}/topol.top -i ${jobdir}/posre.itp -water none -lys -arg -asp -glu -his -ter -renum -merge all" >> $runscript

  # Generate expect script
  runexpect=$(readlink -f "${jobdir}/auto_assign.exp")
  sed -e "s/__LYS__/$lys/g;s/__ARG__/$arg/g;s/__HIS__/$his/g;s:__RUNSCRIPT__:$runscript:g" $autoassign > $runexpect

  # Check both runfiles exist, then run expect
  if test -f $runscript && test -f $runexpect; then
    log=$(readlink -f "${jobdir}/pdb2gmx.log")
    expect $runexpect > $log

    echo -e "\n  Charge set ${no}: "
    echo "  - Files in directory: ${jobdir}"
    echo "  - $(grep 'Total charge' $log)"
  fi

done < $charges
