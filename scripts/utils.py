# GasMD script from https://github.com/andymlau/gasMD
# Written by Andy M Lau 2021

import os
import sys
import numpy as np
import random


def open_pdb(file):
    """ Return the coordinates of a PDB file.
        file = path to file """

    exclude = ['ASX', 'GLX', 'SEC', 'PYL', 'UNK']

    ter = 0
    molecules = []
    with open(file, 'r') as enspdbfile:
        mol = []

        for i, line in enumerate(enspdbfile):
            if line[:1] == '#' or line[:5] == 'MODEL' or line[:6] == '#MODEL':
                modelName = line[1:]
            if line[:4] == 'ATOM':
                if not np.char.isnumeric(line[12]) and line[17:20].strip() not in exclude:
                    mol.append((line[:6].strip(), line[6:11], line[12:16].strip(), line[16:17].strip(),
                                line[17:20].strip(), line[20:22].strip(), line[22:26], line[30:38],
                                line[38:46], line[46:54], line[54:60], line[60:66]))

            # or line[:6] == 'ENDMDL':
            if line[:6] == 'ENDMDL' or line[:3] == 'END' or line == '':
                mol = np.array(mol, dtype=[('type', 'U6'), ('i', 'i4'), ('n', 'U4'), ('alt', 'U1'),
                                           ('resn', 'U3'), ('chain', 'U2'), ('resi', 'i4'), ('x', 'f8'),
                                           ('y', 'f8'), ('z', 'f8'), ('occ', 'f8'), ('b', 'f8')])

                if len(mol) > 0:
                    molecules.append(mol)
                    ter = 1
                    mol = []

    # Hack for when there's no END or ENDMDL at the eof
    if ter == 0 and len(mol) > 0:
        molecules.append(np.array(mol, dtype=[('type', 'U6'), ('i', 'i4'), ('n', 'U4'), ('alt', 'U1'),
                                              ('resn', 'U3'), ('chain',
                                                               'U2'), ('resi', 'i4'), ('x', 'f8'),
                                              ('y', 'f8'), ('z', 'f8'), ('occ', 'f8'), ('b', 'f8')]))

    return molecules


def select_from_mol(mols, name, selection_list):
    """ Extract rows of mol with 'name' in 'selection_list'
        e.g. ['ASN','ASP'] from 'resn'
        e.g. ['CA'] from 'n'
        e.g. [2, 3, 4, 5] from 'resi'
        e.g. ['A','B'] from 'chain' """

    return [m[np.isin(m[name], selection_list)] for m in mols]


def get_xyz(mol):
    """ Neater way to return xyz coordinates from mol
        Checks for missing residues - adds NAN where missing
        Handles single mol, not list of mols """

    padded_mol = []
    start_res = mol[0]['resi']
    end_res = mol[-1]['resi']
    expected_range = range(start_res, end_res+1)

    mol_padded = []
    for p in expected_range:
        res = mol[mol['resi'] == p]
        if len(res) == 0:
            mol_padded.append((p, np.NAN, np.NAN, np.NAN))
        else:
            mol_padded.append((res['resi'], res['x'], res['y'], res['z']))

    mol = np.array(mol_padded, dtype=[('resi', 'i4'),
                                      ('x', 'f8'),
                                      ('y', 'f8'),
                                      ('z', 'f8')])

    return np.array(mol['resi']), np.array([mol['x'], mol['y'], mol['z']])


def charge_sample(mol, n_charges, n_samples, patience=10):
    """ Returns n_samples sets of n_charges charges selected at random from mol.
        patience - controls the number of attempts to select a non-redunant set before
        quitting. """

    charge_set = []
    counter = 0
    while len(charge_set) != n_samples:
        sample = np.sort(np.random.choice(mol, n_charges, replace=False), order='i')

        # Save sample only if not in set already
        if any(np.array_equal(sample, x) for x in charge_set):
            counter += 1
        else:
            charge_set.append(sample)
            counter = 0

        # Force stop if counter reaches patience
        if counter == patience:
            print(f"Patience reached without generating unique sample. Increase patience with -p or decrease number of samples.")
            exit()

    return charge_set


def write_multi_state_pdb(mols, outname):
    """ Writes a multi-state pdb file to disk """

    with open(outname, 'w') as f:
        f.write("# File generated using gasMD script from https://github.com/andymlau/gasMD\n")

        for i, m in enumerate(mols):
            f.write('MODEL   %6d\n' % (i+1))
            for line in m:
                f.write("ATOM   %4d  %-3s %s %s%4d    %8.3f%8.3f%8.3f%6.2f%6.2f\n" % (
                    line['i'], line['n'], line['resn'], line['chain'], line['resi'],
                    line['x'], line['y'], line['z'], line['occ'], line['b']))
            f.write('TER\n')
            f.write('ENDMDL\n')
        f.write('END\n')


def write_sample(mol, outname, outpdb):
    """ Writes the selected charges from charge_sample to a text file for the expect script """

    resdict = {'LYS': 'lysine', 'ARG': 'arginine', 'HIS': 'histidine'}

    with open(outname, 'w') as f:
        f.write("Surface charges sampled using ChargeRoulette (https://github.com/andymlau/gasMD)\n")
        f.write("Code written by Andy M. Lau, PhD. (2021)\n\n")
        f.write("To use, copy and paste the relevant lysine/argnine/histidine block into the expect script.\n\n")

        for i, n in enumerate(mol):
            f.write(f"Charge Roulette Spin No. {i+1}\n")
            f.write(f"   PDB: model {i+1} of pdb {outpdb}\n\n")

            for m in ['LYS', 'ARG', 'HIS']:
                res = select_from_mol([n], 'resn', [m])[0]

                if len(res) > 0:
                    resstr = " ".join([str(ele) for ele in res['resi']])
                else:
                    resstr = ''

                f.write("   set {} {{{}}}\n".format(resdict[m], resstr))

            f.write("\n")


def write_charges(mol, outname):
    """ Writes the selected charges from charge_sample to a text file for the expect script """

    with open(outname, 'w') as f:
        for i, n in enumerate(mol):

            charges = []
            for m in ['LYS', 'ARG', 'HIS']:
                res = select_from_mol([n], 'resn', [m])[0]

                if len(res) > 0:
                    resstr = " ".join([str(ele) for ele in res['resi']])
                else:
                    resstr = ''

                charges.append(resstr)

            f.write("{},{{{}}},{{{}}},{{{}}}\n".format(i+1, charges[0], charges[1], charges[2]))
