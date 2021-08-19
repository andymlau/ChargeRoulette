source /usr/local/gromacs/bin/GMXRC
gmx pdb2gmx -f /home/andy/Github/gasMD/example/inputs/pdb2grnA..pdb-residue_depth.pdb -o /home/andy/Github/gasMD/example/output/sample_3/charge_set_3_out.pdb -v -heavyh -ff oplsaa -p /home/andy/Github/gasMD/example/output/sample_3/topol.top -i /home/andy/Github/gasMD/example/output/sample_3/posre.itp -water none -lys -arg -asp -glu -his -ter -renum -merge all
