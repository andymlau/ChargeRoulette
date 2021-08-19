source /usr/local/gromacs/bin/GMXRC
gmx pdb2gmx -f /home/andy/Github/gasMD/example/inputs/pdb2grnA..pdb-residue_depth.pdb -o /home/andy/Github/gasMD/example/output/sample_1/charge_set_1_out.pdb -v -heavyh -ff oplsaa -p /home/andy/Github/gasMD/example/output/sample_1/topol.top -i /home/andy/Github/gasMD/example/output/sample_1/posre.itp -water none -lys -arg -asp -glu -his -ter -renum -merge all
