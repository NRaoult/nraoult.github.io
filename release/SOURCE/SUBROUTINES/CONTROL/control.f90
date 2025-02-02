  SUBROUTINE control ( a_step )

!-------------------------------------------------------------------------------
! Control level routine, to call the main parts of the model.
!-------------------------------------------------------------------------------

  USE aero, ONLY :  &
!  imported scalars with intent(in)
     co2_mmr  &
!  imported arrays with intent(in)
    ,co2_3d  &
!  imported arrays with intent(out)
    ,aresist,aresist_tile,cd_std_dust,r_b_dust,resist_b         &
    ,resist_b_tile,rho_aresist,rho_aresist_tile,RHO_CD_MODV1,u_s_std_tile

  USE ancil_info, ONLY :  &
              co2_dim_len,co2_dim_row,frac,halo_i,halo_j                     &
             ,ice_fract,ice_fract_ncat,land_index,land_pts                   &
             ,land_mask,land_pts_trif,lice_index,lice_pts,n_rows,nice        &
             ,npft_trif,ntiles,off_x,off_y,row_length,rows                   &
             ,sm_levels,soil_index,soil_pts,tile_index,tile_pts              &
             ,z1_tq,z1_uv,nsmax,dim_cs1,dim_cs2

  USE c_charnk, ONLY :  &
!  imported scalar parameters
     charnock

! Surface elevation
  USE c_elevate, ONLY :  &
!  imported arrays with intent(in)
     z_land

  USE c_epslon, ONLY :  &
!  imported scalar parameters
     c_virtual

  USE c_gamma, ONLY :  &
!  imported arrays with intent(in)
     gamma

  USE c_surf, ONLY :  &
!  imported scalar parameters
     OROG_DRAG_PARAM

  USE coastal, ONLY :  &
!  imported arrays with intent(in)
     fland,flandg  &
!  imported arrays with intent(out)
    ,surf_ht_flux_land,surf_ht_flux_sice,taux_land,taux_ssi,tauy_land  &
    ,tauy_ssi,tstar_land,tstar_sea,tstar_sice,tstar_ssi,vshr_land,vshr_ssi

  USE csigma, ONLY :  &
!  imported scalar parameters
      sbcon

  USE diag_swchs, ONLY : sfme,simlt,slh,smlt,sq1p5,st1p5  &
            ,stf_hf_snow_melt,stf_sub_surf_roff,su10,sv10,SZ0HEFF

  USE drive_io_vars, ONLY :  &
!  imported scalars with intent(in)
     io_rad_type

  USE fluxes, ONLY :  &
!  imported arrays with intent(out)
     alb_tile,e_sea,ecan,ecan_tile,ei,ei_tile,esoil,esoil_tile  &
    ,ext,fqw_1,fqw_tile,FQW_ICE,fsmc,ftl_1,FTL_ICE,ftl_tile,H_SEA  &
    ,HF_SNOW_MELT,LAND_ALBEDO,LATENT_HEAT,LE_TILE,MELT_TILE     &
    ,SEA_ICE_HTF,SICE_MLT_HTF,SNOMLT_SUB_HTF,SNOMLT_SURF_HTF    &
    ,SNOW_MELT,SNOWMELT,SUB_SURF_ROFF,SURF_HT_FLUX,surf_htf_tile  &
    ,SURF_ROFF,RADNET_TILE,TAUX_1,TAUY_1,TOT_TFALL,TSTAR  &
    ,surf_ht_store,anthrop_heat,sw_tile,emis_tile

  USE forcing, ONLY :  &
!  imported arrays with intent(out)
     con_rain,con_snow,ls_rain,ls_snow,lw_down  &
    ,pstar,qw_1,sw_down,tl_1,u_0,u_1,v_0,v_1

  USE orog, ONLY :  &
!  imported arrays
     h_blend_orog,ho2r2_orog,sil_orog_land,z0m_eff

  USE p_s_parms, ONLY : albsoil,b,catch,catch_snow,cosz  &
       ,hcap,hcon,infil_tile,satcon,sathh,smvccl,smvcst  &
       ,smvcwt,sthf,sthu,z0_tile,soil_clay

  USE prognostics, ONLY :  &
!  imported arrays with intent(inout)
     canht_ft,canopy,canopy_gb,cs                                  &
    ,di,di_ncat,gc,gs,lai,rgrain,rho_snow_grnd,smc,smcl,snow_mass  &
    ,snow_mass_sea,snow_grnd,snow_tile,soot,t_soil,ti              &
    ,tstar_tile,z0msea,nsnow,snowdepth,rgrainl                     &
    ,sice,sliq,tsnow

  USE route_mod, ONLY :  &
!  imported araays with intent(inout)
     roffAccumLand

  USE screen, ONLY : q1p5m,q1p5m_tile,t1p5m,t1p5m_tile,u10m,v10m


  USE sea_ice, ONLY :  &
!  imported scalar parameters
     l_moses_ii  &
!  imported scalars
    ,beta,dalb_bare_wet,dt_bare,pen_rad_frac,sw_alphab,sw_alphac,sw_alpham,sw_dtice,version

  USE snow_param, ONLY :  &
!  imported arrays with intent(inout)
     ds

  USE surf_param, ONLY :  &
!  imported scalars with intent(in)
     SeaSalinityFactor

  USE switches, ONLY :  &
!  imported scalars with intent(in)
     can_model,l_co2_interactive,l_cosz,l_dust          &
    ,l_neg_tstar,l_pdm,l_phenol,l_spec_albedo           &
    ,l_ssice_albedo,l_top,l_trif_eq,l_triffid           &
    ,ltimer,route,routeOnly,l_aggregate,can_rad_mod     &
    ,ilayers,L_MOD_BARKER_ALBEDO,L_SICE_MELTPONDS       &
    ,L_SICE_SCATTERING,FORMDRAG,FD_stab_dep             &
    ,L_Q10,lq_mix_bl,L_CTILE,L_spec_z0,L_SICE_HEATFLUX  &
    ,L_INLAND,L_SOIL_SAT_DOWN,l_anthrop_heat_src

  USE time_loc, ONLY : timestep, ijulian

  USE timeConst, ONLY :  &
!  imported scalar parameters
     iSecInDay

  USE top_pdm, ONLY :  &
!  imported arrays with intent(in)
     a_fsat,a_fwet,c_fsat,c_fwet,fexp,gamtot,ti_mean,ti_sig  &
!  imported arrays with intent(inout)
    ,sthzw,zw  &
!  imported arrays with intent(out)
   ,drain,dun_roff,fch4_wetl,fsat,fwetl,qbase,qbase_zw,inlandout_atm

  USE trifctl, ONLY :  &
!  imported scalars with intent(in)
     PHENOL_PERIOD,TRIFFID_PERIOD  &
!  imported scalars with intent(inout)
    ,ASTEPS_SINCE_TRIFFID  &
!  imported arrays with intent(inout)
    ,G_LEAF_ACC,NPP_FT_ACC,G_LEAF_PHEN_ACC,RESP_W_FT_ACC,RESP_S_ACC  &
    ,GPP,NPP,RESP_P,G_LEAF,G_LEAF_PHEN,GPP_FT,NPP_FT,RESP_P_FT       &
    ,RESP_S,RESP_W_FT,LAI_PHEN,C_VEG,CV,G_LEAF_DAY,G_LEAF_DR_OUT     &
    ,LIT_C,LIT_C_MN,NPP_DR_OUT,RESP_W_DR_OUT,RESP_S_DR_OUT,FRAC_AGR

  USE u_v_grid, ONLY :  &
!  imported arrays
     dtrdz_charney_grid_1,u_0_p,u_1_p,v_0_p,v_1_p

  USE zenith_mod, ONLY :  &
!  imported procedures
     zenith

  USE ozone_vars, ONLY :  &
     o3,flux_o3_ft,fo3_ft

  use fomod, only : iloopcount !Jupp


!-------------------------------------------------------------------------------

  IMPLICIT NONE

!-------------------------------------------------------------------------------
! Scalar arguments with intent(in)
!-------------------------------------------------------------------------------
  INTEGER, INTENT(in) :: a_step     ! IN Atmospheric timestep number.

!-------------------------------------------------------------------------------
! Local scalar variables.
!-------------------------------------------------------------------------------
  INTEGER :: error        ! OUT 0 - AOK;
!                         !     1 to 7  - bad grid definition detected
  INTEGER :: phenol_call  ! indicates whether phenology is to be called
  INTEGER :: triffid_call ! indicates whether TRIFFID is to be called
  INTEGER :: nstep_trif   ! Number of atmospheric timesteps between calls to
!                         ! TRIFFID vegetation model
  INTEGER :: i,j,l,n      ! Loop counters

!-------------------------------------------------------------------------------
! Local array variables.
!-------------------------------------------------------------------------------
  REAL :: CON_RAIN_LAND(LAND_PTS)     ! Convective rain (kg/m2/s).
  REAL :: LS_RAIN_LAND(LAND_PTS)      ! Large-scale rain (kg/m2/s).
  REAL :: SURF_HT_FLUX_LD(LAND_PTS)   ! Surface heat flux on land (W/m2).
!                                     ! This is the heat flux into the
!                                     ! uppermost subsurface layer (soil or
!                                     ! snow/soil composite) on land.
  REAL :: LYING_SNOW(LAND_PTS)        ! Gridbox snowmass (kg/m2)

!-------------------------------------------------------------------------------
!  SCREEN (additional)
!-------------------------------------------------------------------------------
  REAL :: T1_SD(ROW_LENGTH,ROWS)      ! Standard deviation of turbulent
!                                     ! fluctuations of layer 1 temp;
!                                     ! used in initiating convection.
  REAL :: Q1_SD(ROW_LENGTH,ROWS)      ! Standard deviation of turbulent
!                                     ! flux of layer 1 humidity;
!                                     ! used in initiating convection.
  REAL :: CDR10M_U(ROW_LENGTH,ROWS)   ! Ratio of CD's reqd for
!                                     ! calculation of 10 m wind. On
!                                     ! U-grid; comments as per RHOKM.
  REAL :: CDR10M_V(ROW_LENGTH,N_ROWS) ! Ratio of CD's reqd for
!                                     ! calculation of 10 m wind. On
!                                     ! V-grid; comments as per RHOKM.
  REAL :: CHR1P5M(LAND_PTS,NTILES)    ! Ratio of coefffs for
!                                     ! calculation of 1.5m temp for
!                                     ! land tiles.
  REAL :: CHR1P5M_SICE(ROW_LENGTH,ROWS)
!                                     ! CHR1P5M for sea and sea-ice
!                                (leads ignored).

!-------------------------------------------------------------------------------
! Local radiation variables.
!-------------------------------------------------------------------------------
  REAL :: PHOTOSYNTH_ACT_RAD(ROW_LENGTH,ROWS)
!                                     ! Net downward shortwave radiation
!                                     !  in band 1 (w/m2).

!-------------------------------------------------------------------------------
!  LOCAL SURF
!-------------------------------------------------------------------------------
  REAL :: TILE_FRAC(LAND_PTS,NTILES)  ! Tile fractions including
!                                     ! snow cover in the ice tile.
  REAL :: RAD_SICE(ROW_LENGTH,ROWS)   ! Surface net shortwave and
!                                     ! downward LW radiation for
!                                     ! sea-ice (W/sq m).
  REAL :: ZH(ROW_LENGTH,ROWS)         ! Height above surface of top of  
!                                     ! boundary layer (metres).        
  REAL :: CD(ROW_LENGTH,ROWS)         ! Turbulent surface exchange     
!                                     ! (bulk transfer) coefficient for
!                                     ! momentum.
  REAL :: CH(ROW_LENGTH,ROWS)         ! Turbulent surface exchange
!                                     ! (bulk transfer) coefficient for
!                                     ! heat and/or moisture.
  REAL :: RHO_SNOW(LAND_PTS,NTILES,NSMAX)
!                                     ! Snow layer densities (m)
  REAL :: HCONS(LAND_PTS)             ! Thermal conductivity of top
!                                     ! soil layer, including water and
!                                     ! ice (W/m/K)
  REAL :: RADNET_SICE(ROW_LENGTH,ROWS)! Surface net radiation on
!                                     ! sea-ice (W/m2)
  REAL :: RHOKM_1(1-OFF_X:ROW_LENGTH+OFF_X,1-OFF_Y:ROWS+OFF_Y)
!                                     ! Exchange coefficients for
!                                     ! momentum on P-grid
  REAL :: RHOKM_U_1(ROW_LENGTH,ROWS)  ! Exchange coefficients for momentum
!                                     ! (on U-grid, with 1st and last rows
!                                     ! undefined or, at present, set to
!                                     ! "missing data")
  REAL :: RHOKM_V_1(ROW_LENGTH,N_ROWS)! Exchange coefficients for momentum
!                                     ! (on V-grid, with 1st and last rows
!                                     ! undefined or, at present, set to
!                                     ! "missing data")
  REAL :: RIB(ROW_LENGTH,ROWS)        ! Mean bulk Richardson number for
!                                     ! lowest layer.
  REAL :: RIB_TILE(LAND_PTS,NTILES)   ! RIB for land tiles.
  REAL :: FME(ROW_LENGTH,ROWS)        ! Wind mixing "power" (W/m2).
  REAL :: FB_SURF(ROW_LENGTH,ROWS)    ! Surface flux buoyancy over
!                                     ! density (m^2/s^3)
  REAL :: U_S(ROW_LENGTH,ROWS)        ! Surface friction velocity (m/s)
  REAL :: ALPHA1(LAND_PTS,NTILES)     ! Mean gradient of saturated
!                                     ! specific humidity with respect
!                                     ! to temperature between the
!                                     ! bottom model layer and tile
!                                     ! surfaces
  REAL :: ALPHA1_SICE(ROW_LENGTH,ROWS)! ALPHA1 for sea-ice.
  REAL :: ASHTF_PRIME(ROW_LENGTH,ROWS)! Adjusted SEB coefficient for sea-ice
  REAL :: ASHTF_PRIME_TILE(LAND_PTS,NTILES)
!                                     ! Adjusted SEB coefficient for land tiles
  REAL :: FRACA(LAND_PTS,NTILES)      ! Fraction of surface moisture
!                                     ! flux with only aerodynamic
!                                     ! resistance for snow-free land tiles.
  REAL :: RHOSTAR(ROW_LENGTH,ROWS)    ! Surface air density
  REAL :: RESFS(LAND_PTS,NTILES)      ! Combined soil, stomatal
!                                     ! and aerodynamic resistance
!                                     ! factor for fraction (1-FRACA)
!                                     ! of snow-free land tiles.
  REAL :: RESFT(LAND_PTS,NTILES)      ! Total resistance factor.
!                                     ! FRACA+(1-FRACA)*RESFS for
!                                     ! snow-free land, 1 for snow.
  REAL :: RHOKH(ROW_LENGTH,ROWS)      ! Grid-box surface exchange
!                                     ! coefficients
  REAL :: RHOKH_TILE(LAND_PTS,NTILES) ! Surface exchange coefficients
!                                     ! for land tiles
  REAL :: RHOKH_SICE(ROW_LENGTH,ROWS) ! Surface exchange coefficients
!                                     ! for sea and sea-ice
  REAL :: DTSTAR_TILE(LAND_PTS,NTILES)! Change in TSTAR over timestep
!                                     ! for land tiles
  REAL :: DTSTAR(ROW_LENGTH,ROWS)     ! Change is TSTAR over timestep
!                                     ! for sea-ice
  REAL :: SURF_HT_FLUX_SICE_NCAT(ROW_LENGTH,ROWS,NICE)
!                                     ! Heat flux by ice catagory
  REAL :: FLANDG_U(ROW_LENGTH,ROWS)   ! Land frac (on U-grid, with 1st
!                                     ! and last rows undefined or, at
!                                     ! present, set to "missing data")
  REAL :: FLANDG_V(ROW_LENGTH,N_ROWS) ! Land frac (on V-grid, with 1st
!                                     ! and last rows undefined or, at
!                                     ! present, set to "missing data")

  REAL :: Z0HSSI(ROW_LENGTH,ROWS)     ! Roughness length for heat and
!                                     ! moisture over sea (m).
  REAL :: Z0H_TILE(LAND_PTS,NTILES)   ! Tile roughness lengths for heat
!                                     ! and moisture (m).
  REAL :: Z0MSSI(ROW_LENGTH,ROWS)     ! Roughness length for
!                                     ! momentum over sea (m).
  REAL :: Z0M_TILE(LAND_PTS,NTILES)   ! Tile roughness lengths for
!                                     ! momentum.
  REAL :: VSHR(ROW_LENGTH,ROWS)       ! Magnitude of surface-to-lowest
!                                     ! atm level wind shear (m per s).
  REAL :: CANHC_TILE(LAND_PTS,NTILES) ! Areal heat capacity of canopy
!                                     ! for land tiles (J/K/m2).
  REAL :: WT_EXT_TILE(LAND_PTS,SM_LEVELS,NTILES)
!                                     ! Fraction of evapotranspiration
!                                     ! which is extracted from each
!                                     ! soil layer by each tile.
  REAL :: FLAKE(LAND_PTS,NTILES)      ! Lake fraction.
  REAL :: CT_CTQ_1(ROW_LENGTH,ROWS)   ! Coefficient in T and q
!                                     ! tri-diagonal implicit matrix
  REAL :: CQ_CM_U_1(ROW_LENGTH,ROWS)  ! Coefficient in U tri-diagonal
!                                     ! implicit matrix
  REAL :: CQ_CM_V_1(ROW_LENGTH,N_ROWS)! Coefficient in V tri-diagonal
!                                     ! implicit matrix
  REAL :: DQW_1(ROW_LENGTH,ROWS)      ! Level 1 increment to q field
  REAL :: DTL_1(ROW_LENGTH,ROWS)      ! Level 1 increment to T field
  REAL :: DU_1(1-OFF_X:ROW_LENGTH+OFF_X,1-OFF_Y:ROWS+OFF_Y)
!                                     ! Level 1 increment to u wind field
  REAL :: DV_1(1-OFF_X:ROW_LENGTH+OFF_X,1-OFF_Y:N_ROWS+OFF_Y)
!                                     ! Level 1 increment to v wind field
  REAL :: TI_GB(ROW_LENGTH,ROWS)      ! GBM ice surface temperature (K)
  REAL :: OLR(ROW_LENGTH,ROWS)        !    TOA - surface upward LW on
!                                     !    last radiation timestep
!                                     !    Corrected TOA outward LW
  REAL :: RHOKH_MIX(ROW_LENGTH,ROWS)  ! Exchange coeffs for moisture.
  REAL :: BQ_1(ROW_LENGTH,ROWS)       ! A buoyancy parameter (beta q tilde).
  REAL :: BT_1(ROW_LENGTH,ROWS)       ! A buoyancy parameter (beta T tilde).
  REAL :: EMIS_SOIL(LAND_PTS)         ! Emissivity of underlying soil

  REAL :: SICE_ALB(ROW_LENGTH,ROWS)          ! Albedo of sea-ice
  REAL :: LAND_ALB(ROW_LENGTH,ROWS)          !   sea-ice albedo
  REAL :: OPEN_SEA_ALBEDO(ROW_LENGTH,ROWS,2) !   calculations

!-----------------------------------------------------------------------
! Variables used for semi-implicit, semi-Lagrangian scheme in UM
! Not used standalone
!-----------------------------------------------------------------------
  INTEGER, PARAMETER :: NumCycles = 1  !  Number of cycles (iterations) for iterative SISL.
  INTEGER, PARAMETER :: CycleNo = 1    !  Iteration no

!-----------------------------------------------------------------------
! These variables are required for prescribed roughness lengths in
! SCM mode in UM - not used standalone
!-----------------------------------------------------------------------
  REAL :: Z0M_SCM(ROW_LENGTH,ROWS)    ! Fixed Sea-surface roughness
!                                     ! length for momentum (m).(SCM)
  REAL :: Z0H_SCM(ROW_LENGTH,ROWS)    ! Fixed Sea-surface roughness
!                                     ! length for heat (m). (SCM)

!-----------------------------------------------------------------------
! These variables are INTENT(OUT) in sf_expl, so just define them here.
!-----------------------------------------------------------------------
  REAL :: RECIP_L_MO_SEA(row_length,rows)
!                                     ! Reciprocal of the surface
!                                     ! Obukhov  length at sea
!                                     ! points. (m-1).
  REAL :: EPOT_TILE(LAND_PTS,NTILES)  ! Local EPOT for land tiles.
  REAL :: RHOKPM(LAND_PTS,NTILES)     ! Land surface exchange coeff.
!                                     ! (Note used with JULES)
  REAL :: RHOKPM_POT(LAND_PTS,NTILES) ! Potential evaporation
!                                     ! exchange coeff.
!                                     ! (Dummy - not used with JULES)
  REAL :: RHOKPM_SICE(ROW_LENGTH,ROWS)! Sea-ice surface exchange coeff.
!                                     ! (Dummy - not used with JULES)
  REAL :: Z0H_EFF(ROW_LENGTH,ROWS)    ! Effective grid-box roughness
!                                     ! length for heat, moisture (m)
  REAL :: Z0M_GB(ROW_LENGTH,ROWS)     ! Gridbox mean roughness length
!                                     ! for momentum (m).
  REAL :: RESP_S_TOT(DIM_CS2)         ! Total soil respiration (kg C/m2/s).
  REAL :: WT_EXT(LAND_PTS,SM_LEVELS)  ! cumulative fraction of transp'n
  REAL :: RA(LAND_PTS)                ! Aerodynamic resistance (s/m).

  LOGICAL, PARAMETER :: l_ukca = .FALSE.   ! switch for UKCA scheme - NEVER USED!!!
  LOGICAL, PARAMETER :: L_FLUX_BC = .FALSE.
                      ! SCM logical for prescribed
                      ! surface flux forcing - why is this in
                      ! the surface scheme?!!!
                      
!-------------------------------------------------------------------------
! These variables are INTENT(IN) to sf_expl, but not used with the
! current configuration of standalone JULES (initialised to 0 below)
!-------------------------------------------------------------------------
REAL :: z1_uv_top(row_length, rows)
                             ! Height of top of lowest uv-layer
REAL :: z1_tq_top(row_length, rows)
                             ! Height of top of lowest Tq-layer
REAL :: ddmfx(row_length,rows)
!                            ! Convective downdraught  
!                            ! mass-flux at cloud base

!-----------------------------------------------------------------------
! Initialise these to zero as they are never used
!-----------------------------------------------------------------------
  z0m_scm(:,:)   = 0.0
  z0h_scm(:,:)   = 0.0
  z1_uv_top(:,:) = 0.0
  z1_tq_top(:,:) = 0.0
  ddmfx(:,:)     = 0.0

      alpha1       = 0.         !Jupp
      ashtf_prime  = 0.         !Jupp
      flandg_u     = 0.         !Jupp
      flandg_v     = 0.         !Jupp
      rhokm_u_1    = 0.         !Jupp
      rhokm_v_1    = 0.         !Jupp
      rhokpm       = 0.         !Jupp
      rhokpm_sice  = 0.         !Jupp
      chr1p5m      = 0.         !Jupp
      chr1p5m_sice = 0.         !Jupp

!------------------------------------------------------------------------------
! If we're only doing river routing, most routines need not be called.
!------------------------------------------------------------------------------


!write(*,*) 'control line 429 :',iloopcount
!$TAF STORE canht_ft,g_leaf_acc,gs,hcons,l_q10,lai,npp_ft_acc,resp_s_acc, &
!$TAF&      resp_w_ft_acc,tstar,tstar_sice,tstar_tile,z0msea,             &
!$TAF&      rad_sice,flandg,rgrain,snowdepth,tile_index,tile_pts, &
!$TAF&      sw_down, smcl, sthf , &
!$TAF&      canopy,ds,nsnow,sice,sliq,snow_tile,sthu,t_soil,tsnow = tape_n_control0, &
!$TAF&      REC = iloopcount
!$TAF INCOMPLETE rad_sice




  IF ( .NOT. routeOnly ) THEN

!-------------------------------------------------------------------------------
!   Calculate the cosine of the zenith angle
!-------------------------------------------------------------------------------
    IF ( l_cosz ) THEN
      CALL zenith( row_length*rows,cosz )
    ELSE
!     Set cosz to a default of 1.0
      cosz(:) = 1.0
    ENDIF

!$TAF STORE flandg=tape_n_control8, REC = iloopcount
    CALL ftsa( land_mask,flandg,ice_fract,tstar,tstar_sice       &
           ,cosz,snow_mass,snow_mass_sea                         &
           ,sw_alpham,sw_alphac,sw_alphab,sw_dtice               &
           ,l_moses_ii,l_ssice_albedo                            &
           ,l_mod_barker_albedo                                  &
           ,l_sice_meltponds,l_sice_scattering,.TRUE.            &
           ,dt_bare,dalb_bare_wet,pen_rad_frac,beta,version      &
           ,row_length*rows,row_length*rows                      &
           ,land_alb,sice_alb                                    &
           ,open_sea_albedo )

!-------------------------------------------------------------------------------
!   Calculate albedo on land tiles.
!-------------------------------------------------------------------------------
!$TAF STORE rgrain,snowdepth,tile_index,tile_pts,tstar_tile,                &
!$TAF&      z0_tile,tstar = tape_n_control9, &
!$TAF&      REC = iloopcount
    CALL TILE_ALBEDO (                                                      &
           row_length*rows,land_pts,land_index,ntiles,tile_pts              &
          ,tile_index,l_aggregate,l_spec_albedo,albsoil                     &
          ,cosz,frac,lai,rgrain,snowdepth,soot,tstar_tile,z0_tile           &
          ,alb_tile,land_albedo,can_rad_mod )
!Jupp
!write(*,*) 'control line 461 :',iloopcount
!$TAF STORE alb_tile,land_albedo  = tape_n_control1, REC = iloopcount
!Jupp

!-------------------------------------------------------------------------------
!   Change radiation to be downward components if not using io_rad_type=1
!   NOTE this assumes that the point is either 100% land or 100% sea-ice.
!   1 downward fluxes provided
!   2 net (all wavelength) downward (in downward longwave variable) and downward
!      shortwave fluxes are provided
!   3 net downward fluxes are provided (in downward variables)
!   One day we would probably like to do this in driveUpdate or the likes, but
!   at present we don't
!   have all the required variables/masks there (I think).
!-------------------------------------------------------------------------------
!$TAF STORE sw_down = tape_n_control10, REC = iloopcount
    IF ( io_rad_type == 2) THEN
!-------------------------------------------------------------------------------
!     Convert net total radiation to net longwave. Net total is currently stored
!     in lw_down. Use the average of diffuse albedos in visible and NIR on land.
!-------------------------------------------------------------------------------
      DO i=1,row_length
        DO j=1,rows
          IF ( land_mask(i,j) ) THEN
            lw_down(i,j) = lw_down(i,j) - sw_down(i,j) * ( 1.0 - 0.5 *  &
                                ( land_albedo(i,j,2) + land_albedo(i,j,4) ) )
          ELSE
            lw_down(i,j) = lw_down(i,j)-  sw_down(i,j) * ( 1.0 - sice_alb(i,j) )
          ENDIF
        ENDDO
      ENDDO
    ENDIF   !  io_rad_type

    IF ( io_rad_type == 3 ) THEN
!-------------------------------------------------------------------------------
!     Convert shortwave from net to downward.
!     Net flux is currently stored in sw_down.
!     Use the average of diffuse albedos in visible and NIR on land.
!-------------------------------------------------------------------------------
      DO i=1,row_length
        DO j=1,rows
          IF ( land_mask(i,j) ) THEN
            sw_down(i,j) = sw_down(i,j) / ( 1.0 - 0.5 *  &
                                ( land_albedo(i,j,2) + land_albedo(i,j,4) ) )
          ELSE
            sw_down(i,j) = sw_down(i,j) / ( 1.0 - sice_alb(i,j) )
          ENDIF
        ENDDO
      ENDDO
    ENDIF   !  io_rad_type

    IF ( io_rad_type == 2 .OR. io_rad_type == 3) THEN
!-------------------------------------------------------------------------------
!     Convert longwave from net to downward. Net longwave is currently stored in lw_down.
!-------------------------------------------------------------------------------
      DO i=1,row_length
        DO j=1,rows
          IF ( .NOT. land_mask(I,J) ) THEN
            lw_down(i,j) = lw_down(i,j) + sbcon * tstar_sice(i,j)**4.0
          ENDIF
        ENDDO
      ENDDO
      DO n=1,ntiles
        DO l=1,land_pts
          j = ( land_index(l)-1 ) / row_length + 1
          i = land_index(l) - ( j-1 ) * row_length
          lw_down(i,j) = lw_down(i,j) + frac(l,n) * sbcon * tstar_tile(l,n)**4.0
        ENDDO
      ENDDO
    ENDIF   !  io_rad_type

!-----------------------------------------------------------------------
!   Calculate radiation for sea ice.
!-----------------------------------------------------------------------
    DO i=1,row_length
      DO j=1,rows
        rad_sice(i,j) = ( 1. - sice_alb(i,j) ) * sw_down(i,j) + lw_down(i,j)
      ENDDO
    ENDDO

!-----------------------------------------------------------------------
!   Calculate net SW radiation on tiles.
!   Use the average of diffuse albedos in visible and NIR.
!-----------------------------------------------------------------------
    DO n=1,ntiles
      DO l=1,land_pts
        j = ( land_index(l)-1 ) / row_length + 1
        i = land_index(l) - (j-1)*row_length
        sw_tile(l,n) = ( 1. - 0.5 * ( alb_tile(l,n,2) + alb_tile(l,n,4)  &
                       ) ) * sw_down(i,j)
      ENDDO
    ENDDO

!-----------------------------------------------------------------------
!   Calculate photosynthetically active radiation (PAR).
!-----------------------------------------------------------------------
    DO i=1,row_length
      DO j=1,rows
        photosynth_act_rad(i,j) = 0.5 * sw_down(i,j)
      ENDDO
    ENDDO

!-----------------------------------------------------------------------
!   Calculate buoyancy parameters bt and bq. set ct_ctq_1, cq_cm_u_1,
!   cq_cm_v_1, dtl_1, dqw_1, du_1 , dv_1 all to zero (explicit coupling)
!   and boundary-layer depth.
!-----------------------------------------------------------------------
    DO i=1,row_length
      DO j=1,rows
        bt_1(i,j) = 1. / tl_1(i,j)
        bq_1(i,j) = c_virtual / (1. + c_virtual*qw_1(i,j))
        ct_ctq_1(i,j) = 0.0
        cq_cm_u_1(i,j) = 0.0
        cq_cm_v_1(i,j) = 0.0
        dtl_1(i,j) = 0.0
        dqw_1(i,j) = 0.0
        du_1(i,j) = 0.0
        dv_1(i,j) = 0.0
        zh(i,j) = 1000.
      ENDDO
    ENDDO

!-----------------------------------------------------------------------
!   Generate the anthropogenic heat for surface calculations
!   dummy variables given for yr, hr, min, sec as they are not used
!-----------------------------------------------------------------------
    CALL generate_anthropogenic_heat( 0,ijulian,0,0,0,ntiles  &
                           ,land_pts,frac,anthrop_heat        &
                           ,l_anthrop_heat_src )
   
!-----------------------------------------------------------------------
!   Explicit calculations.
!-----------------------------------------------------------------------

!$TAF STORE canopy,ds,flandg,gs,hcons,l_q10,nsnow,sice,sliq,snow_tile, &
!$TAF&      snowdepth,sthf,sthu,t_soil,tsnow,tstar_tile,        &
!$TAF&      z0msea,tile_index,tile_pts = tape_n_control11, REC = iloopcount

    CALL sf_expl (                                                    &

!     IN values defining field dimensions and subset to be processed :
         halo_i,halo_j,off_x,off_y,row_length,rows,n_rows             &
        ,land_pts,land_pts_trif,npft_trif                             &
        ,dim_cs1,dim_cs2                                              &

!     IN  parameters for iterative SISL scheme
        ,numcycles,cycleno                                            &

!     IN parameters required from boundary-layer scheme :
        ,bq_1,bt_1,z1_uv,z1_uv_top,z1_tq,z1_tq_top,qw_1,tl_1          &

!     IN soil/vegetation/land surface data :
        ,land_index,land_mask,formdrag,fd_stab_dep,orog_drag_param    &
        ,ntiles,sm_levels,canopy,catch,catch_snow,hcon,ho2r2_orog     &
        ,fland,flandg,snow_tile,sil_orog_land,smvccl,smvcst,smvcwt    &
        ,sthf,sthu,z0_tile                                            &

!     IN sea/sea-ice data :
        ,ice_fract,u_0,v_0,u_0_p,v_0_p,charnock,seasalinityfactor     &

!     IN everything not covered so far :
        ,pstar,lw_down,rad_sice,sw_tile,timestep,zh,ddmfx             &
        ,co2_mmr,co2_3d,co2_dim_len,co2_dim_row,l_co2_interactive     &
        ,l_phenol,l_triffid,l_q10,asteps_since_triffid                &
        ,cs,frac,canht_ft,photosynth_act_rad,lai,lq_mix_bl            &
        ,t_soil,ti,tstar                                              &
        ,tstar_land,tstar_sea,tstar_sice,tstar_ssi                    &
        ,tstar_tile,z_land,l_ctile,0                                  &
        ,albsoil,cosz,ilayers                                         &
        ,u_1,v_1,u_1_p,v_1_p                                          &
        ,l_dust,anthrop_heat,soil_clay,o3                             &

!     IN STASH flags :-
        ,sfme,sq1p5,st1p5,su10,sv10,sz0heff                           &

!     INOUT data :
        ,z0msea,l_spec_z0,z0m_scm,z0h_scm,gs                          &
        ,g_leaf_acc,npp_ft_acc,resp_w_ft_acc,resp_s_acc               &

!     OUT diagnostic not requiring STASH flags :
        ,cd,ch,recip_l_mo_sea,e_sea,fqw_1                             &
        ,ftl_1,ftl_tile,le_tile,h_sea,radnet_sice,radnet_tile         &
        ,rhokm_1,rhokm_u_1,rhokm_v_1,rib,rib_tile,taux_1,tauy_1       &
        ,taux_land,taux_ssi,tauy_land,tauy_ssi                        &

!     OUT diagnostic requiring STASH flags :
        ,fme                                                          &

!     OUT diagnostics required for soil moisture nudging scheme :
        ,wt_ext,ra                                                    &

!     OUT data required for tracer mixing :
        ,rho_aresist,aresist,resist_b                                 &
        ,rho_aresist_tile,aresist_tile,resist_b_tile                  &

!     OUT data required for mineral dust scheme
        ,r_b_dust,cd_std_dust,u_s_std_tile                            &

!     OUT data required for 4d-var :
        ,rho_cd_modv1                                                 &

!     OUT data required elsewhere in UM system
        ,fb_surf,u_s,t1_sd,q1_sd                                      &

!     OUT data required elsewhere in boundary layer or surface code
        ,alpha1,alpha1_sice,ashtf_prime,ashtf_prime_tile,fqw_tile     &
        ,epot_tile,fqw_ice,ftl_ice,fraca,rhostar,resfs,resft          &
        ,rhokh,rhokh_tile,rhokh_sice,rhokpm,rhokpm_pot,rhokpm_sice    &
        ,rhokh_mix,dtstar_tile,dtstar                                 &
        ,h_blend_orog,z0hssi,z0h_tile,z0h_eff,z0m_gb,z0mssi,z0m_tile  &
        ,z0m_eff,cdr10m_u,cdr10m_v,chr1p5m,chr1p5m_sice,smc,hcons     &
        ,vshr,vshr_land,vshr_ssi                                      &
        ,gpp,npp,resp_p,g_leaf,gpp_ft,npp_ft                          &
        ,resp_p_ft,resp_s,resp_s_tot,resp_w_ft                        &
        ,gc,canhc_tile,wt_ext_tile,flake                              &
        ,tile_index,tile_pts,tile_frac,fsmc                           &
        ,flandg_u,flandg_v,emis_tile,emis_soil                        &

! OUT data for ozone
        ,flux_o3_ft,fo3_ft                                            &

!     logicals
   &    ,ltimer,l_ukca  )

!-----------------------------------------------------------------------
!   Implicit calculations.
!-----------------------------------------------------------------------
!Jupp
!write(*,*) 'control line 684 :',iloopcount
!$TAF STORE alpha1,alpha1_sice,ashtf_prime,ashtf_prime_tile,canhc_tile,e_sea,flake, &
!$TAF& flandg,flandg_u,flandg_v,fqw_1,fqw_tile,fraca,ftl_1,ftl_tile,    &
!$TAF& h_sea,radnet_sice,radnet_tile,resfs,resft,rhokh_sice,            &
!$TAF& rhokh_tile,rhokm_u_1,rhokm_v_1,rhokpm,rhokpm_sice,smc,tile_frac, &
!$TAF& tile_index,tile_pts,wt_ext_tile = tape_n_control2, REC = iloopcount
!Jupp

    CALL sf_impl (                                                      &

!     IN values defining field dimensions and subset to be processed :
         off_x,off_y,row_length,rows,n_rows,land_pts                    &

!     IN soil/vegetation/land surface data :
        ,land_index,land_mask,nice                                      &
        ,ntiles,tile_index,tile_pts,sm_levels                           &
        ,canhc_tile,canopy,flake,smc,tile_frac,wt_ext_tile,fland,flandg &

!     IN sea/sea-ice data :
        ,di,ice_fract,di_ncat,ice_fract_ncat,u_0,v_0                    &

!     IN everything not covered so far :
        ,pstar,lw_down,rad_sice,sw_tile,timestep                        &
        ,t_soil,qw_1,tl_1,u_1,v_1,rhokm_u_1,rhokm_v_1,gamma(1)          &
        ,alpha1,alpha1_sice,ashtf_prime,ashtf_prime_tile                &
        ,dtrdz_charney_grid_1,du_1,dv_1                                 &
        ,fqw_tile,epot_tile,fqw_ice,ftl_ice                             &
        ,fraca,resfs,resft,rhokh,rhokh_tile,rhokh_sice                  &
        ,rhokpm,rhokpm_pot,rhokpm_sice                                  &
        ,dtstar_tile,dtstar,z1_tq                                       &
        ,z0hssi,z0mssi,z0h_tile,z0m_tile,cdr10m_u,cdr10m_v              &
        ,chr1p5m,chr1p5m_sice,ct_ctq_1,dqw_1,dtl_1,cq_cm_u_1,cq_cm_v_1  &
        ,l_neg_tstar                                                    &
        ,flandg_u,flandg_v,anthrop_heat,l_sice_heatflux                 &
        ,emis_tile,emis_soil                                            &

!     IN STASH flags :-
        ,simlt,smlt,slh,sq1p5,st1p5,su10,sv10                           &

!     INOUT data :
        ,ti,ti_gb,tstar                                                 &
        ,tstar_land,tstar_sea,tstar_sice,tstar_ssi                      &
        ,tstar_tile,snow_tile                                           &
        ,le_tile,radnet_sice,radnet_tile                                &
        ,e_sea,fqw_1,ftl_1,ftl_tile,h_sea,olr,taux_1,tauy_1             &
        ,taux_land,taux_ssi,tauy_land,tauy_ssi                          &

!     OUT diagnostic not requiring STASH flags :
        ,ecan,ei_tile,esoil_tile                                        &
        ,sea_ice_htf,surf_ht_flux,surf_ht_flux_land,surf_ht_flux_sice   &
        ,surf_htf_tile,surf_ht_store                                    &

!     OUT diagnostic requiring STASH flags :
        ,sice_mlt_htf,snomlt_surf_htf,latent_heat                       &
        ,q1p5m,q1p5m_tile,t1p5m,t1p5m_tile,u10m,v10m                    &

!     OUT data required elsewhere in UM system :
        ,ecan_tile,ei,esoil,ext,snowmelt,melt_tile,rhokh_mix            &
        ,surf_ht_flux_sice_ncat                                         &
        ,error                                                          &

!     logicals
       ,lq_mix_bl,l_flux_bc,ltimer )

!-----------------------------------------------------------------------
!   Compress fields to land only for hydrology
!-------------------------------------------------------------------------------
    DO l=1,land_pts
      j=(land_index(l)-1)/row_length + 1
      i=land_index(l) - (j-1)*row_length
      ls_rain_land(l)=ls_rain(i,j)
      con_rain_land(l)=con_rain(i,j)
    ENDDO

!-------------------------------------------------------------------------------
!   Snow processes.
!-------------------------------------------------------------------------------
!$TAF INCOMPLETE ds,smcl,sthf,t_soil,smvcst,melt_tile 



!Jupp
!write(*,*) 'control line 766 :',iloopcount
!$TAF STORE ds,melt_tile,nsnow,rgrain,rgrainl,rho_snow,rho_snow_grnd,sice,sliq, &
!$TAF&      smcl,sthf,                                                          &
!$TAF&      snow_grnd,snow_tile,snowdepth,t_soil,tsnow,                         &
!$TAF&      tstar_tile = tape_n_control3, REC = iloopcount
!Jupp

   CALL snow ( land_pts,timestep,stf_hf_snow_melt,ntiles,tile_pts,tile_index   &
           ,catch_snow,con_snow,tile_frac,ls_snow,ei_tile,hcap(:,1),hcons      &
           ,melt_tile,smcl(:,1),sthf(:,1),surf_htf_tile,t_soil(:,1)            &
           ,tstar_tile,smvcst(:,1),rgrain,rgrainl,rho_snow_grnd,sice           &
           ,sliq,snow_grnd,snow_tile,snowdepth,tsnow,nsnow                     &
           ,ds,hf_snow_melt,lying_snow,rho_snow,snomlt_sub_htf,snow_melt       &
           ,surf_ht_flux_ld )

!-------------------------------------------------------------------------------
!   Reset snowmelt over land points.
!-------------------------------------------------------------------------------
    DO l=1,land_pts
      j = ( land_index(l)-1 ) / row_length + 1
      i = land_index(l) - (j-1) * row_length
      snowmelt(i,j) = snow_melt(l)
    ENDDO

!-------------------------------------------------------------------------------
!   Land hydrology.
!-------------------------------------------------------------------------------

!Jupp
!write(*,*) 'control line 793 :',iloopcount
!$TAF STORE con_rain_land,ecan_tile,ext,melt_tile, &
!$TAF&  ls_rain_land,snow_tile,surf_ht_flux_ld, &
!$TAF&  tstar_tile = tape_n_control4, REC = iloopcount
!Jupp

    CALL hydrol (                                                &
              lice_pts,lice_index,soil_pts,soil_index,nsnow,     &
              land_pts,sm_levels,b,catch,con_rain_land,          &
              ecan_tile,ext,hcap,hcon,ls_rain_land,              &
              satcon,sathh,snowdepth,surf_ht_flux_ld,timestep,   &
              smvcst,smvcwt,canopy,stf_hf_snow_melt,             &
              stf_sub_surf_roff,smcl,sthf,sthu,t_soil,           &
              canopy_gb,hf_snow_melt,smc,snow_melt,              &
              sub_surf_roff,surf_roff,tot_tfall,                 &
              inlandout_atm,l_inland,ntiles,tile_pts,tile_index, &
              infil_tile,melt_tile,tile_frac,                    &
              l_top,l_pdm,fexp,gamtot,ti_mean,ti_sig,cs,         &
              dun_roff,drain,fsat,fwetl,qbase,qbase_zw,          &
              zw,sthzw,a_fsat,c_fsat,a_fwet,c_fwet,              &
              fch4_wetl,dim_cs1,l_soil_sat_down,l_triffid,       &
              ltimer )

  ENDIF   !  not routeonly

!Jupp
!write(*,*) 'control line 819 :',iloopcount
!$TAF STORE g_leaf_acc,npp_ft_acc,resp_s_acc,resp_w_ft_acc               &
!$TAF&  = tape_n_control5, REC = iloopcount
!Jupp

!-------------------------------------------------------------------------------
! Call runoff routing.
!-------------------------------------------------------------------------------
!Jupp  IF ( route ) CALL route_drive( land_pts,sub_surf_roff  &
!Jupp                                ,surf_roff,roffaccumland )


  IF ( .NOT. routeonly ) THEN

!-------------------------------------------------------------------------------
!   Copy land points output back to full fields array.
!-------------------------------------------------------------------------------
    DO l = 1,land_pts
      j = ( land_index(l)-1 ) / row_length + 1
      i = land_index(l) - (j-1) * row_length
      snow_mass(i,j) = lying_snow(l)
    ENDDO

!-----------------------------------------------------------------------
!   Update sea-ice surface layer temperature.
!-----------------------------------------------------------------------
    CALL sice_htf( row_length,rows,flandg,simlt,nice                   &
                  ,di_ncat,ice_fract,ice_fract_ncat,surf_ht_flux_sice_ncat  &
                  ,tstar_sice,timestep                                 &
                  ,ti,ti_gb,sice_mlt_htf,sea_ice_htf,l_sice_heatflux   &
                  ,ltimer)

!-------------------------------------------------------------------------------
!   Convert sea and sea-ice fluxes to be fraction of grid-box
!   (as required by sea and sea-ice modellers)
!-------------------------------------------------------------------------------
    DO i=1,row_length
      DO j=1,rows
        DO n=1,nice
          surf_ht_flux_sice_ncat(i,j,n) = ice_fract(i,j) *         &
                          surf_ht_flux_sice_ncat(i,j,n)
          sice_mlt_htf(i,j,n) = ice_fract(i,j) * sice_mlt_htf(i,j,n)
          sea_ice_htf(i,j,n) = ice_fract(i,j) * sea_ice_htf(i,j,n)
        ENDDO
      ENDDO
    ENDDO

!-------------------------------------------------------------------------------
!   If leaf phenolgy is activated, check whether the surface model has run an
!   integer number of phenology calling periods
!-------------------------------------------------------------------------------
    phenol_call=1
    triffid_call=1
    IF ( l_phenol ) phenol_call = MOD ( FLOAT(a_step),  &
                         (FLOAT(phenol_period)*(REAL(isecinday)/timestep)) )

!Jupp
!write(*,*) 'control line 876 :',iloopcount
!$TAF STORE PHENOL_CALL = tape_n_control6, REC = iloopcount
!Jupp

    IF ( l_triffid ) THEN
      nstep_trif = INT( REAL(isecinday) * triffid_period / timestep )
      IF ( asteps_since_triffid == nstep_trif ) triffid_call = 0
    ENDIF

!Jupp
!write(*,*) 'control line 886 :',iloopcount
!$TAF STORE TRIFFID_CALL = tape_n_control7, REC = iloopcount
!Jupp

    IF ( triffid_call == 0 ) THEN
!-------------------------------------------------------------------------------
!     Run includes dynamic vegetation
!-------------------------------------------------------------------------------

!$TAF INCOMPLETE resp_s_acc,g_leaf_acc,g_leaf_phen_acc,npp_ft_acc,resp_w_ft_acc      &
!$TAF&          ,cs,frac,lai ,soil_clay,canht_ft,catch_snow,catch,infil_tile &
!$TAF&          ,z0_tile,c_veg,cv,g_leaf_day,g_leaf_dr_out,lai_phen,lit_c    &
!$TAF&          ,lit_c_mn,npp_dr_out,resp_w_dr_out,resp_s_dr_out

      CALL veg2( land_pts,land_index,ntiles,can_model                         &
                ,row_length,rows,a_step,asteps_since_triffid                  &
                ,phenol_period,triffid_period,l_phenol,l_triffid,l_trif_eq    &
                ,timestep,frac_agr,satcon                                     &
                ,g_leaf_acc,g_leaf_phen_acc,npp_ft_acc                        &
                ,resp_s_acc,resp_w_ft_acc                                     &
                ,cs,frac,lai,soil_clay,canht_ft                               &
                ,catch_snow,catch,infil_tile,z0_tile                          &
                ,c_veg,cv,lit_c,lit_c_mn,g_leaf_day,g_leaf_phen               &
                ,lai_phen,g_leaf_dr_out,npp_dr_out,resp_w_dr_out              &
                ,resp_s_dr_out )

    ELSE

      IF ( phenol_call == 0 )  &
!-------------------------------------------------------------------------------
!       Run includes phenology, but not dynamic vegetation
!       therefore call veg1 rather than veg2
!-------------------------------------------------------------------------------

!$TAF INCOMPLETE lai,g_leaf_acc,frac,canht_ft,catch,z0_tile,g_leaf_day,     &
!$TAF&           g_leaf_phen,lai_phen,infil_tile,catch_snow 

        CALL veg1( land_pts,ntiles,can_model,a_step,phenol_period,l_phenol  &
                  ,timestep,satcon,g_leaf_acc,frac,lai,canht_ft             &
                  ,catch_snow,catch,infil_tile,z0_tile                      &
                  ,g_leaf_day,g_leaf_phen,lai_phen )

    ENDIF  !  triffid_call

  ENDIF   !  routeonly

  END SUBROUTINE control
