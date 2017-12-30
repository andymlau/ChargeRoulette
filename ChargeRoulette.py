# Reads PDB output from DEPTH server, extracts all HIS, ARG and LYS residues and returns set of X residues to be charged
# in gas phase simulations

# Last updated by Andy Dec 2017

import random
from numpy import unique
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--input","-i", help='The PDB output from DEPTH.',type=str)
parser.add_argument("--nQ","-n", help='Number of charges to sample.',type=int)
parser.add_argument("--nSets","-s", help='Number of sets of charges to generate.',type=int,default=1)
parser.add_argument("--extract_only","-eo", help="Extract basic residues only without sampling.",action="store_true",default='False')

args = parser.parse_args()

filename = args.input
nQ = args.nQ
nSets = args.nSets

# Read lines from PDB file
inputFile = open(filename, 'r')
inputFileLines = inputFile.read().splitlines()

nLines = len(inputFileLines)

inputFile.close()

# Residues to find
basics = ['LYS', 'HIS', 'ARG']

# Read coordinates and specify depth
basicLines = []
chainLines = []

for line in inputFileLines:
    depth = float(str(line[61:66]))

    if (line[17:20] in basics) and line.find('CA') >= 0 and line.find('ATOM') >= 0 and depth < 5.0:
        basicLines.append(line)

    chainLines.append(line[21:22])
    chains = unique(chainLines)

chainsPrint = ', '.join(chains)

print " "
print "  Structure contains "+str(nLines)+" residues across "+str(len(chains))+" chains: "+str(chainsPrint)
print "  Number of chargable residues: "+str(len(basicLines))

charge_str = []

if args.extract_only == True:
    # Create Output File
    OutputFileName = filename[:-4] + '.basic.pdb'
    OutputFile = open(OutputFileName, 'w')

    for line in basicLines:
        OutputFile.write(line + '\n')
    OutputFile.write('END' + '\n')

    OutputFile.flush()
    OutputFile.close()

    print "  Output PDB saved to " + str(OutputFileName)
    print " "

else:
    for i in range(0, int(nSets)):

        random.shuffle(basicLines)

        sample = basicLines[0:int(nQ)]

        # Create Output File
        OutputFileName = filename[:-4] + '.basic_nQ'+str(nQ)+'_set'+str(i+1)+'.pdb'
        OutputFile = open(OutputFileName, 'w')

        for line in sample:
            OutputFile.write(line + '\n')
        OutputFile.write('END' + '\n')

        OutputFile.flush()
        OutputFile.close()

        print "  Output PDB saved to "+str(OutputFileName)

        lysines = []
        arginines = []
        histidines = []

        for residue in sample:
            if residue[17:20] == 'LYS':
                lysines.append(residue[23:26])
            if residue[17:20] == 'ARG':
                arginines.append(residue[23:26])
            if residue[17:20] == 'HIS':
                histidines.append(residue[23:26])

        lysines = ' '.join(lysines)
        arginines = ' '.join(arginines)
        histidines = ' '.join(histidines)

        charge_str.append("Charge roulette spin No."+str(i+1)+":")
        charge_str.append("   Charges correspond to file "+str(OutputFileName))
        charge_str.append("  ")
        charge_str.append("   set lysines {"+str(lysines)+"}")
        charge_str.append("   set arginines {"+str(arginines)+"}")
        charge_str.append("   set histidines {"+str(histidines)+"}")
        charge_str.append("  ")

# Create Output File for expect script code
OutputFileName = filename[:-4] + '.expect_charges.txt'
OutputFile = open(OutputFileName, 'w')

for line in charge_str:
    OutputFile.write(line + '\n')

OutputFile.flush()
OutputFile.close()

print "  All charge roulette residues saved to " + str(OutputFileName)

print " "