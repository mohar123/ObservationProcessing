#!/bin/csh -x

#set in_dir = /discover/nobackup/projects/gmao/geos-it/mchattop/ROMEX/input/kom5/2022
set out_dir = /discover/nobackup/projects/gmao/obsdev/mchattop/GPSROdata/python3/km



cd /discover/nobackup/projects/gmao/obsdev/mchattop/GPSROdata/python3
foreach date_dir (`ls ${out_dir}`)
    ./cdaac2ncep.py ${date_dir} 6 km
end
mkdir -p ${out_dir}/km_gdas/
mv km_*.bufr ${out_dir}/km_gdas/
#exit

cd ${out_dir}/km_gdas/
foreach file (`ls km_*`)

   set yyyy = `echo $file | cut -c4-7`
   echo $yyyy
   set doy = `echo $file | cut -c9-11`
   echo $doy
   set doym1 = `echo "$doy - 1;" | /usr/bin/bc`
   echo $doy, $doym1
   set hh = `echo $file | cut -c13-14`
   set mm = `date -d "$doym1 days $yyyy-01-01" +"%m"`
   set dd = `date -d "$doym1 days $yyyy-01-01" +"%d"`
   echo ${dd},${mm}
   mv $file `echo $file | sed -n s/${yyyy}.${doy}_${hh}Z/${yyyy}${mm}${dd}.${hh}z/p`
end
exit

foreach file (`ls spirenasa*.bufr`)
   ls $file
   set yyyy = `echo $file | cut -c11-14`
   echo $yyyy
   set mm = `echo $file | cut -c15-16`
   echo $mm
   mkdir -p BUFR_spirenasa/${yyyy}/${mm} #mkdir and intermediate dir if they don't exist
   mv $file BUFR_spirenasa/${yyyy}/${mm}/
end



exit

