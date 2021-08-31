#! /usr/bin/env bash

# ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations
# Downloaded from: https://github.com/andymlau/ChargeRoulette
# Author: Andy M. Lau, PhD (2021) (andy.m.lau@ucl.ac.uk)
# See LICENSE file for more details.

set -eu

progdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
scripts="${progdir}/scripts"
chargeroulette="${scripts}/charge_roulette.py"
autoassign="${scripts}/__auto_assign.exp"
py="$(which python)"

# source /usr/local/gromacs/bin/GMXRC
gromacs="gmx pdb2gmx"
fflags="-v -heavyh -ff oplsaa -water none -lys -arg -asp -glu -his -ter -renum -merge all"

# By default, use arg, his and lys residues
arginine=1
histidine=1
lysine=1

if [[ $# -eq 0 ]] ; then
    echo "$0: No arguments given. Run ./run_charge_roulette.sh -h for more help. Exiting."
    echo " "
    exit 1
fi

title () {
  echo " "
  echo "-----------------------------------------------------------------------"
  echo "ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations"
  echo "-----------------------------------------------------------------------"
  echo " "
  echo "Downloaded from: https://github.com/andymlau/ChargeRoulette"
  echo "Author: Andy M. Lau, PhD (2021) (andy.m.lau@ucl.ac.uk)"
  echo " "
}

usage () {
  echo "Usage: ./$0 [-i <string; path] [-o <string; path>] [-n <int>] [-s <int>]"
}

# Input option handling
while getopts ':i:o:n:s:c:hRHK' opt; do
  case "$opt" in
    h)
    title
    usage
    echo " "
    echo "-h, --help       Show this help menu."
    echo " "
    echo "Mandatory arguments:"
    echo "-i, --input      (path) input pdb file to run ChargeRoulette on. Should be the (residuedepth) output of DEPTH server."
    echo "-o, --output     (path) specify the output directory for files to be written to."
    echo "-n, --ncharges   (int) specify the number of positive charges that each run should generate. e.g. 7 for a the output pdb to have a +7 charge."
    echo "-s, --nsamples   (int) specify the number of alternative charge configurations. e.g. 5 will generate 5 different output pdbs."
    echo " "
    echo "Optional arguments:"
    echo "-c, --custom     (path) use a custom assignment schedule. If option used, -n and -s are no longer mandatory."
    echo "-R, --arg        Do not include arginines."
    echo "-H, --his        Do not include histidines."
    echo "-K, --lys        Do not include lysines."
    echo " "
    exit 1 ;;

    i) input=$(readlink -f $OPTARG) ;;
    o) output=$(readlink -f $OPTARG) ;;
    n) ncharges=$OPTARG ;;
    s) nsamples=$OPTARG ;;
    c) custom=$(readlink -f $OPTARG) ;;
    R) arginine=0 ;;
    H) histidine=0 ;;
    K) lysine=0 ;;
    :) echo -e "Error: -$OPTARG requires an argument. See help (./$0 -h) for more details.\n"; usage; exit 1 ;;
    # \?) echo "Unrecognised option '$*'"; exit 1;;
    *) echo -e "Error: Unrecognised option '$*'. See help (./$0 -h) for more details.\n"; usage; exit 1 ;;
  esac
done

# Check that gromacs command is found
if ! command -v $gromacs &> /dev/null
then
    echo "GROMACS (gmx pdb2gmx) was not found. Did you forget to install or source GMXRC?"
    exit 1
fi

# Check that expect is found
if ! command -v expect &> /dev/null
then
    echo "expect was not found. Did you forget to install?"
    exit 1
fi

mandatory () {
  echo -e "Error: Mandatory options and arguments not set. See help (./$0 -h) for more details.\n"
}

# Check that mandatory arguments have been set
if [ -z ${custom+x} ]; then
  if [ -z ${input+x} ] || [ -z ${output+x} ] || [ -z ${ncharges+x} ] || [ -z ${nsamples+x} ]; then
    mandatory; usage; exit 1
  fi
else
  if [ -z ${input+x} ] || [ -z ${output+x} ]; then
    mandatory; usage; exit 1
  fi
fi

title

# Some checks
if test ! -f $input; then
  echo "Input file ${input} does not exist. Please check path. "
  exit 1
else
  if test ! -s $input; then
    echo "Input file ${input} is empty. Please check input."
    exit 1
  fi
fi

if test ! -d $output; then
  mkdir -p $output
  echo "Output files will be saved to ${output}"
else
  while true; do
    read -p "Found existing output directory at ${output}. Do you want to overwrite? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Exiting."; exit;;
        * ) echo "Please answer y or n.";;
    esac
  done
fi

# If custom schedule is used, check the file exists
if [ ! -z ${custom+x} ]; then
  if test ! -f ${custom}; then
    echo "Schedule file ${custom} not found. Please check path."
    exit 1
  else
    echo "Will use custom assignment schedule from $custom"

    # Copy the user given custom file and check for blank line at eof
    charges="$output/$(basename ${custom})"
    sed -e '$a\' $custom > $charges
  fi
else
  # Run charge roulette
  echo -e "\nWill sample $ncharges charges from $(basename $input) $nsamples times."

  [[ $arginine -eq 0 ]] && echo "  ** Residue sampling will ignore all arginine residues."
  [[ $histidine -eq 0 ]] && echo "  ** Residue sampling will ignore all histidine residues."
  [[ $lysine -eq 0 ]] && echo "  ** Residue sampling will ignore all lysine residues."

  $py $chargeroulette -i $input -n $ncharges -s $nsamples -o $output -R $arginine -H $histidine -K $lysine
  if [ $? == 1 ]; then exit 1; fi

  charges="$output/$(basename ${input%.pdb})_samples.txt"
fi

# Print summary of the charges to be assigned:
if test ! -f $charges; then
  echo "Error: ${charges} not found."
  exit 1
fi

# Iterate over each charge set
while read -r line; do
  # Check that line has the correct format:
  # [[ "$line" =~ ^(\d+)(,\{[\d\s]*\})(,\{[\d\s]*\})(,\{[\d\s]*\})$ ]] || echo -e "\n    Error: Incorrect formatting in schedule file."; exit 1
  if [[ ! "$line" =~ ^([[:digit:]]+),\{.*\} ]]; then
    echo -e "Error: Incorrect formatting in schedule file.\n"
    exit 1
  fi

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

    echo -e "\nCharge set ${no}: "
    echo "  - Files in directory: ${jobdir}"

    # Check for fatal errors:
    if grep -q "Fatal error" $log; then
      sed -ne '/Fatal error/,$ p' $log | sed "s/^/    /g"
      echo -e "\n"
      exit 1
    else
      if grep -q "Total charge" $log; then
        echo "  - Charges assigned to residues: "
        echo "    Lysines: $(echo ${lys} | sed 's/{//g; s/}//g; s/ /, /g')"
        echo "    Arginines: $(echo ${arg} | sed 's/{//g; s/}//g; s/ /, /g')"
        echo "    Histidines: $(echo ${his} | sed 's/{//g; s/}//g; s/ /, /g')"
        echo -e "\n  - $(grep 'Total charge' $log)"
        [[ ! -z ${custom+x} ]] && echo "    ** Custom schedule used: check total charge!"
      else
        echo -e "\n  - pdb2gmx did not terminate correctly ('Total charge' not found). Please check output log of pdb2gmx for errors."
        exit 1
      fi
    fi
  fi

done < $charges

echo -e "\nProgram Finished."
