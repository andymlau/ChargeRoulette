# ChargeRoulette: Automating GROMACS pdb2gmx for gas phase MD simulations
# Downloaded from: https://github.com/andymlau/ChargeRoulette
# Author: Andy M. Lau, PhD (2021) (andy.m.lau@ucl.ac.uk)
# See LICENSE file for more details.

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
    parser.add_argument('-R', '--no_arg', type=int, required=False,
                        help='Do not charge arginines.')
    parser.add_argument('-H', '--no_his', type=int, required=False,
                        help='Do not charge histidines.')
    parser.add_argument('-K', '--no_lys', type=int, required=False,
                        help='Do not charge lysines.')
    parser.add_argument('-d', '--depth', type=float, required=False, default=5.0,
                        help='(default 5.0) Charges will only be selected from residues above this depth.')
    parser.add_argument('-p', '--patience', type=int, required=False, default=10,
                        help='(default 10) Number of sampling attempts to make before stopping.')
    args = parser.parse_args()

    # Open pdb, filter out non-CA atoms, get all basic residues that meet depth criteria
    pdb = select_from_mol(open_pdb(args.input), 'n', 'CA')

    posres = []
    if args.no_arg:
        posres.append('ARG')
    if args.no_his:
        posres.append('HIS')
    if args.no_lys:
        posres.append('LYS')

    basic = select_from_mol(pdb, 'resn', posres)[0]
    basic = basic[basic['b'] < args.depth]

    # Check that there are enough residues to choose from
    if len(basic) < args.n_charges:
        print(
            f"\n    Error: requested number of charges ({args.n_charges}) is greater than the number of residues that can be sampled from ({len(basic)}).\n    Decrease the number of charges or check PDB. Are you using -R/H/K to exclude residues?")
        exit(1)

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
