
! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************

!    SUBROUTINE SOILMC-------------------------------------------------

! Description:
!     Diagnoses the soil moisture in a layer at the surface

!**********************************************************************

SUBROUTINE soilmc ( npnts,nshyd,soil_pts,soil_index,              &
                    dz,sthu,v_sat,v_wilt,smc )

USE c_densty

USE soil_param, ONLY :                                            &
 zsmc                 ! Depth of layer for soil moisture
!                           ! diagnostic (m).

USE parkind1, ONLY: jprb, jpim
USE yomhook, ONLY: lhook, dr_hook
IMPLICIT NONE

INTEGER                                                           &
 npnts                                                            &
                      ! IN Number of gridpoints.
,nshyd                                                            &
                      ! IN Number of soil moisture levels.
,soil_pts                                                         &
                      ! IN Number of soil points.
,soil_index(npnts)    ! IN Array of soil points.

REAL                                                              &
 dz(nshyd)                                                        &
                      ! IN Thicknesses of the soil layers (m).
,sthu(npnts,nshyd)                                                &
                      ! IN Unfrozen soil moisture content of
!                           !    each layer as a frac. of saturation.
,v_sat(npnts,nshyd)                                               &
                      ! IN Volumetric soil moisture conc. at
!                           !    saturation (m3 H2O/m3 soil).
,v_wilt(npnts,nshyd)  ! IN Volumetric soil moisture conc. below
!                           !    which stomata close (m3 H2O/m3 soil).

REAL                                                              &
 smc(npnts)           ! OUT Soil moisture (kg/m2).

REAL                                                              &
 z1,z2                ! WORK Depth of the top and bottom of the
!                           !      soil layers (m).

INTEGER                                                           &
 i,j,n                ! WORK Loop counters

INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
REAL(KIND=jprb)               :: zhook_handle


IF (lhook) CALL dr_hook('SOILMC',zhook_in,zhook_handle)
DO i=1,npnts
  smc(i) = 0.
END DO

z2 = 0.
!Jupp
!$TAF LOOP = SEQUENTIAL
!Jupp
DO n=1,nshyd
  z1 = z2
  z2 = z2 + dz(n)
  IF ( z2 <  zsmc ) THEN
!CDIR NODEP
!Jupp
!$TAF LOOP = PARALLEL
!Jupp
    DO j=1,soil_pts
      i = soil_index(j)
      smc(i) = smc(i) + rho_water * dz(n) *                       &
                           ( sthu(i,n)*v_sat(i,n) - v_wilt(i,n) )
    END DO
  ELSE IF ( z2 >= zsmc .AND. z1 <  zsmc ) THEN
!CDIR NODEP
!Jupp
!$TAF LOOP = PARALLEL
!Jupp
    DO j=1,soil_pts
      i = soil_index(j)
      smc(i) = smc(i) + rho_water * ( zsmc - z1 ) *               &
                           ( sthu(i,n)*v_sat(i,n) - v_wilt(i,n) )
    END DO
  END IF
END DO

IF (lhook) CALL dr_hook('SOILMC',zhook_out,zhook_handle)
RETURN
END SUBROUTINE soilmc
