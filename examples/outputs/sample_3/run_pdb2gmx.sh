source /usr/local/gromacs/bin/GMXRC
gmx pdb2gmx -f /home/andy/Github/gasMD/examples/inputs/2GRN.pdb-residue_depth.pdb -o /home/andy/Github/gasMD/examples/outputs/sample_3/out.pdb -p /home/andy/Github/gasMD/examples/outputs/sample_3/topol.top -i /home/andy/Github/gasMD/examples/outputs/sample_3/posre.itp -v -heavyh -ff oplsaa -water none -lys -arg -asp -glu -his -ter -renum -merge all
