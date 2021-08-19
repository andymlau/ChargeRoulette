# GasMD script from https://github.com/andymlau/gasMD
# Written by Andy M Lau 2021

import argparse
from utils import *


def main():

    # Create the parser and add arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', type=str, required=True,
                        help='PDB output from DEPTH (has atomic depth in place of b-factors)')
    parser.add_argument('-o', '--outdir', type=str, required=True,
                        help='Where output files will be saved to.')
    parser.add_argument('-n', '--n_charges', type=int, required=True,
                        help='The number of residues to select each time.')
    parser.add_argument('-s', '--n_samples', type=int, required=True,
                        help='The number of samples.')
    parser.add_argument('-d', '--depth', type=float, required=False, default=5.0,
                        help='(default 5.0) Charges will only be selected from residues above this depth.')
    parser.add_argument('-p', '--patience', type=int, required=False, default=10,
                        help='(default 10) Number of sampling attempts to make before stopping.')
    args = parser.parse_args()

    # Open pdb, filter out non-CA atoms, get all basic residues that meet depth criteria
    pdb = select_from_mol(open_pdb(args.input), 'n', 'CA')
    basic = select_from_mol(pdb, 'resn', ['HIS', 'ARG', 'LYS'])[0]
    basic = basic[basic['b'] < args.depth]

    # Check that there are enough residues to choose from
    if len(basic) < args.n_charges:
        print("Error: requested number of charges is greater than the number of residues that can be sampled from. Decrease the number of charges or check PDB.")
        exit()

    sample = charge_sample(mol=basic,
                           n_charges=args.n_charges,
                           n_samples=args.n_samples,
                           patience=args.patience)

    # Save samples to multi-model pdb and txt file for expect script
    basename = os.path.basename(args.input)
    outpdb = args.outdir + "/" + basename[:-4] + '_samples.pdb'
    outtxt = args.outdir + "/" + basename[:-4] + '_samples.txt'

    write_multi_state_pdb(sample, outpdb)
    # write_sample(sample, outtxt, outpdb)
    write_charges(sample, outtxt)


if __name__ == "__main__":
    main()
