# ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations

These scripts can be used to automate the charge assigning step of GROMACS pdb2gmx for gas phase molecular dynamics simulations. Gas phase simulations of charged protein complexes are typically performed for comparisons with experimental structural mass spectrometry measurements. 

Assigning charges using the GROMACS pdb2gmx interactive tool (via `-lys` `-arg` `-his` etc. flags) is very tedious, as the user the prompted to key in a number, e.g. '0' for a non-protonated (z=-1) aspartic acid, or '1' to have it protonated (z=0), for every residue in the input file. Hence the motivation for this repo is to put together scripts that can automatically assign such protonation states without needing any input from the user. ChargeRoulette can assign charges through GROMACS very quickly by using the `expect` program which automates interactions with the command line. This bypasses the need for the user to interactively enter 0s and 1s to assign the protonation state of each residue. 

The intended use case is that ChargeRoulette can be used to generate many instances of a biological system with a total charge relevant to mass spectrometry, and each with a random distribution of charged residues (although a user-defined distribution can also be used). Each instance can then be input to the rest of the GROMACS simulation workflow (equilibration, production, etc.). This repo **does not** contain files for running the simulations. 

This method has been applied to work such as that published in **Hansen & Lau et al., 2018, Angewandte Chemie**, [link](https://onlinelibrary.wiley.com/doi/10.1002/anie.201812018).

Of interest, is a method published by **Konermann, 2017**, that implements a mobile proton method that allow charges to move between residues periodically, [link](https://pubs.acs.org/doi/pdf/10.1021/acs.jpcb.7b05703).

##

<p align="center">
  <img width="600" height="450" src="https://github.com/andymlau/gasMD/blob/master/examples/sample.gif">
</p>

## Contents
- [Read before running](#read-before-running)
- [Prerequisites](#prerequisites)
- [Instructions for use](#instructions-for-use)
  - [Preparing inputs](#preparing-inputs)
  - [Running the program](#running-the-program)
    - [Example run commands](#example-run-commands)
  - [Outputs](#outputs)
    - [Example output](#example-output)
- [Runtime](#runtime)
- [Other useful customisations](#other-useful-customisations)
  - [Using a custom assignment schedule](#using-a-custom-assignment-schedule)
  - [Changing the pdb2gmx run command](#changing-the-pdb2gmx-run-command)
  - [To gmx or not to gmx?](#to-gmx-or-not-to-gmx)
  - [Notes for handling multi-chain inputs](#notes-for-handling-multi-chain-inputs)


### Read before running
A few assumptions are made in terms of how charges are initialised:
1. Mass spec typically produces net positively charged ions, and so to produce such representations, all acidic residues are set to neutral (i.e. protonated) and a number of charges are spread randomly across only the basic residues (lys, arg and his). Termini are also left neutral.
2. Charge-carrying residues are selected randomly from a set of candidate residues that meet the selection criteria, defined as all lys, arg and his residues within 5Å depth of the surface of the molecule.
3. ChargeRoulette does NOT run the whole gas phase simulation - it only performs the initial charge assignment step. For a detailed description on how to perform such simulations, Lars Konermann has a nice methods article [here](https://www.sciencedirect.com/science/article/abs/pii/S1046202317304644?via%3Dihub).  
4. ChargeRoulette does not clean your file for you - it is assumed that your pdb file is set up properly, i.e. chain and residue ids are correct and that any chain breaks in the molecule are intended or at least acknowledged. For general pdb file manipulation, [pdb-tools](http://www.bonvinlab.org/pdb-tools/) from the Bonvin Lab is recommended.

### Prerequisites:

- [GROMACS](https://manual.gromacs.org/documentation/) (tested on version 2021.3 released August 18th, 2021)
- The `expect` program for linux: https://linux.die.net/man/1/expect
- At least Python 3.

### Instructions for use:

The following files are distributed:
- `run_charge_roulette.sh` - This is the main chargeroulette script that should be run.
- `residuetypes.dat` - A custom residuetypes.dat file that includes 'LYSN' to allow lysines to be charged.
- `README.md` - This readme file.
- `scripts/charge_roulette.py` - Handles input pdb parsing and charge sampling.
- `scripts/utils.py` - Functions for charge_roulette.py
- `examples` - Example input and output files.

#### Preparing inputs:

1. First, source GROMACS using `source /usr/local/gromacs/bin/GMXRC` or the equivalent command for your system.
2. Given an input pdb file, such as `examples/input/2GRN.pdb`, the file must first be submitted to the DEPTH server found [here](http://cospi.iiserpune.ac.in/depth).
3. A zip file containing outputs can be downloaded from the server once the job has been completed. The output file with the suffix `-residue_depth.pdb` should be used for ChargeRoulette. An example output file is supplied at `examples/input/2GRN.pdb-residue_depth.pdb`. Residue depths (Å) replace the b-factor column in this file. The depth is used to select surface residues that can be charge-carrying.

4. The command for running charge roulette is:

```
./run_charge_roulette.sh [-i <string; path] [-o <string; path>] [-n <int>] [-s <int>]
```

#### Running the program:
```
-h, --help       Show this help menu.

Mandatory arguments:
-i, --input      (path) input pdb file to run ChargeRoulette on. Should be the (residuedepth) output of DEPTH server.
-o, --output     (path) specify the output directory for files to be written to.
-n, --ncharges   (int) specify the number of positive charges that each run should generate. e.g. 7 for a the output pdb to have a +7 charge.
-s, --nsamples   (int) specify the number of alternative charge configurations. e.g. 5 will generate 5 different output pdbs.

Optional arguments:
-c, --custom     (path) use a custom assignment schedule. If option used, -n and -s are no longer mandatory.
-R, --arg        Do not include arginines.
-H, --his        Do not include histidines.
-K, --lys        Do not include lysines.
```

##### Example run commands:
Charge the input to 7+ and generate 3 distributions of charges selected from ARG/HIS/LYS:
```
./run_charge_roulette.sh -i examples/inputs/2GRN.pdb-residue_depth.pdb -o ./examples/test -n 7 -s 3
```

Charge the input to 7+ and generate 3 distributions of charges selected from HIS/LYS (ignore ARG):
```
./run_charge_roulette.sh -i examples/inputs/2GRN.pdb-residue_depth.pdb -o ./examples/test -n 7 -s 3 -R
```

Charge the input to 3+ and generate 10 distributions of charges selected from only LYS (ignore ARG/HIS):
```
./run_charge_roulette.sh -i examples/inputs/2GRN.pdb-residue_depth.pdb -o ./examples/test -n 3 -s 10 -R -H
```

If re-running ChargeRoulette to the same output directory, the user will be prompted to confirm that they wish to overwrite any existing files in the output directory:
```
Found existing output directory at /home/andy/Github/ChargeRoulette/examples/outputs. Do you want to overwrite? [y/n]
```
When prompted, either enter `y` followed by return to overwrite the files, or `n` to quit the program.

#### Outputs:
5. A number of output files are written to the user-defined output folder:

- `2GRN.pdb-residue_depth_samples.pdb` - a multi-state pdb file where each state contains the charge-carrying residues. This file is for visualisation only. It can be quite useful to open together this file and the original input pdb, in PyMOL to visualise where the charges have been assigned to. This strategy can be used iteratively to test different distributions of charges and test how they affect the simulation, for example.
- `2GRN.pdb-residue_depth_samples.txt` - the charge assignment schedule file that will be used by expect to interact with pdb2gmx. See [Using a custom assignment schedule](#using-a-custom-assignment-schedule) for more details.
- `sample_x` - subfolders containing the `pdb2gmx` output files for each set of charges, where `x` is equal to the number of samples requested using `-s`. Running ChargeRoulette with `-s 10` will generate 10 subfolders.

Within `sample_x` subfolders:
- **auto_assign.exp** - an expect script generated by ChargeRoulette used to interact with pdb2gmx.
- **run_pdb2gmx.sh** - a bash script containing the pdb2gmx command.
- **pdb2gmx.log** - a log file containing the stdout of pdb2gmx.
- **out.pdb** - a pdb2gmx output file.
- **topol.top** - a pdb2gmx output file.
- **posre.itp** - a pdb2gmx output file.


#### Example output:
```
-----------------------------------------------------------------------
ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations
-----------------------------------------------------------------------

Downloaded from: https://github.com/andymlau/ChargeRoulette
Author: Andy M. Lau, PhD (2021) (andy.m.lau@ucl.ac.uk)

Output files will be saved to /home/andy/Github/ChargeRoulette/examples/outputs

Will sample 5 charges from 2GRN.pdb-residue_depth.pdb 3 times.

Charge set 1:
  - Files in directory: /home/andy/Github/ChargeRoulette/examples/outputs/sample_1
  - Charges assigned to residues:
    Lysines: 48, 65, 153
    Arginines: 17
    Histidines: 20

  - Total charge 5.000 e

Charge set 2:
  - Files in directory: /home/andy/Github/ChargeRoulette/examples/outputs/sample_2
  - Charges assigned to residues:
    Lysines: 48, 65, 110, 146
    Arginines: 141
    Histidines:

  - Total charge 5.000 e

Charge set 3:
  - Files in directory: /home/andy/Github/ChargeRoulette/examples/outputs/sample_3
  - Charges assigned to residues:
    Lysines: 14, 18, 153, 154
    Arginines: 17
    Histidines:

  - Total charge 5.000 e

Program Finished.

```
- The 'Total charge' above should be checked in each instance to make sure that the total molecule charge is correct, especially if the user uses a custom assignment schedule using the `-c` flag. 
- If no residues of a certain type are selected, the res id list will be blank, e.g. Histidines for charge sets 2 and 3 above. 

If pdb2gmx encounters a fatal error, the error will be printed and the program will stop:
```
  Charge set 1:
  - Files in directory: /home/andy/Github/ChargeRoulette/examples/test2/sample_1
    Fatal error:
    Residue 129 named LEU of a molecule in the input file was mapped
    to an entry in the topology database, but the atom C used in
    that entry is not found in the input file. Perhaps your atom
    and/or residue naming needs to be fixed.

    For more information and tips for troubleshooting, please check the GROMACS
    website at http://www.gromacs.org/Documentation/Errors
    -------------------------------------------------------
```
As these are input specific issues, consult the error message and the GROMACS documentation to fix these.

#### Runtime

ChargeRoulette has linear time complexity and takes roughly 2 seconds to sample 10 charges from a 157 residue long protein (i.e., `n_samples=1`, `n_charges=10`), running on 1 core of a Xeon E5-1650 CPU. Each additional sample takes another ~2 seconds, that is, `n_samples=10` will take ~2x10=~20 seconds for the same protein and `n_charges`. The quoted runtime includes both the sampling and running the charge assignment process in pdb2gmx.

### Other useful customisations:

#### Using a custom assignment schedule
Each time ChargeRoulette runs, an assignment schedule file is generated which summarises which LYS, ARG or HIS will be protonated by pdb2gmx. An example of such a file can be found at `examples/outputs/2GRN.pdb-residue_depth_samples.txt`:
```
1,{48 65 153},{17},{20}
2,{48 65 110 146},{141},{}
3,{14 18 153 154},{17},{}
```
The schedule is a text file where each line represents a separate distribution of selected residues. Using `-s 5` will generate a file with 5 lines. Each line consists of 4 descriptors separated by commas: `sample_no`, `{LYS to protonate}`,  `{ARG to protonate}` and `{HIS to protonate}`, where values in `{}` are residue numbers. 

In the case where the user wishes to designate their own residue sets, the `-c` flag can be used to point ChargeRoulette to a custom schedule file:
```
./run_charge_roulette.sh -i examples/inputs/2GRN.pdb-residue_depth.pdb -o ./examples/outputs_custom_schedule -c examples/inputs/custom_schedule.txt
```

Output:
```
-----------------------------------------------------------------------
ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations
-----------------------------------------------------------------------

Downloaded from: https://github.com/andymlau/ChargeRoulette
Author: Andy M. Lau, PhD (2021) (andy.m.lau@ucl.ac.uk)

Output files will be saved to /home/andy/Github/ChargeRoulette/examples/outputs_custom_schedule
Will use custom assignment schedule from /home/andy/Github/ChargeRoulette/examples/inputs/custom_schedule.txt

Charge set 1:
  - Files in directory: /home/andy/Github/ChargeRoulette/examples/outputs_custom_schedule/sample_1
  - Charges assigned to residues:
    Lysines: 48, 65, 153
    Arginines: 17
    Histidines: 20

  - Total charge 5.000 e
    ** Custom schedule used: check total charge!
```
The user's schedule will be copied to the output directory. The user should take care to check the total charge of their system if custom residues are requested. 

#### Changing the pdb2gmx run command
By default the pdb2gmx run command is:
```
gmx pdb2gmx -f ${input} -o ${jobdir}/out.pdb -p ${jobdir}/topol.top -i ${jobdir}/posre.itp -v -heavyh -ff oplsaa -water none -lys -arg -asp -glu -his -ter -renum -merge all
```
However this may not suit your particular application, depending on what you're simulating or how complex your system is. The flags after `-i` can be customised by editing the `fflags` variable (line 18) in `run_charge_roulette.sh`.

#### To gmx or not to gmx?
This has not been tested yet, but if for some reason you are running an older version of GROMACS which does not preceed `pdb2gmx` with `gmx`, you will need to change the `gromacs` variable on line 17 of `run_charge_roulette.sh`. As far as I know, the key mappings for the interactive charge assignment step of pdb2gmx is unchanged from GROMACS version 4 onwards), but it's worth checking that your total charge is correct after assignment and investigate further if not.

Mappings for version 2021.3:
```
Which LYSINE type do you want for residue 1
0. Not protonated (charge 0) (LYS)
1. Protonated (charge +1) (LYSH)

Which ARGININE type do you want for residue 14
0. Not protonated (charge 0) (ARGN)
1. Protonated (charge +1) (ARG)

Which ASPARTIC ACID type do you want for residue 87
0. Not protonated (charge -1) (ASP)
1. Protonated (charge 0) (ASPH)

Which GLUTAMIC ACID type do you want for residue 7
0. Not protonated (charge -1) (GLU)
1. Protonated (charge 0) (GLUH)

Which HISTIDINE type do you want for residue 15
0. H on ND1 only (HISD)
1. H on NE2 only (HISE)
2. H on ND1 and NE2 (HISH)
3. Coupled to Heme (HIS1)

Select start terminus type for LYSN-1
 0: NH3+
 1: ZWITTERION_NH3+ (only use with zwitterions containing exactly one residue)
 2: NH2
 3: None

Start terminus LYSN-1: NH2
Select end terminus type for LEU-129
 0: COO-
 1: ZWITTERION_COO- (only use with zwitterions containing exactly one residue)
 2: COOH
 3: None
```

#### Notes for handling multi-chain inputs
If simulating larger systems or protein complexes with more than one chain, it is ultimately up to the user to prepare and sanitise their input pdb. Currently ChargeRoulette has only been tested on single chains, however multi-chain pdbs can be safely handelled by *linearising* the residue numbers, such that inter-chain residue numbers are unique and do not overlap (e.g. chain A: 1-100, chain B: 101-200, chain C: 600-700), and then finally re-chaining the pdb to only chain A.

