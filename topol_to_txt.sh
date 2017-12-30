grep "q +1.0" $1 > topol.top.temp
sed -e s/'q +1.0'//g -i.temp topol.top.temp
echo `sed 's/[^0-9]//g' topol.top.temp`  | sed 's/ /,/g' > topol.top.temp.temp
echo "select qRes=(i;dummy)" > pymol_temp
sed -e "s/dummy/$(cat topol.top.temp.temp)/" pymol_temp > topol.top_qRes.txt
rm *temp*
cat 0_topol.top_qRes.txt