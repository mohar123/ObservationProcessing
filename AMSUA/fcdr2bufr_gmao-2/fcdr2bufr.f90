! Date: Nov 10, 2015
! Isaac Moradi Isaac.Moradi@NOAA.GOV
!
! Main program to write input NetCDF files into bufr format
!

PROGRAM FCDR_TO_BUFR

  USE Write_Bufr
  USE Read_Data

  IMPLICIT NONE

  INTEGER(KIND=4) :: nobs, nscan, nfov, nchan
  REAL(8), DIMENSION(:), ALLOCATABLE :: year, month, day, hour, minute, second
  REAL(8), DIMENSION(:), ALLOCATABLE :: year1, month1, day1, hour1, minute1, second1
  REAL(8), DIMENSION(:), ALLOCATABLE :: lat, lon, eia, fov
  REAL(8), ALLOCATABLE :: tb(:,:), tb_window(:,:)
  CHARACTER(LEN=20) :: sensor_id
  CHARACTER(LEN=250) :: fname_netcdf, fname_netcdf1, dir_outbufr

  fname_netcdf = "/data/users/imoradi/workspace/fcdr_nwp_impact/data/fcdr/"//&
                 "metop-a/2008/NSS.MHSX.M2.D08004.S0917.E1059.B0627576.SV.NC"
  CALL GET_COMMAND_ARGUMENT(1, fname_netcdf)
  CALL GET_COMMAND_ARGUMENT(2, fname_netcdf1)
  CALL GET_COMMAND_ARGUMENT(3, dir_outbufr)
  CALL GET_COMMAND_ARGUMENT(4, sensor_id)


  PRINT*, "In: ", fname_netcdf
  PRINT*, "Out: ", dir_outbufr

  IF  (INDEX(sensor_id,"amsua") > 0) THEN
    Call AMSUA_FCDR(fname_netcdf1,        &                      
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
                      Tb              )  
    IF  (INDEX(fname_netcdf, "aqua") > 0) THEN
      Call AMSUA_AQUA_4CHAN(fname_netcdf,        &                      
                      fov,            &
                      Tb_window       )  
    ELSE
      Call AMSUA_4CHAN(fname_netcdf,        &                      
                      nobs,           &
                      nfov,           &
                      nchan,          &
                      year1,           &
                      month1,          &
                      day1,            &
                      hour1,           &
                      minute1,         &
                      second1,         &
                      !lat,            &
                      !lon,            &
                      !eia,            &
                      fov,            &
                      Tb_window       )  
    END IF
    ! Put the data from window channels into Tb array
    Tb(:,1:3) = Tb_window(:,1:3)
    Tb(:,15) = Tb_window(:,4)
    
  ENDIF
  
  IF(INDEX(fname_netcdf, "aqua") > 0) THEN
        CALL AQUA_AMSU(dir_outbufr, & 
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
                      Tb              )
  ELSE
       CALL TOVS(dir_outbufr, & 
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
                      Tb              )
  ENDIF
END PROGRAM FCDR_TO_BUFR
