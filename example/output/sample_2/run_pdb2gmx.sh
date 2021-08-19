source /usr/local/gromacs/bin/GMXRC
gmx pdb2gmx -f /home/andy/Github/gasMD/example/inputs/pdb2grnA..pdb-residue_depth.pdb -o /home/andy/Github/gasMD/example/output/sample_2/charge_set_2_out.pdb -v -heavyh -ff oplsaa -p /home/andy/Github/gasMD/example/output/sample_2/topol.top -i /home/andy/Github/gasMD/example/output/sample_2/posre.itp -water none -lys -arg -asp -glu -his -ter -renum -merge all
