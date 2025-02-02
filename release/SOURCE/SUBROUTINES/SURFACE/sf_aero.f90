
! *****************************COPYRIGHT*******************************
! (c) CROWN COPYRIGHT 2000, Met Office, All Rights Reserved.
! Please refer to file $UMDIR/vn$VN/copyright.txt for further details
! *****************************COPYRIGHT*******************************
!   SUBROUTINE SF_AERO------------------------------------------------

!  Purpose: Calculate coefficients required for aerosol code

!  Suitable for Single Column use.

!  Documentation: UM Documentation Paper No 24, section P243.
!                 See especially sub-section (ix).
!---------------------------------------------------------------------

! Arguments :-
SUBROUTINE sf_aero (                                              &
 row_length,rows,land_pts,ntiles,land_index,tile_index,tile_pts,  &
 ltimer,l_dust,                                                   &
 flandg,tile_frac,pstar,rhostar,tstar,vshr_land,vshr_ssi,         &
 cd_ssi,ch_ssi,cd_std,ch_tile,rhokh_gb,                           &
 rho_aresist,aresist,resist_b,rho_aresist_tile,aresist_tile,      &
 resist_b_tile,r_b_dust,cd_std_dust,rhokh_mix                     &
 )


USE c_dust_ndiv

USE parkind1, ONLY: jprb, jpim
USE yomhook, ONLY: lhook, dr_hook
IMPLICIT NONE

INTEGER, INTENT(IN) ::                                            &
 row_length                                                       &
                       ! IN Number of X points?
,rows                                                             &
                       ! IN Number of Y points?
,land_pts                                                         &
                       ! IN No of land points being processed.
,ntiles                                                           &
                       ! IN Number of land tiles per land point.
,land_index(land_pts)                                             &
                       ! IN Index of land points.
,tile_index(land_pts,ntiles)                                      &
                       ! IN Index of tile points.
,tile_pts(ntiles)      ! IN Number of tile points.


LOGICAL, INTENT(IN) ::                                            &
 ltimer                                                           &
                       ! IN Logical for TIMER.
,l_dust                ! IN switch for mineral dust


REAL, INTENT(IN) ::                                               &
 flandg(row_length,rows)                                          &
                       ! IN Land fraction on all tiles.
,tile_frac(land_pts,ntiles)                                       &
                       ! IN Tile fractions.
,pstar(row_length,rows)                                           &
                       ! IN Surface pressure (Pascals).
,rhostar(row_length,rows)                                         &
                       ! IN Surface air density
,tstar(row_length,rows)                                           &
                       ! IN Gridbox Mean Surface Temperature (K)
,vshr_land(row_length,rows)                                       &
                       ! IN Magnitude of land sfc-to-lowest-level
!                            !    wind shear
,vshr_ssi(row_length,rows)                                        &
                       ! IN Mag. of mean sea sfc-to-lowest-level
!                            !    wind shear
,cd_ssi(row_length,rows)                                          &
                       ! IN Bulk transfer coefficient for
!                            !      momentum over sea mean.
,ch_ssi(row_length,rows)                                          &
                       ! IN Bulk transfer coefficient for heat
!                            !    and/or moisture over sea mean.
,cd_std(land_pts,ntiles)                                          &
                       ! IN Local drag coefficient for calc
!                            !    of interpolation coefficient
,ch_tile(land_pts,ntiles)                                         &
                       ! IN Transfer coefficient for heat and
!                            !    moisture
,rhokh_gb(row_length,rows)
                       ! IN Grid-box surface exchange
!                            !     coefficients


!  Output variables.

REAL, INTENT(OUT) ::                                              &
 rho_aresist(row_length,rows)                                     &
                       ! OUT RHOSTAR*CD_STD*VSHR  for SCYCLE
,aresist(row_length,rows)                                         &
                       ! OUT 1/(CD_STD*VSHR)      for SCYCLE
,resist_b(row_length,rows)                                        &
                       ! OUT (1/CH-1/CD_STD)/VSHR for SCYCLE
,rho_aresist_tile(land_pts,ntiles)                                &
                       ! OUT RHOSTAR*CD_STD*VSHR on land tiles
,aresist_tile(land_pts,ntiles)                                    &
                       ! OUT 1/(CD_STD*VSHR) on land tiles
,resist_b_tile(land_pts,ntiles)                                   &
                       ! OUT (1/CH-1/CD_STD)/VSHR on land tiles
,r_b_dust(row_length,rows,ndiv)                                   &
                       ! OUT surf layer res for dust
,cd_std_dust(row_length,rows)                                     &
                       ! OUT Bulk transfer coef. for momentum,
!                            !     excluding orographic effects
,rhokh_mix(row_length,rows)
!                            ! OUT Exchange coeffs for moisture.


! Local workspace
REAL ::                                                           &
 rho_aresist_land(row_length,rows)                                &
                       ! Land mean of rho_aresist_tile
,vshr(row_length,rows) ! friction velocity passed to DUSTRESB

! Local scalars.
INTEGER ::                                                        &
 i,j                                                              &
             ! Loop counter (horizontal field index).
,k                                                                &
             ! Loop counter (tile field index).
,l                                                                &
             ! Loop counter (land point field index).
,n                                                                &
             ! Loop counter (tile index).
,idiv        ! Loop counter (dust division).

INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
REAL(KIND=jprb)               :: zhook_handle

!-----------------------------------------------------------------------
! External routines called:
!-----------------------------------------------------------------------
EXTERNAL timer, dustresb


IF (lhook) CALL dr_hook('SF_AERO',zhook_in,zhook_handle)
IF (ltimer) THEN
! DEPENDS ON: timer
  CALL timer('SFAERO  ',3)
END IF


!-----------------------------------------------------------------------
!!  Calculate surface layer resistance for mineral dust
!-----------------------------------------------------------------------
DO j=1,rows
  DO i=1,row_length
    rho_aresist(i,j) = 0.
    rho_aresist_land(i,j)=0.0
    aresist(i,j) = 0.
    resist_b(i,j) = 0.
  END DO
END DO

DO j=1,rows
  DO i=1,row_length
    IF ( flandg(i,j) < 1.0 ) THEN
      rho_aresist(i,j) = rhostar(i,j)*cd_ssi(i,j)*vshr_ssi(i,j)
      aresist(i,j) =  1. / (cd_ssi(i,j) * vshr_ssi(i,j))
      resist_b(i,j)= (cd_ssi(i,j)/ch_ssi(i,j) - 1.0) *            &
                      aresist(i,j)
    END IF
  END DO
END DO

! Land tiles
DO n=1,ntiles
  DO l=1,land_pts
    rho_aresist_tile(l,n) = 0.
    aresist_tile(l,n) = 0.
    resist_b_tile(l,n) = 0.
  END DO
  DO k=1,tile_pts(n)
    l = tile_index(k,n)
    j=(land_index(l)-1)/row_length + 1
    i = land_index(l) - (j-1)*row_length
    rho_aresist_tile(l,n) = rhostar(i,j) * cd_std(l,n)            &
                * vshr_land(i,j)
    aresist_tile(l,n) = 1. / ( cd_std(l,n) * vshr_land(i,j) )
    resist_b_tile(l,n) = ( cd_std(l,n)/ch_tile(l,n) - 1.0 ) *     &
                                               aresist_tile(l,n)
    IF (resist_b_tile(l,n) < 0.) resist_b_tile(l,n) = 0.
    rho_aresist_land(i,j) = rho_aresist_land(i,j) +               &
                     tile_frac(l,n)*rho_aresist_tile(l,n)
  END DO
END DO

DO l=1,land_pts
  j=(land_index(l)-1)/row_length + 1
  i = land_index(l) - (j-1)*row_length
  rho_aresist(i,j) = flandg(i,j)*rho_aresist_land(i,j) +          &
                      (1.0-flandg(i,j))*rho_aresist(i,j)
  aresist(i,j) = rhostar(i,j) / rho_aresist(i,j)
END DO

 IF (l_dust) THEN

   DO j = 1,rows
     DO i = 1,row_length
       cd_std_dust(i,j)=(1.-flandg(i,j))*cd_ssi(i,j)
     END DO
   END DO

   DO n=1,ntiles
     DO k=1,tile_pts(n)
       l = tile_index(k,n)
       j=(land_index(l)-1)/row_length + 1
       i = land_index(l) - (j-1)*row_length
       cd_std_dust(i,j) = cd_std_dust(i,j) +                      &
               flandg(i,j)*tile_frac(l,n)*cd_std(l,n)
     END DO
   END DO

   DO j = 1,rows
     DO i = 1,row_length
       DO idiv = 1,ndiv
         r_b_dust(i,j,idiv) = 0.
       END DO !IDIV
       vshr(i,j)=(1.0 - flandg(i,j)) * vshr_ssi(i,j) +            &
              flandg(i,j) * vshr_land(i,j)
     END DO !I
   END DO !J

! DEPENDS ON: dustresb
   CALL dustresb (                                                &
     row_length,rows,                                             &
     pstar,tstar,rhostar,aresist,vshr,cd_std_dust,                &
     r_b_dust                                                     &
   )

 END IF !(L_DUST)


!-----------------------------------------------------------------------
! 10 Set RHOKH, the coefficients required for tracer mixing.
!    Required 5B and after due to change in contents of RHOKH in rest
!    of routine.
!-----------------------------------------------------------------------

DO j=1,rows
  DO i=1,row_length
    rhokh_mix(i,j) = rhokh_gb(i,j)
  END DO
END DO

IF (ltimer) THEN
! DEPENDS ON: timer
  CALL timer('SFAERO  ',4)
END IF

IF (lhook) CALL dr_hook('SF_AERO',zhook_out,zhook_handle)
RETURN
END SUBROUTINE sf_aero
