#! /usr/bin/env bash

# ChargeRoulette script from https://github.com/andymlau/ChargeRoulette
# Written by Andy M Lau, PhD (2021)

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

# source /usr/local/gromacs/bin/GMXRC
gromacs="gmx pdb2gmx"
fflags="-v -heavyh -ff oplsaa -water none -lys -arg -asp -glu -his -ter -renum -merge all"

# Check that gromacs command is found
if ! command -v $gromacs &> /dev/null
then
    echo "GROMACS (gmx pdb2gmx) was not found. Did you forget to source GMXRC?"
    exit 0
fi

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
  echo "${gromacs} -f ${input} -o ${jobdir}/out.pdb -p ${jobdir}/topol.top -i ${jobdir}/posre.itp ${fflags}" >> $runscript

  # Generate expect script
  runexpect=$(readlink -f "${jobdir}/auto_assign.exp")

  sed -e "s/__LYS__/$lys/g;s/__ARG__/$arg/g;s/__HIS__/$his/g;s:__RUNSCRIPT__:$runscript:g" $autoassign > $runexpect

  # Check both runfiles exist, then run expect
  if test -f $runscript && test -f $runexpect; then
    log=$(readlink -f "${jobdir}/pdb2gmx.log")
    expect $runexpect > $log

    echo -e "\n  Charge set ${no}: "
    echo "  - Files in directory: ${jobdir}"

    # Check for fatal errors:
    if grep -q "Fatal error" $log; then
      sed -ne '/Fatal error/,$ p' $log | sed "s/^/    /g"
      echo -e "\n"
      exit 0
    else
      if grep -q "Total charge" $log; then
        echo "  - Charges assigned to residues: "
        echo "    Lysines: $(echo ${lys} | sed 's/{//g; s/}//g; s/ /, /g')"
        echo "    Arginines: $(echo ${arg} | sed 's/{//g; s/}//g; s/ /, /g')"
        echo "    Histidines: $(echo ${his} | sed 's/{//g; s/}//g; s/ /, /g')"
        echo -e "\n  - $(grep 'Total charge' $log)"
      fi
    fi
  fi

done < $charges
