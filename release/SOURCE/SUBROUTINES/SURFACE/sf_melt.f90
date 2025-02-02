
! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
! SUBROUTINE SF_MELT----------------------------------------------------
!
! Purpose : Calculates surface melting (snow and sea-ice) and increments
!           surface fluxes to satisfy energy balance.
!           Sub-surface snowmelt is calculated and snowdepth incremented
!           by melt and sublimation in P251.
!-----------------------------------------------------------------------
SUBROUTINE sf_melt (                                              &
 row_length,rows,points,pts_index                                 &
,tile_index,tile_pts,ltimer,fld_sea                               &
,alpha1,ashtf_prime,dtrdz_1                                       &
,resft,rhokh_1,tile_frac,timestep,GAMMA                           &
,ei_tile,fqw_1,ftl_1,fqw_tile,ftl_tile                            &
,tstar_tile,snow_tile,snowdepth                                   &
,melt_tile                                                        &
 )


USE c_r_cp
USE c_lheat
USE c_0_dg_c

USE switches, ONLY :                                              &
 frac_snow_subl_melt

USE rad_param, ONLY :                                             &
 maskd

USE snow_param, ONLY :                                            &
 rho_snow_const

USE parkind1, ONLY: jprb, jpim
USE yomhook, ONLY: lhook, dr_hook

use fomod, only: softmin, softmax !Luke
IMPLICIT NONE
!real, external :: tiny !Jupp

INTEGER                                                           &
 row_length                                                       &
                      ! IN Number of X points?
,rows                                                             &
                      ! IN Number of Y points?
,points                                                           &
                      ! IN Total number of points.
,pts_index(points)                                                &
                      ! IN Index of points.
,tile_index(points)                                               &
!                           ! IN Index of tile points.
,tile_pts             ! IN Number of tile points.

LOGICAL                                                           &
 ltimer
                      ! IN Logical for TIMER.

 REAL                                                             &
 fld_sea(row_length,rows)                                         &
!                           ! IN Fraction of land or sea.
,alpha1(points)                                                   &
!                           ! IN Gradients of saturated specific
!                           !    humidity with respect to temp.
!                           !    between the bottom model layer
!                           !    and surface.
,ashtf_prime(points)                                              &
!                           ! IN Adjusted SEB coefficient
,dtrdz_1(row_length,rows)                                         &
!                           ! IN -g.dt/dp for surface layer
,resft(points)                                                    &
                       !IN Resistance factor.
,rhokh_1(points)                                                  &
!                           ! IN Surface exchange coefficient.
,tile_frac(points)                                                &
!                           ! IN Tile fractions.
,timestep                                                         &
                      ! IN Timestep (sec).
,GAMMA                ! IN implicit weight in level 1

REAL                                                              &
 ei_tile(points)                                                  &
!                           ! INOUT Sublimation for tile (kg/m2/s)
,fqw_1(row_length,rows)                                           &
!                           ! INOUT GBM surface moisture flux (kg/m2/s).
,ftl_1(row_length,rows)                                           &
!                           ! INOUT GBM surface sens. heat flux (W/m2).
,fqw_tile(points)                                                 &
!                           ! INOUT FQW for tile.
,ftl_tile(points)                                                 &
!                           ! INOUT FTL for tile.
,tstar_tile(points)                                               &
!                           ! INOUT Tile surface temperatures (K).
,snow_tile(points)                                                &
!                           ! INOUT Lying snow on tile (kg/m2).
,snowdepth(points)
!                           ! INOUT Depth of snow on tile (m).

REAL                                                              &
 melt_tile(points)
!                           ! OUT Surface snowmelt on tiles (kg/m2/s).

real smk
!  External routines called :-
EXTERNAL timer


REAL                                                              &
 dfqw                                                             &
                      ! Moisture flux increment.
,dftl                                                             &
                      ! Sensible heat flux increment.
,dtstar                                                           &
                      ! Surface temperature increment.
,lcmelt                                                           &
                      ! Temporary in melt calculations.
,lsmelt                                                           &
                      ! Temporary in melt calculations.
,rhokh1_prime                                                     &
                      ! Modified forward time-weighted
!                           ! transfer coefficient.
,snow_max                                                         &
                      ! Snow available for melting.
,snow_density                                                     &
                      ! Density of snow on input
,tstarmax             ! Maximum gridbox mean surface temperature
!                           ! at sea points with ice.
INTEGER                                                           &
 i,j                                                              &
                      ! Loop counter - full horizontal field.
,k                                                                &
                      ! Loop counter - tile field
,l                                                                &
                      ! Loop counter - land field.
,n                    ! Loop counter - tile index.

INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
REAL(KIND=jprb)               :: zhook_handle

IF (lhook) CALL dr_hook('SF_MELT',zhook_in,zhook_handle)

IF (ltimer) THEN
! DEPENDS ON: timer
CALL timer('SFMELT  ',3)
END IF

melt_tile(:) = 0.

!-----------------------------------------------------------------------
!  Melt snow on tile if TSTAR_TILE is greater than TM.
!-----------------------------------------------------------------------
!Jupp
!$TAF LOOP = PARALLEL
DO k=1,tile_pts
  l = tile_index(k)
  j=(pts_index(l)-1)/row_length + 1
  i = pts_index(l) - (j-1)*row_length
  IF (snowdepth(l) > SQRT(TINY(1.0)) ) THEN
    snow_density = snow_tile(l) / snowdepth(l)
  ELSE
    snow_density = rho_snow_const
  ENDIF
!  snow_max = MAX( 0.0, snow_tile(l) - ei_tile(l)*timestep )

smk = 50. / (1.+ abs(    snow_tile(l)    )+abs(   ei_tile(l)*timestep      ) ) 

  snow_max = softMAX( 0.0, snow_tile(l) - ei_tile(l)*timestep, smk) !Luke

!  write(*,*) 'sf_melt line 170: ',0.0,snow_tile(l) - ei_tile(l)*timestep
  IF ( snow_max.gt.0.0 .AND. tstar_tile(l).gt.tm ) THEN
    rhokh1_prime = 1. / ( 1. / rhokh_1(l)                         &
                       + GAMMA*dtrdz_1(i,j) )
    lcmelt = (cp + lc*alpha1(l)*resft(l))*rhokh1_prime            &
             + ashtf_prime(l)
    lsmelt = lcmelt + lf*alpha1(l)*rhokh1_prime
    IF (frac_snow_subl_melt == 1) THEN
!      dtstar = - MIN( (tstar_tile(l) - tm) *                      &
!               (1.0 - EXP(-maskd*snow_max/snow_density)),         &
!               lf*snow_max / (lcmelt*timestep) )



smk = 50. / (1.+ abs((tstar_tile(l) - tm) *                      &
               (1.0 - EXP(-maskd*snow_max/snow_density))) +abs(lf*snow_max / (lcmelt*timestep)) ) 

      dtstar = - softMIN( (tstar_tile(l) - tm) *                      &
               (1.0 - EXP(-maskd*snow_max/snow_density)),         &
               lf*snow_max / (lcmelt*timestep), smk )                !Luke




!    write(*,*) 'sf_melt line 184:'  ,(tstar_tile(l) - tm) *                      &
!               (1.0 - EXP(-maskd*snow_max/snow_density)),         &
!               lf*snow_max / (lcmelt*timestep)
    ELSE
!      dtstar = - MIN( tstar_tile(l) - tm ,                        &
!                      lf*snow_max / (lcmelt*timestep) )

smk = 50. / (1.+ abs(   tstar_tile(l) - tm      )+abs(    lf*snow_max / (lcmelt*timestep)    ) ) 


      dtstar = - softMIN( tstar_tile(l) - tm ,                        &
                      lf*snow_max / (lcmelt*timestep), smk )         !Luke




!      write(*,*) 'sf_melt line 192: ',tstar_tile(l) - tm ,                        &
!                      lf*snow_max / (lcmelt*timestep)
    END IF
    tstar_tile(l) = tstar_tile(l) + dtstar
    melt_tile(l) = - lsmelt*dtstar / lf
    dftl = cp*rhokh1_prime*dtstar
    dfqw = alpha1(l)*resft(l)*rhokh1_prime*dtstar
    ftl_tile(l) = ftl_tile(l) + dftl
    fqw_tile(l) = fqw_tile(l) + dfqw
    ei_tile(l) = ei_tile(l) + dfqw
!-----------------------------------------------------------------------
!  Update gridbox-mean quantities
!-----------------------------------------------------------------------
    dftl = tile_frac(l)*dftl
    dfqw = tile_frac(l)*dfqw
    ftl_1(i,j) = ftl_1(i,j) + fld_sea(i,j)*dftl
    fqw_1(i,j) = fqw_1(i,j) + fld_sea(i,j)*dfqw
  END IF
END DO

IF (ltimer) THEN
! DEPENDS ON: timer
CALL timer('SFMELT  ',4)
END IF

IF (lhook) CALL dr_hook('SF_MELT',zhook_out,zhook_handle)
RETURN
END SUBROUTINE sf_melt
