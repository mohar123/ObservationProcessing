! Date: Nov 10, 2015
! Isaac Moradi Isaac.Moradi@NOAA.GOV
!
! Writes input files into bufr format
! 


MODULE Write_Bufr
  USE datetime_module
  IMPLICIT NONE
CONTAINS


SUBROUTINE TOVS(     dir_outbufr,   &
                      sensor_id,      &
		      nobs,           &
		      nfov,           &
		      nchan,          &
                      year,           &
 		      month,          &
                      day,            &
                      hour,           &
                      minute,         &
                      second,         &
                      lat,            &
                      lon,            & 
                      eia,            &
                      fov,            &                      
                      Tb               )

  INTEGER(4), INTENT(IN) :: nobs, nfov, nchan
  REAL(8), DIMENSION(:), INTENT(IN) :: year, month, day, hour, minute, second
  REAL(8), DIMENSION(:), INTENT(IN) :: lat, lon, eia, fov
  REAL(8), INTENT(IN) :: tb(:,:)
  CHARACTER(LEN=*), INTENT(IN) :: sensor_id, dir_outbufr
  CHARACTER(LEN=400)  ::fname_outbufr

  INTEGER(4) :: iobs,iret, iunit ,ireadsb,ireadmg, icahn, ichan
  INTEGER(4), PARAMETER ::  narr=100
  INTEGER(8) :: idate
  REAL(8) :: arr(narr), brr(narr,350)
  INTEGER :: err_stat
  CHARACTER(LEN=100) :: bufrid, tbid
  CHARACTER(LEN=250) :: bufrtab_dir
  INTEGER(4) :: wmo_satellite_id, wmo_sensor_id
  INTEGER(4), PARAMETER :: bufrtab = 20, outbufr = 10
  REAL(4) :: solar_zenith_angle, source_azimuth_angle
  LOGICAL :: exist
  INTEGER(8) file_size, syntime, year1, month1, day1
  INTEGER ::  hour1
  REAL(8) :: dn,  datenum(nobs), min_datenum, max_datenum
  TYPE(datetime) :: dt, dt1
  LOGICAL :: obs_selec(nobs) 
  bufrtab_dir = './bufrtab'

  CALL WMO_ID(sensor_id, wmo_satellite_id, wmo_sensor_id)

  min_datenum = 1e6
  max_datenum = 0
  DO iobs=1,nobs
     hour1 = 6 * INT((hour(iobs) + 3) / 6.0)
     !print*, "hour", hour(iobs), hour1
     datenum(iobs) = date2num(datetime(INT(year(iobs)), INT(month(iobs)), &
                     INT(day(iobs)), hour1))
  ENDDO

  !if (INT(hour(iobs)) .GE. 22) dn = dn + 1
  min_datenum = minval(datenum)
  max_datenum = maxval(datenum)
  

  solar_zenith_angle = 10
  source_azimuth_angle = 10

  bufrid = 'NC021023'
  tbid = 'BRITCSTC'

  CALL DATELEN(10)
  
  ! In the case of missing values in time, min_datenum becomes a small number
  IF ((max_datenum - min_datenum) .GT. 2) THEN
     min_datenum = max_datenum - 1.0
  ENDIF

  DO dn=min_datenum, max_datenum, 0.25
    dt = num2date(dn)
    fname_outbufr = TRIM(dir_outbufr)//dt%strftime("/%Y/")//dt%strftime("%m/")//dt%strftime("%d/")
    CALL system("mkdir -p "//TRIM(fname_outbufr))
    fname_outbufr = TRIM(fname_outbufr)//"fcdr_"//dt%strftime("%Y%m%d%H")//".bufr"
    print*, "writing to ... ", fname_outbufr    

    ! Open a file - append to the end of the file if exists
    INQUIRE(FILE=TRIM(fname_outbufr), EXIST=exist, SIZE=file_size)
    IF (exist) THEN 
        OPEN(UNIT=outbufr, FILE=TRIM(fname_outbufr), STATUS="old", &
                        POSITION="append", ACTION="write")
    ELSE
       OPEN(UNIT=outbufr, FILE=TRIM(fname_outbufr), STATUS="NEW", ACTION="write")
    ENDIF

    ! Open bufr table
    OPEN(UNIT=bufrtab, FILE=TRIM(bufrtab_dir)//'/'//'bufrtab.021', ACTION="read")

    ! Open bufr file
    IF (exist) THEN
      CALL OPENBF(outbufr,'APN', bufrtab)   ! Append to existing file
    ELSE
      CALL OPENBF(outbufr,'OUT', bufrtab)  ! Creat a new file
    ENDIF

    obs_selec = .FALSE.
    ! 0.125 = 3 hours
    WHERE ((datenum .GT. (dn-0.125)) .OR. (datenum .LT. (dn + 0.125)))
          obs_selec = .TRUE.
    ENDWHERE

    !READ(TRIM(dt%strftime("%Y%m%d%H")), '(i)')  idate 
    DO iobs=1,nobs
       IF (obs_selec(iobs) .EQ. .FALSE.) cycle
       dt1=num2date(datenum(iobs))
       !print*, dt1%isoformat(),  year(iobs), month(iobs), day(iobs),  hour(iobs), minute(iobs)

       idate=  year(iobs) * 1000000 + month(iobs) * 10000 + &
               day(iobs) * 100 + hour(iobs)
       
       arr(  1) = year(iobs)  
       arr(  2) = month(iobs) 
       arr(  3) = day(iobs)   
       arr(  4) = hour(iobs)  
       arr(  5) = minute(iobs)
       arr(  6) = second(iobs)
       arr(  7) = lat(iobs) 
       arr(  8) = lon(iobs)
       arr(  9) =  wmo_satellite_id      ! SAID 
       arr( 10) =  wmo_sensor_id         ! SIID             
       arr( 11) =  fov(iobs)             ! FOVN         
       arr( 12) =  eia(iobs)             ! SAZA changed it from 13 to 12 and tested it          
       arr( 13) = eia(iobs)              ! Satellite azimuth angle             
       arr( 14) =  solar_zenith_angle    ! SOZA                                
       arr( 15) =  source_azimuth_angle  ! SOLAZI          

       brr=99
       DO ichan=1,nchan
          brr(1,ichan) = ichan                                
          brr(2,ichan) =tb(iobs, ichan)         
       ENDDO
       
       ! THIS SUBROUTINE OPENS AND INITIALIZES A NEW BUFR MESSAGE WITHIN MEMORY.                
       CALL OPENMB(outbufr, TRIM(bufrid), idate)
       ! WRITE DATA VALUES TO INTERNAL SUBSET
       CALL UFBSEQ(outbufr, arr, narr, 1, iret, TRIM(bufrid))   ! allocate delayed replication space
       CALL UFBSEQ(outbufr, brr, narr, nchan, iret, TRIM(tbid)) ! fill in data values
       CALL WRITCP(outbufr)
   ENDDO
   CALL CLOSBF(outbufr)
   Close(outbufr)
  
 ENDDO   
END SUBROUTINE TOVS

SUBROUTINE AQUA_AMSU(     dir_outbufr,   &
                      sensor_id,      &
		      nobs,           &
		      nfov,           &
		      nchan,          &
                      year,           &
 		      month,          &
                      day,            &
                      hour,           &
                      minute,         &
                      second,         &
                      lat,            &
                      lon,            & 
                      eia,            &
                      fov,            &                      
                      Tb               )

  INTEGER(4), INTENT(IN) :: nobs, nfov, nchan
  REAL(8), DIMENSION(:), INTENT(IN) :: year, month, day, hour, minute, second
  REAL(8), DIMENSION(:), INTENT(IN) :: lat, lon, eia, fov
  REAL(8), INTENT(IN) :: tb(:,:)
  CHARACTER(LEN=*), INTENT(IN) :: sensor_id, dir_outbufr
  CHARACTER(LEN=400)  ::fname_outbufr

  

  INTEGER(4) :: iobs,iret, iunit ,ireadsb,ireadmg, icahn, ichan
  INTEGER(4), PARAMETER ::  narr=100, bufr_header_size = 25
  INTEGER(8) :: idate
  REAL(8) :: arr(narr), brr(narr,350), bufr_aquaspot(bufr_header_size)
  INTEGER :: err_stat
  CHARACTER(LEN=100) :: bufrid, tbid
  CHARACTER(LEN=250) :: bufrtab_dir
  INTEGER(4) :: wmo_satellite_id, wmo_sensor_id
  INTEGER(4), PARAMETER :: bufrtab = 20, outbufr = 10
  REAL(4) :: solar_zenith_angle, source_azimuth_angle
  LOGICAL :: exist
  INTEGER(8) file_size, syntime, year1, month1, day1
  INTEGER ::  hour1, status
  REAL(8) :: dn,  datenum(nobs), min_datenum, max_datenum
  TYPE(datetime) :: dt, dt1
  LOGICAL :: obs_selec(nobs), write_idate 
        integer, parameter                 :: n_airs_channels        = 281
        character(len=8)                          :: sequence_airschan
  sequence_airschan = 'SCBTSEQN'

  bufrtab_dir = './bufrtab'

  CALL WMO_ID(sensor_id, wmo_satellite_id, wmo_sensor_id)

  min_datenum = 1e6
  max_datenum = 0
  DO iobs=1,nobs
     hour1 = 6 * INT((hour(iobs) + 3) / 6.0)
     !print*, "hour", hour(iobs), hour1
     datenum(iobs) = date2num(datetime(INT(year(iobs)), INT(month(iobs)), &
                     INT(day(iobs)), hour1))
  ENDDO

  !if (INT(hour(iobs)) .GE. 22) dn = dn + 1
  min_datenum = minval(datenum)
  max_datenum = maxval(datenum)
  
  solar_zenith_angle = 10
  source_azimuth_angle = 10
  bufrid = 'NC021249'
  !bufrid = 'NC021250'
  tbid = 'BRITCSTC'

  CALL DATELEN(10)
  
  ! In the case of missing values in time, min_datenum becomes a small number
  IF ((max_datenum - min_datenum) .GT. 2) THEN
     min_datenum = max_datenum - 1.0
  ENDIF

  DO dn=min_datenum, max_datenum, 0.25
    dt = num2date(dn)
    fname_outbufr = TRIM(dir_outbufr)//dt%strftime("/%Y/")//dt%strftime("%m/")//dt%strftime("%d/")
    CALL system("mkdir -p "//TRIM(fname_outbufr))
    fname_outbufr = TRIM(fname_outbufr)//"fcdr_"//dt%strftime("%Y%m%d%H")//".bufr"
    print*, fname_outbufr    

    ! Open a file - append to the end of the file if exists
    INQUIRE(FILE=TRIM(fname_outbufr), EXIST=exist, SIZE=file_size)
    IF (exist) THEN 
        OPEN(UNIT=outbufr, FILE=TRIM(fname_outbufr), STATUS="old", &
                        POSITION="append", ACTION="write")
    ELSE
       OPEN(UNIT=outbufr, FILE=TRIM(fname_outbufr), STATUS="NEW", ACTION="write")
    ENDIF

    ! Open bufr table
    OPEN(UNIT=bufrtab, FILE=TRIM(bufrtab_dir)//'/'//'bufrtab.021', ACTION="read")

    ! Open bufr file
    IF (exist) THEN
      CALL OPENBF(outbufr,'APN', bufrtab)   ! Append to existing file
    ELSE
      CALL OPENBF(outbufr,'OUT', bufrtab)  ! Creat a new file
    ENDIF

    obs_selec = .FALSE.
    ! 0.125 = 3 hours
    WHERE ((datenum .GT. (dn-0.125)) .OR. (datenum .LT. (dn + 0.125)))
          obs_selec = .TRUE.
    ENDWHERE


    write_idate = .TRUE.

    !READ(TRIM(dt%strftime("%Y%m%d%H")), '(i)')  idate 
    DO iobs=1,nobs
       IF (obs_selec(iobs) .EQ. .FALSE.) cycle
       dt1=num2date(datenum(iobs))
       !print*, dt1%isoformat(),  year(iobs), month(iobs), day(iobs),  hour(iobs), minute(iobs)

       idate=  year(iobs) * 1000000 + month(iobs) * 10000 + &
               day(iobs) * 100 + hour(iobs)

      bufr_aquaspot = 0
      bufr_aquaspot( 1) = wmo_satellite_id
      bufr_aquaspot( 6) = 45 !solar_zenith
      bufr_aquaspot( 7) = 45 !solar_azimuth

      CALL OPENMB(outbufr, TRIM(bufrid), idate)
      call ufbseq(outbufr, bufr_aquaspot, bufr_header_size, 1, iret, 'SPITSEQN')


       arr(  1) = wmo_sensor_id
       arr(  2) = year(iobs)  
       arr(  3) = month(iobs) 
       arr(  4) = day(iobs)   
       arr(  5) = hour(iobs)  
       arr(  6) = minute(iobs)
       arr(  7) = second(iobs)
       arr(  8) = lat(iobs) 
       arr(  9) = lon(iobs)
       arr( 10) =  eia(iobs)   
       arr( 11) = 0 ! azimuth
       arr( 12) = fov(iobs)

       brr=99
       DO ichan=1,nchan
          brr(1,ichan) = ichan                                
          brr(2, ichan) = 0
          brr(3, ichan) = 0
          brr(4,ichan) =tb(iobs, ichan)         
       ENDDO

       ! WRITE DATA VALUES TO INTERNAL SUBSET
       CALL UFBSEQ(outbufr, arr, narr, 1, iret, 'AMSUSPOT') 
       !call drfini(outbufr, n_airs_channels, 1,'('//sequence_airschan//')')
       CALL UFBSEQ(outbufr, brr, narr, nchan, iret, 'AMSUCHAN') ! fill in data values
       CALL WRITCP(outbufr)
   ENDDO
   CALL CLOSBF(outbufr)
   Close(outbufr)
  
 ENDDO   
END SUBROUTINE AQUA_AMSU

SUBROUTINE WMO_ID(sensor_id,        &
                  said,             &  ! wmo_satellite_id
                  siid              )  ! wmo_sensor_id     

      CHARACTER(LEN=*), INTENT(IN) :: sensor_id
      INTEGER, INTENT(OUT) :: said, siid

      CHARACTER(LEN=50) :: asat, isat
      INTEGER :: ind
    
      ind = SCAN(sensor_id, "_")
      asat = sensor_id(1:ind-1)   ! instrument
      isat = sensor_id(ind+1:)    ! satellite

      if(asat=='hirs2') then
         if(isat=='n14')then;said=205;siid=605;endif
      elseif(asat=='hirs3') then
         if(isat=='n15')then;said=206;siid=606;endif
         if(isat=='n16')then;said=207;siid=606;endif
         if(isat=='n17')then;said=208;siid=606;endif
         if(isat=='n18')then;said=209;siid=606;endif
         if(isat=='n19')then;said=223;siid=606;endif
      elseif(asat=='hirs4') then
         if(isat=='n18')then;said=209;siid=607;endif
         if(isat=='n19')then;said=223;siid=607;endif
         if(isat=='metop-a')then;said=004;siid=607;endif
         if(isat=='metop-b')then;said=003;siid=607;endif
      elseif(asat=='goes'.or.asat(1:4)=='sndr') then
         if(isat=='g06')then;said=250;siid=626;endif
         if(isat=='g07')then;said=251;siid=626;endif
         if(isat=='g08')then;said=252;siid=626;endif
         if(isat=='g09')then;said=253;siid=626;endif
         if(isat=='g10')then;said=254;siid=626;endif
         if(isat=='g11')then;said=255;siid=626;endif
         if(isat=='g12')then;said=256;siid=626;endif
         if(isat=='g13')then;said=257;siid=626;endif
         if(isat=='g14')then;said=258;siid=626;endif
         if(isat=='g15')then;said=259;siid=626;endif
      elseif(asat=='amsua') then
         if(isat=='n15')then;said=206;siid=570;endif
         if(isat=='n16')then;said=207;siid=570;endif
         if(isat=='n17')then;said=208;siid=570;endif
         if(isat=='n18')then;said=209;siid=570;endif
         if(isat=='n19')then;said=223;siid=570;endif
         if(isat=='metop-a')then;said=004;siid=570;endif
         if(isat=='metop-b')then;said=003;siid=570;endif
         if(isat=='aqua')then;said=784;siid=570;endif
      elseif(asat=='amsub') then
         if(isat=='n15')then;said=206;siid=574;endif
         if(isat=='n16')then;said=207;siid=574;endif
         if(isat=='n17')then;said=208;siid=574;endif
      elseif(asat=='msu') then
         if(isat=='n14')then;said=205;siid=623;endif
      elseif(asat=='mhs') then
         if(isat=='n18')then;said=209;siid=203;endif
         if(isat=='n19')then;said=223;siid=203;endif
         if(isat=='metop-a')then;said=004;siid=203;endif
         if(isat=='metop-b')then;said=003;siid=203;endif
      elseif(asat=='airs') then
         if(isat=='aqua')then;said=784;siid=420;endif
      elseif(asat=='iasi') then
         if(isat=='metop-a')then;said=004;siid=221;endif
         if(isat=='metop-b')then;said=003;siid=221;endif
      elseif(asat=='atms') then
         if(isat=='npp')then;said=224;siid=621;endif
      elseif(asat=='cris') then
         if(isat=='npp')then;said=224;siid=620;endif
      elseif(asat(1:5)=='ssmis') then
         if(isat=='f15')then;said=248;siid=0;endif
         if(isat=='f16')then;said=249;siid=0;endif
         if(isat=='f17')then;said=285;siid=0;endif
         if(isat=='f18')then;said=286;siid=0;endif
      elseif(asat=='seviri') then
         if(isat=='m01')then;said=058;siid=207;endif
         if(isat=='m02')then;said=059;siid=207;endif
         if(isat=='m03')then;said=050;siid=207;endif
         if(isat=='m04')then;said=051;siid=207;endif
         if(isat=='m05')then;said=052;siid=207;endif
         if(isat=='m06')then;said=053;siid=207;endif
         if(isat=='m07')then;said=054;siid=207;endif
         if(isat=='m08')then;said=055;siid=207;endif
         if(isat=='m09')then;said=056;siid=207;endif
         if(isat=='m10')then;said=057;siid=207;endif
      else
         print*,'no code found for ',asat,isat
         STOP
      endif
      return

END SUBROUTINE WMO_ID


END MODULE Write_Bufr
