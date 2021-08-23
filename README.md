# ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations

These scripts can be used to automate the charge assigning step of GROMACS pdb2gmx for gas phase molecular dynamics simulations. Gas phase simulations of charged protein complexes are typically performed for comparisons with experimental structural mass spectrometry measurements.  

Assigning charges using the GROMACS pdb2gmx interactive tool (via `-lys` `-arg` `-his` etc. flags) is very tedious, as the user the prompted to key in a number, e.g. '0' for a non-protonated (z=-1) aspartic acid, or '1' to have it protonated (z=0), for every residue in the input file. Hence the motivation for this repo is to put together scripts that can automatically assign such protonation states without needing any input from the user.

<p align="center">
  <img width="600" height="450" src="https://github.com/andymlau/gasMD/blob/master/examples/sample.gif">
</p>

## Contents
- [Please read before trying to run](#please-read-before-trying-to-run)
- [Prerequisites](#prerequisites)
- [Instructions for use](#instructions-for-use)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
    - [Example output](#example-output)
- [Runtime](#runtime)
- [Other useful customisations](#other-useful-customisations)
  - [Changing the pdb2gmx run command](#changing-the-pdb2gmx-run-command)
  - [To gmx or not to gmx?](#to-gmx-or-not-to-gmx)

### Please read before trying to run
A few assumptions are made in terms of how charges are initialised:
1. Mass spec typically produces net positively charged ions, and so to produce such representations, all acidic residues are set to neutral (i.e. protonated) and a number of charges are spread randomly across only the basic residues (lys, arg and his). Termini are also left neutral.
2. Charge-carrying residues are selected randomly from a set of candidate residues that meet the selection criteria, defined as all lys, arg and his residues within 5Å depth of the surface of the molecule.
3. ChargeRoulette does not clean your file for you - it is assumed that your pdb file is set up properly, i.e. chain and residue ids are correct and that any chain breaks in the molecule are intended or at least acknowledged. For general pdb file manipulation, [pdb-tools](http://www.bonvinlab.org/pdb-tools/) from the Bonvin Lab is recommended.

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

#### Inputs:

1. First, source GROMACS using `source /usr/local/gromacs/bin/GMXRC` or the equivalent command for your system.
2. Given an input pdb file, such as `examples/input/2GRN.pdb`, the file must first be submitted to the DEPTH server found [here](http://cospi.iiserpune.ac.in/depth).
3. A zip file containing outputs can be downloaded from the server once the job has been completed. The output file with the suffix `-residue_depth.pdb` should be used for ChargeRoulette. An example output file is supplied at `examples/input/2GRN.pdb-residue_depth.pdb`. Residue depths (Å) replace the b-factor column in this file. The depth is used to select surface residues that can be charge-carrying.

4. The command for running charge roulette is:

```
bash run_charge_roulette.sh input.pdb n_charges n_samples output_directory
```
e.g.
```
bash run_charge_roulette.sh examples/inputs/2GRN.pdb-residue_depth.pdb 10 3 examples/test
```

- `input.pdb` - (path) is the output file of DEPTH, e.g. `2GRN.pdb-residue_depth.pdb`
- `n_charges` - (int) is the number of charges that will be assigned to the surface of the molecule. This should match the experimental charge state of the protein observed via native mass spectrometry.
- `n_samples` - (int) is the number of charge samples, e.g. 10 will produce 10 alternative charge configurations of your input molecule.
- `output_directory` - (path) is the path that the output files should be saved to.

For example, running ChargeRoulette with `n_charges=10`, and `n_samples=5`, will randomly distribute 10 charges on the surface of `input.pdb`, 5 times.

If re-running ChargeRoulette to the same output directory, the user will be prompted to confirm that they wish to overwrite any existing files in the output directory:
```
bash run_charge_roulette.sh examples/inputs/2GRN.pdb-residue_depth.pdb 9 4 examples/test
Found existing output directory at /home/andy/Github/ChargeRoulette/examples/test. Do you want to overwrite? [y/n]
```
When prompted, enter `y` to overwrite the files, or `n` to quit the program.

#### Outputs:
5. A number of output files are written to the user-defined output folder:

- `2GRN.pdb-residue_depth_samples.pdb` - a multi-state pdb file where each state contains the charge-carrying residues. This file is for visualisation only. It can be quite useful to open together this file and the original input pdb, in PyMOL to visualise where the charges have been assigned to. This strategy can be used iteratively to test different distributions of charges and test how they affect the simulation, for example.
- `2GRN.pdb-residue_depth_samples.txt` - a summary of the residues that were selected in each sample. `1,{14 18 30 49 59 74 101 146},{141},{20}` is in the format: `sample_no,{LYS residue numbers},{ARG residue numbers},{HIS residue numbers}'.
- `sample_x` - subfolders containing the `pdb2gmx` output files for each set of charges, where `x` is equal to `n_samples` in the last step. Running ChargeRoulette with `n_samples=10` will generate 10 subfolders.

Within `sample_x` subfolders:
- ***auto_assign.exp*** - an expect script generated by ChargeRoulette used to interact with pdb2gmx.
- ***run_pdb2gmx.sh*** - a bash script containing the pdb2gmx command.
- **pdb2gmx.log** - a log file containing the stdout of pdb2gmx.
- **out.pdb** - a pdb2gmx output file.
- **topol.top** - a pdb2gmx output file.
- **posre.itp** - a pdb2gmx output file.

(Files in italics above can be deleted once the program has finished.)

#### Example output:

```
Running charge_roulette.py
  - Will sample 10 charges from 2GRN.pdb-residue_depth.pdb 3 times.
  - The following charges will be assigned: (sample_no,LYS,ARG,HIS):
    1,{18 48 49 65 74 146 153 154},{17 141},{}
    2,{18 30 48 59 101 110 146 154},{104},{20}
    3,{18 30 101 146 153},{8 141 147 149},{20}

  Charge set 1:
  - Files in directory: /home/andy/Github/gasMD/examples/test/sample_1
  - Charges assigned to residues:
    Lysines: 18, 48, 49, 65, 74, 146, 153, 154
    Arginines: 17, 141
    Histidines:

  - Total charge 10.000 e

  Charge set 2:
  - Files in directory: /home/andy/Github/gasMD/examples/test/sample_2
  - Charges assigned to residues:
    Lysines: 18, 30, 48, 59, 101, 110, 146, 154
    Arginines: 104
    Histidines: 20

  - Total charge 10.000 e

  Charge set 3:
  - Files in directory: /home/andy/Github/gasMD/examples/test/sample_3
  - Charges assigned to residues:
    Lysines: 18, 30, 101, 146, 153
    Arginines: 8, 141, 147, 149
    Histidines: 20

  - Total charge 10.000 e
```

- The 'Total charge' above should be checked in each instance to make sure that the total molecule charge is correct.

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

#### Changing the pdb2gmx run command
By default the pdb2gmx run command is:
```
gmx pdb2gmx -f ${input} -o ${jobdir}/out.pdb -p ${jobdir}/topol.top -i ${jobdir}/posre.itp -v -heavyh -ff oplsaa -water none -lys -arg -asp -glu -his -ter -renum -merge all
```
However this may not suit your particular application, depending on what you're simulating or how complex your system is. The flags after `-i` can be customised by editing the `fflags` variable in `run_charge_roulette.sh`.

#### To gmx or not to gmx?
This has not been tested yet, but if for some reason you are running an older version of GROMACS which does not preceed `pdb2gmx` with `gmx`, you will need to change the `gromacs` variable on line 24 of `run_charge_roulette.sh` and possibly line 86 if you don't need to source GROMACS first. As far as I know, the key mappings for the interactive charge assignment step of pdb2gmx is unchanged from GROMACS version 4 onwards), but it's worth checking that your total charge is correct after assignment and investigate further if not.

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
