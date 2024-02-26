#!/bin/csh -X
source /discover/nobackup/projects/gmao/geos-it/mchattop/GPSRO_SPIRE_reanalysis/GEOSadas_5295/GEOSadas/install/bin/g5_modules
foreach file (`ls gdas1.1505*gpsro.tm00.bufr_d`)
   /discover/nobackup/projects/gmao/geos-it/mchattop/GPSRO_SPIRE_reanalysis/GEOSadas_5295/GEOSadas/install/bin/prepbysaid.x -r ${file} -o nocsmic_${file}
end

exit




