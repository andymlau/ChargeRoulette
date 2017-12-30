## gasMD: Automating pdb2gmx for gas phase MD simulations

These scripts can be used to automate the charge assigning stage of GROMACS pdb2gmx for gas phase molecular dynamics simulations. Gas phase simulations of charged protein complexes are typically performed for comparisons with experimental structural mass spectrometry measurements.  

Assigning charges to proteins and protein complexes can be performed through the following steps: 
1. Neutralisation of all existing charges from the protein pdb file, through setting all chargable residues and termini to protonation states which yield neutral charges.
2. Distribution of a number of charges (usually positive and reflects experimental charge states of species) across the surface of a protein, to mimic experimental surface ionisation. This is done through modifying the protonation state of positively chargable residues (Lys/Arg/His) to be +1 each. 
3. Continue with rest of GROMACS simulation protocol - not covered here. 

### ChargeRoulette.py

ChargeRoulette.py takes as input, a pdb file of a protein or protein complex with its b-factors swapped with the atomic depth of each residue. Depth calculation can be performed with http://cospi.iiserpune.ac.in/depth/htdocs/index.html - I refer to this as 'depth.pdb' here (see *4JFO.pdb-atomic_depth.pdb* in example folder). ChargeRoulette.py extracts all chargable positive residues: Lys, Arg, His, within 5Å of the protein surface. A number of these residues are then randomly selected. 

```
python ChargeRoulette.py -i <input> -n <number of charges> -s <num of sets of charges>
```

```
Inputs
-i <input>    depth.pdb file
-n <charges>  charge state of protein desired, e.g. 13 for 13+ from mass spec
-s <sets>     number of sets of -n to generate

Outputs
..basic_nQ<n>_set<s>.pdb    pdb file containing only residues selected to be charged. s number of files are generated, sampling n number of residues
..expect_charges.txt        Residues from ..basic_nQ<n>_set<s>.pdb are printed here to be used for the next stage
expect_autoAssign.exp
```

### expect_autoAssign.exp

The pdb2gmx program of GROMACS is used to convert pdb files into a GROMACS-compatible topology for molecular dynamics simulations. The output file of pdb2gmx will inherit the default protonation states (and charge state) from the input pdb file. Users can use the -lys -his -arg -asp -glu and -ter commands to interactively select protonation states of each residue. This method cycles over every residue individually, is laborious and accidental mistakes in typing can result in the user needing to repeat pdb2gmx several times before the correct charge state is assigned. 

expect_autoAssign.exp is an expect/tcl script which can automatically set the protonation states of residues which are output from ChargeRoulette.py. 

You will need to set up the expect_autoAssign.exp and pdb2gmx_gas_oplsaa_merge_res-assign.sh scripts before running the expect command using:

```
expect expect_autoAssign.exp
```
Within expect_autoAssign.exp residues that are to be charged are set up in the following format:

```
set lysines {535 201 114 382 195 423 816 291}
set arginines {708 773 648 56 6 171 165 695}
set histidines {547 363 310}
```

The ..expect_charges.txt output of ChargeRoulette.txt contains lists which are substituted into the expect_autoAssign.exp script. 

Responses to pdb2gmx are set up in the following format:

```
#Lysine charge and default settings; 0 = non-protonated (0), 1 = protonated (+1)
    -re $lys_q {
        if {$expect_out(1,string) in $lysines} {
            send "1\r"
        } else {
            send "0\r"
        }
        exp_continue
    }
```
If expect encounters a residue listed in lysines/arginines/histidines, *1* will be sent, setting the protonation state to +1 for that residue. All other residues are set to *0* or non-protonated. pdb2gmx will terminate after the topol.top file is generated.

The actual pdb2gmx program is spawned through the pdb2gmx_gas_oplsaa_merge_res-assign.sh script from within expect. The pdb2gmx command is set up as:

```
gmx pdb2gmx -f 2_CRL2_6784.pdb -o 0_out.pdb -v -heavyh -ff oplsaa -p 0_topol.top -i 0_posre.itp -water none -lys -arg -asp -glu -his -ter
```

Please consult GROMACS documentation on pdb2gmx for the full definition of each flags. The relevant flags to automatic charge assigning are the following:

```
-f <input>              Pdb file initially submitted to DEPTH server - the depth.pdb CANNOT be used. 
-p <topol>              output name for the topology file
-lys, etc.              triggers pdb2gmx interactive residue protonation state selector
```

**If your system has more than one chain**
As expect_autoAssign.exp relies on recognition of a single residue number, if chain A contains a LYS 200 to be charged and chain B coincidentally has LYS at position 200, both residues will be charged.

**Solution 1**
To avoid this problem, you should check the STDOUT of pdb2gmx to ensure that the total system charge is what you expect it to be. You can alter the residue lists in expect_autoAssign.exp by either manually selecting an alternative, non-clashing residue, or use another randomly sampled set of residues from ChargeRoulette.py.

**Solution 2**
Renumber all chains consecutively and then remove all chain information. Linearizing the pdb in this way is much more efficient as residue numbers are not shared between different parts of the protein complex. Methods of doing this are not covered here.

### topol_to_txt.sh

The topol_to_txt.sh bash script can be used to check that your pdb2gmx out.pdb file is configured with the correct distribution of charges. To use this: 

```
bash topol_to_txt.sh <0_topol_Protein_chain_D.itp>
```

The topol_to_txt.sh script reads through each residue of the topology file and returns the residues which have a +1 charge - these being your lys, arg and his residues from the last script. 

If your charges are spread across multiple chains, you will need to run topol_to_txt.sh on each chain-specific topology file. To check that the correct charges have been distributed, open the basic_nQ_set.pdb file that you used from ChargeRoulette.py in PyMOL and paste the output of topol_to_txt.sh:

```
select qRes=(i;14,48,121,146,176,186,263)
```

the qRes selection should match the residues within your pdb file. 


### Additional Information

All testing was performed on GROMACS version 5.1.2 on a Mac running macOS Sierra Version 10.12.6

For more information, please contact Andy at andy.lau@kcl.ac.uk
