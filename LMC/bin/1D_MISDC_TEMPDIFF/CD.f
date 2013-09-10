c     Initialize some values
      block data chemdat
      include 'spec.h'
      data traninit / -1 /
      data Pcgs / -1 /
      data iH2  / -1 /
      data iO2  / -1 /
      data iN2  / -1 /
      data iCH4 / -1 /
      end

      subroutine calc_diffusivities(scal, beta, mu, lo, hi)
      implicit none
      include 'spec.h'
      double precision scal(-2:nfine+1,nscal)
      double precision beta(-1:nfine  ,nscal)
      double precision   mu(-1:nfine)
      integer lo, hi

      double precision Dt(Nspec), CPMS(Nspec), Y(Nspec)
      double precision Tt, Wavg, rho
      double precision X(Nspec), alpha, l1, l2, cpmix, RWRK
      integer n, i, IWRK

      double precision fourThirds

      fourThirds = 4.d0 / 3.d0

c     Ensure chem/tran initialized
      if (traninit.lt.0) call initchem()

      if (LeEQ1 .eq. 0) then
         
         do i=lo-1,hi+1
            Tt = MAX(scal(i,Temp),TMIN_TRANS) 
            rho = 0.d0
            do n=1,Nspec
               rho = rho + scal(i,FirstSpec+n-1)
            enddo
            do n=1,Nspec
C               Y(n) = scal(i,FirstSpec+n-1) / scal(i,Density)
               Y(n) = scal(i,FirstSpec+n-1) / rho
            enddo
            
c           given y[species]: maxx fractions
c           returns mean molecular weight (gm/mole)
            CALL CKMMWY(Y,IWRK,RWRK,Wavg)

c           returns the specific heats at constant pressure
c           in mass units
            CALL CKCPMS(Tt,IWRK,RWRK,CPMS)

c           convert y[species] (mass fracs) to x[species] (mole fracs)
            CALL CKYTX(Y,IWRK,RWRK,X)

c           initialize the thermomolecular parameters that are needed in order
c           to evaluate the transport linear systems
            CALL EGSPAR(Tt,X,Y,CPMS,EGRWRK,EGIWRK)

c           compute flux diffusion coefficients
            CALL EGSV1(Pcgs,Tt,Y,Wavg,EGRWRK,Dt)

            do n=1,Nspec
               beta(i,FirstSpec+n-1)
     &              = rho * Wavg * invmwt(n) * Dt(n)
            end do

            alpha = 1.0D0
c           compute thermal conductivity
            CALL EGSL1(alpha, Tt, X, EGRWRK, l1)
            alpha = -1.0D0
c           compute thermal conductivity with a different averating parameters
            CALL EGSL1(alpha, Tt, X, EGRWRK, l2)
            beta(i,Temp) = .5d0 * (l1 + l2)
c           Returns the mean specific heat at CP
            CALL CKCPBS(scal(i,Temp),Y,IWRK,RWRK,CPMIX)
            beta(i,RhoH) = beta(i,Temp) / CPMIX

c           compute shear viscosity
            CALL EGSE3(Tt, Y, EGRWRK, mu(i))            
            mu(i) = fourThirds*mu(i)
         enddo
      else
         do i=lo-1,hi+1
c     Kanuary, Combustion Phenomena (Wiley, New York) 1982:  mu [g/(cm.s)] = 10 mu[kg/(m.s)]
            mu(i) = 10.d0 * 1.85d-5*(MAX(scal(i,Temp),1.d0)/298.d0)**.7d0
c     For Le=1, rho.D = lambda/cp = mu/Pr  (in general, Le = Sc/Pr)
            rho = 0.d0
            do n=1,Nspec
               beta(i,FirstSpec+n-1) = mu(i) / Sc
               rho = rho + scal(i,FirstSpec+n-1)
            enddo
            
            do n=1,Nspec
               Y(n) = scal(i,FirstSpec+n-1) / rho
            enddo
c           Returns the mean specific heat at CP
            CALL CKCPBS(scal(i,Temp),Y,IWRK,RWRK,CPMIX)
            beta(i,RhoH) = mu(i) / Pr
            beta(i,Temp) = beta(i,RhoH) * CPMIX

            mu(i) = fourThirds*mu(i)
         enddo
      endif

      end

      subroutine calc_lambda_cp(scal, beta, cp, lo, hi)
      implicit none
      include 'spec.h'
      double precision scal(-2:nfine+1,nscal)
      double precision beta(-1:nfine  ,nscal)
      double precision   cp(0:nfine-1)
      integer lo, hi

      double precision Dt(Nspec), CPMS(Nspec), Y(Nspec)
      double precision Tt, Wavg, rho
      double precision X(Nspec), alpha, l1, l2, cpmix, RWRK
      integer n, i, IWRK

      double precision fourThirds

      fourThirds = 4.d0 / 3.d0

c     Ensure chem/tran initialized
      if (traninit.lt.0) call initchem()

      if (LeEQ1 .eq. 0) then
         
         do i=lo-1,hi+1
            Tt = MAX(scal(i,Temp),TMIN_TRANS) 
            rho = 0.d0
            do n=1,Nspec
               rho = rho + scal(i,FirstSpec+n-1)
            enddo
            do n=1,Nspec
               Y(n) = scal(i,FirstSpec+n-1) / rho
            enddo
            
c           given y[species]: maxx fractions
c           returns mean molecular weight (gm/mole)
            CALL CKMMWY(Y,IWRK,RWRK,Wavg)

c           returns the specific heats at constant pressure
c           in mass units
            CALL CKCPMS(Tt,IWRK,RWRK,CPMS)

c           convert y[species] (mass fracs) to x[species] (mole fracs)
            CALL CKYTX(Y,IWRK,RWRK,X)

c           initialize the thermomolecular parameters that are needed in order
c           to evaluate the transport linear systems
            CALL EGSPAR(Tt,X,Y,CPMS,EGRWRK,EGIWRK)

c           compute flux diffusion coefficients
            CALL EGSV1(Pcgs,Tt,Y,Wavg,EGRWRK,Dt)

            alpha = 1.0D0
c           compute thermal conductivity
            CALL EGSL1(alpha, Tt, X, EGRWRK, l1)
            alpha = -1.0D0
c           compute thermal conductivity with a different averating parameters
            CALL EGSL1(alpha, Tt, X, EGRWRK, l2)
            beta(i,Temp) = .5d0 * (l1 + l2)
c           Returns the mean specific heat at CP
            CALL CKCPBS(scal(i,Temp),Y,IWRK,RWRK,CPMIX)
            if (i .ne. lo-1 .and. i .ne. hi+1) then
               cp(i) = CPMIX
            end if

         enddo
      else

         print*,"ERROR: calling calc_lambda_cp with unity Le"
         stop

      endif

      end

      subroutine initchem
      implicit none
      include 'spec.h'
      double precision RU, RUC, RWRK, RDUMMY
      integer lout, IWRK, n, len, offset, IDUMMY
      integer kname(maxspnml*maxspec)

      if (traninit.lt.0) then
c         open(unit=51,status='old',form='formatted',file=tranfile)

c     This sets Nspec
         CALL CKINDX(IDUMMY,RDUMMY,Nelt,Nspec,Nreac,Nfit)

         lout = 6
         call EGINI(eg_nodes, lout, eg_IFLAG, eg_ITLS,
     &        EGRWRK, egr, EGIWRK, egi)

c     Other useful things
         call CKRP(IWRK, RWRK, RU, RUC, P1ATM)
         call CKWT(IWRK, RWRK, mwt)
     
         do n=1,Nspec
            invmwt(n) = 1.d0 / mwt(n)
         end do

         call cksyms(kname,maxspnml)
         do n=1,Nspec
            offset = (n-1)*maxspnml+1
            call convStr(kname(offset),maxspnml,specNames(n),len)
            if (specNames(n).eq.'H2')  iH2=n
            if (specNames(n).eq.'O2')  iO2=n
            if (specNames(n).eq.'N2')  iN2=n
            if (specNames(n).eq.'CH4') iCH4=n
            if (specNames(n).eq.'CH3OCH3') iCH3OCH3=n
            if (specNames(n).eq.'CO2') iCO2=n
            if (specNames(n).eq.'H2O') iH2O=n
         enddo
         traninit = 1
      endif
      end

      subroutine convStr(codedString,maxLen,string,strLen)
      implicit none
      integer codedString(*), maxLen, k, strLen
      character*(*) string
      do k=1,maxLen
         string(k:k) = ' '
         if (codedString(k) .ne. ICHAR(' ')) then
            string(k:k) = CHAR(codedString(k))
            strLen = k
         endif
      enddo
      end


      subroutine vodeF_T_RhoY(NEQ, TIME, Z, ZP, RPAR, IPAR)
      implicit none
      include 'spec.h'
      double precision TIME, Z(0:Nspec), ZP(0:Nspec), RPAR(*)
      integer NEQ, IPAR(*)
      
      double precision RHO, CPB, SUM, Y(Nspec)
      double precision HK(Nspec), WDOTK(Nspec), C(Nspec), RWRK
      integer K, IWRK

      integer NiterMAX, Niter
      parameter (NiterMAX = 30)
      double precision res(NiterMAX), errMAX, hmix, T

C     For strang
C     Variables in Z are:  Z(0)   = T
C                          Z(K) = Y(K)
C
C     For SDC
C     Variables in Z are:  Z(0)   = rho*h
C                          Z(K) = rho*Y(K)


      if (Pcgs.lt.0.d0) then
         print *,'vodeF_T_RhoY: Must set Pcgs before calling vode'
         stop
      endif

      RHO = 0.d0
      do K=1,Nspec
         RHO = RHO + Z(K)
      enddo
      
      do K=1,Nspec
         if (lim_rxns .eq. 0) then
            C(K) = Z(K)*invmwt(K)
         else
            C(K) = MAX(0.d0,Z(K)*invmwt(K))
         endif
         Y(K) = Z(K)/RHO
      enddo

      T = T_INIT
      hmix = (rhoh_INIT + c_0(0)*
     &     TIME + c_1(0)*TIME*TIME*0.5d0)/RHO
      errMax = hmix_TYP*1.e-20
      call FORT_TfromHYpt(T,hmix,Y,Nspec,errMax,NiterMAX,
     &     res,Niter)
      T_INIT = T
      if (Niter.lt.0) then
         print *,'vodeF_T_RhoY: H to T solve failed'
         print *,'Niter=',Niter
         stop
      endif

      call CKWC(T,C,IWRK,RWRK,WDOTK)
      do k= 1, Nspec
         ZP(k) = WDOTK(k)*mwt(k) + c_0(k) + c_1(k)*TIME
      end do
      ZP(0) = c_0(0) + c_1(0)*TIME 

      END

      subroutine vodeJ(NEQ, T, Y, ML, MU, PD, NRPD, RPAR, IPAR)
      implicit none
      integer NEQ, NRPD, ML, MU, IPAR(*)
      double precision T, Y(NEQ), PD(NRPD,NEQ), RPAR(*)
      print *,'Should not be in vodeJ'
      stop
      end




      subroutine chemsolve(RYnew, Tnew, RYold, Told, FuncCount, dt,
     &     diag, do_diag, ifail, i)
      implicit none
      include 'spec.h'

      double precision YJ_SAVE(80)
      logical FIRST
      common /VHACK/ YJ_SAVE, FIRST
      save   /VHACK/

      integer do_diag, ifail, FuncCount, i
      double precision RYold(*), RYnew(*), Told, Tnew
      double precision dt, diag(*)
   
      integer NEQ, ITOL, IOPT, ITASK, open_vode_failure_file
      parameter (ITOL=1, IOPT=1, ITASK=1)
      double precision RTOL, ATOL(Nspec+1), ATOLEPS, TT1, TT2
C      parameter (RTOL=1.0E-8, ATOLEPS=1.0E-8)
      parameter (RTOL=1.0D-13, ATOLEPS=1.0D-13)
      external vodeF_T_RhoY, vodeJ, open_vode_failure_file
      integer n, MF, ISTATE

      integer nsubchem, nsub, node
      double precision dtloc, weight, TT1save
      double precision C(Nspec),Q(Nreac)

c     DVODE workspace requirements      
      integer dvr, dvi

c     METH = 2 (backward diffs)
c     MAXORD = 5
c     NEQ = Nspec+1 
c     NYH = NEQ = Nspec+1
c     MITER = 2
c     JSV = 1
c     JSV = SIGN(MF)
c     MF = JSV*(10*METH + MITER) = 22
c     LWM = 2*(Nspec+1)**2 + 2    (MITER = 2, MF<0)
c     lenr = 20 + NYH*(MAXORD + 1) + 3*NEQ + LWM
c          = 20 + (Nspec+1)*(6) + 3*(Nspec+1) + 2*(Nspec+1)**2 + 2
c          = 22 + (Nspec+1)*9 + 2*(Nspec+1)**2
c     
      parameter (dvr = 22 + 9*(maxspec+1) + 2*(maxspec+1)**2)
      parameter (dvi = 30 + maxspec + 1)
      
      double precision DVRWRK(dvr)
      integer DVIWRK(dvi)

      common / VODE_SPACE / dvrwrk, dviwrk
      save / VODE_SPACE /

      double precision Z(0:Nspec)
      double precision RPAR, RWRK
      integer IPAR, IWRK

c     IOPT=1 parameter settings for VODE
C      DVRWRK(1) = 0.d0
C      DVRWRK(2) = 0.d0
C      DVRWRK(3) = 0.d0
C      DVRWRK(4) = 0.d0
      DVRWRK(5) = 0.d0
      DVRWRK(6) = 0.d0
      DVRWRK(7) = min_vode_timestep
C      DVRWRK(8) = 0.d0
C      DVRWRK(9) = 0.d0
C      DVRWRK(10) = 0.d0
C      DVIWRK(1) = 0
C      DVIWRK(2) = 0
C      DVIWRK(3) = 0
C      DVIWRK(4) = 0
      DVIWRK(5) = 0
      DVIWRK(6) = max_vode_subcycles
      DVIWRK(7) = 0
C      DVIWRK(8) = 0
C      DVIWRK(9) = 0
C      DVIWRK(10) = 0

      if (do_diag.eq.1) nsubchem = nchemdiag

      
      MF = 22
      ATOL(1) = ATOLEPS
      TT1 = 0.d0
      TT2 = dt
      if (do_diag.eq.1) then
         nsub = nsubchem
         dtloc = dt/nsubchem
      else
         nsub = 1
         dtloc = dt
      endif
      ISTATE = 1
      NEQ = Nspec + 1


      Z(0) = Told
      do n=1,Nspec
         Z(n) = RYold(n)
      end do

c     Always form Jacobian to start
      if (i .eq. 0) then
         FIRST = .TRUE.
      else
         FIRST = .FALSE.
      end if

      ifail = 0
      do node = 1,nsub
         if (node.lt.nsub) then
            weight = 1.d0
         else
            weight = 0.5d0
         endif

         TT1save = TT1
         TT2 = TT1 + dtloc

c     HACK
         FIRST = .TRUE.

         CALL DVODE
     &        (vodeF_T_RhoY, NEQ, Z(0), TT1, TT2, ITOL, RTOL, ATOL,
     &        ITASK, ISTATE, IOPT, DVRWRK, dvr, DVIWRK,
     &        dvi, vodeJ, MF, RPAR, IPAR)

         TT1 = TT2

         FuncCount = DVIWRK(11)

         if (ISTATE.LE.-1  .or.  verbose_vode .eq. 1) then
            write(6,*) '......dvode done:'
            write(6,*) ' last successful step size = ',DVRWRK(11)
            write(6,*) '          next step to try = ',DVRWRK(12)
            write(6,*) '   integrated time reached = ',DVRWRK(13)
            write(6,*) '      number of time steps = ',DVIWRK(11)
            write(6,*) '              number of fs = ',DVIWRK(12)
            write(6,*) '              number of Js = ',DVIWRK(13)
            write(6,*) '    method order last used = ',DVIWRK(14)
            write(6,*) '   method order to be used = ',DVIWRK(15)
            write(6,*) '            number of LUDs = ',DVIWRK(19)
            write(6,*) ' number of Newton iterations ',DVIWRK(20)
            write(6,*) ' number of Newton failures = ',DVIWRK(21)
            write(6,*) '     comp with largest err = ',DVIWRK(16)

            print *,'Input state:'
            print *,'T:',Told
            print *,'RY:',(RYold(n),n=1,Nspec)
         end if

         Tnew = Z(0)
         do n=1,Nspec
            RYnew(n) = Z(n)
         end do

         if (ISTATE.LE.-1) ifail = 1

      enddo
      end


      subroutine FORT_TfromHYpt(T,Hin,Y,Nspec,errMax,NiterMAX,res,Niter)
      implicit none
      double precision T,Y(*),H,Hin
      double precision TMIN,TMAX,errMAX
      integer Nspec,NiterMAX,Niter,n,NiterDAMP, Discont_NiterMAX
      parameter (TMIN=250, TMAX=5000, Discont_NiterMAX=100)
      double precision  T0,cp,dH,temp
      double precision res(0:NiterMAX-1),dT, Htarg
      logical out_of_bounds, converged, soln_bad, stalled
      double precision HMIN,cpMIN,HMAX,cpMAX
      integer ihitlo,ihithi,IWRK
      double precision old_T, old_H, Tsec, Hsec, RWRK

      out_of_bounds(temp) = (temp.lt.TMIN-1.d0) .or. (temp.gt.TMAX)

      NiterDAMP = NiterMAX
      if ((T.GE.TMIN).and.(T.LE.TMAX)) then
         T0 = T
      else
         T0 = 0.5d0*(TMIN+TMAX)
         T = T0
      end if
      Niter = 0
      soln_bad = .FALSE.
c     Hin in MKS, convert to CGS
c      Htarg = Hin * 1.d4
      Htarg = Hin
      ihitlo = 0
      ihithi = 0

      CALL CKHBMS(T,Y,IWRK,RWRK,H)

      old_T = T
      old_H = H

      Htarg = Hin

      dH = 2.d0*ABS(H - Htarg)/(1.d0 + ABS(H) + ABS(Htarg))
      res(Niter) = dH
      converged = dH.le.errMAX
      stalled = .false.

      do while ((.not.converged) .and. 
     &     (.not.stalled) .and.
     &     (.not.soln_bad))

         CALL CKCPBS(T,Y,IWRK,RWRK,cp)
         dT = (Htarg - H)/cp
         old_T = T
         if ((Niter.le.NiterDAMP).and.(T+dT.ge.TMAX)) then
            T = TMAX
            ihithi = 1
         else if ((Niter.le.NiterDAMP).and.(T+dT.le.TMIN)) then
            T = TMIN
            ihitlo = 1
         else
            T = T + dT
         end if
         soln_bad = out_of_bounds(T)
         if (soln_bad) then
            Niter = -1
            goto 100
         else
            old_H = H
            CALL CKHBMS(T,Y,IWRK,RWRK,H)
            dH = 2.d0*ABS(H - Htarg)/(1.d0 + ABS(H) + ABS(Htarg))
            res(Niter) = min(dH,abs(dT))
            Niter = Niter + 1
         end if
         converged = (dH.le.errMAX)
         stalled = (ABS(dT).le.errMAX)
         if ((ihitlo.eq.1).and.(H.gt.Htarg)) then
            T = TMIN
            CALL CKHBMS(T,Y,IWRK,RWRK,HMIN)
            CALL CKCPBS(T,Y,IWRK,RWRK,cpMIN)
            T=TMIN+(Htarg-HMIN)/cpMIN
            converged = .true.
         endif
         if ((ihithi.eq.1).and.(H.lt.Htarg)) then
            T = TMAX
            CALL CKHBMS(T,Y,IWRK,RWRK,HMAX)
            CALL CKCPBS(T,Y,IWRK,RWRK,cpMAX)
            T=TMAX+(Htarg-HMAX)/cpMAX
            converged = .true.
         endif

c     If the iterations are failing, perhaps it is because the fits are discontinuous
c     The following implements a modified secant method to hone in on a discontinity in h
c     with T.  Discont_NiterMAX is fairly large because this process can be particularly
c     slow to converge if the Htarg value happens to lay between the discontinuous function
c     values.  
         if (Niter .ge. NiterMAX) then
            do while (.not. stalled)
               dT = - (H - Htarg) * (old_T - T)/(old_H - H)
               Tsec = T + dT
               soln_bad = out_of_bounds(Tsec)
               if (soln_bad) then
                  Niter = -3
                  goto 100
               endif
               CALL CKHBMS(Tsec,Y,IWRK,RWRK,Hsec)
               if ( (Hsec-Htarg)*(Htarg-H) .gt. 0.d0 ) then
                  old_H = H
                  old_T = T
               endif
               H = Hsec
               T = Tsec
               stalled = (ABS(dT).le.errMAX)
               Niter = Niter + 1
               if (Niter.gt.NiterMAX+Discont_NiterMAX) then
                  Niter = -2
                  goto 100
               endif
            enddo
            converged = .true.
         endif
      end do

      return
c
c     Error condition....dump state and bail out
c
 100  continue

      write(6,997) 'T from (H,Y): failed'
      write(6,997) 'iterations tried = ',Niter
      write(6,998) 'initial T = ',T0
      write(6,998) 'current T = ',T
      write(6,998) 'previous T = ',old_T
      write(6,998) 'target H = ',Htarg
      write(6,998) 'species mass fracs:'
      do n = 1,Nspec
         write(6,998) '  ',Y(n)
      end do
      write(6,998)
      write(6,998) 'residual:'
      do n = 0,NiterMAX-1
         write(6,998) '  ',res(n)
      end do

 997  format(a,3(i4,a))
 998  format(a,d21.12)
      end
  
      integer function open_vode_failure_file ()
      implicit none
      character*30 name, myproc
      integer lout,i,j,k,idx

c     Hardwire the unit number to 26 for the moment
      lout = 26 
c      call bl_pd_myproc(i)
      i = 0
      write(myproc, *) i
      idx = 1 
      do j = 1, 30
         if (myproc(j:j) .ne. ' ') then
            idx = j
            goto 1
         end if 
      end do
 1    continue
      do k = 30, j+1, -1
         if (myproc(k:k) .ne. ' ') then
            goto 2
         end if
      end do
 2    continue
      write(name, '(2a)') 'vode.failed.', myproc(idx:k)
c      write(name, '(2a)') 'vode.failed.', myproc(idx:30)
      open(unit=lout, file=name, form='formatted', status='replace')
      open_vode_failure_file = lout
      end

