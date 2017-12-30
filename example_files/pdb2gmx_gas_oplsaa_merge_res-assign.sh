#To be used with pdb2gmx_auto_assign.sh script

source /usr/local/gromacs/bin/GMXRC

gmx pdb2gmx -f 4JFO.pdb -o 0_out.pdb -v -heavyh -ff oplsaa -p 0_topol.top -i 0_posre.itp -water none -lys -arg -asp -glu -his -ter

echo "pdb2gmx finished"
