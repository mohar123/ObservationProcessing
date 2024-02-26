#!/bin/csh -x

set in_dir = new_COSMIC_bufr/pub/cosmic2021/level2/bfrPrf/
set out_dir = bfrPrf_Cp

#cd ${in_dir}

mv ${in_dir}/2015.??? ${out_dir}/

foreach date_dir (`ls ${out_dir}`)
   ./cdaac2ncep.py ${date_dir} 6 bfrPrf_Cp
end

foreach file (`ls bfrPrf_Cp_*`)

   set yyyy = `echo $file | cut -c11-14`
   echo $yyyy
   set doy = `echo $file | cut -c16-18`
   echo $doy
   set doym1 = `echo "$doy - 1;" | /usr/bin/bc`
   echo $doy, $doym1
   set hh = `echo $file | cut -c20-21`
   set mm = `date -d "$doym1 days $yyyy-01-01" +"%m"`
   set dd = `date -d "$doym1 days $yyyy-01-01" +"%d"`
   echo ${dd},${mm}
   mv $file `echo $file | sed -n s/${yyyy}.${doy}_${hh}Z/${yyyy}${mm}${dd}.${hh}z/p`
end

foreach file (`ls bfrPrf_Cp_*.bufr`)
   ls $file
   set yyyy = `echo $file | cut -c11-14`
   echo $yyyy
   set mm = `echo $file | cut -c15-16`
   echo $mm
   mkdir -p BUFR_Cp/${yyyy}/${mm} #mkdir and intermediate dir if they don't exist
   mv $file BUFR_Cp/${yyyy}/${mm}/
end

exit

