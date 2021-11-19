;;;   to  write seasonal composites El Nino/La Nina as netCDF
;;;      data for MSE element output in ~/inputdata/obs_data/DATA/netCDF
;;     5 variables madv, mdiv, mse, omse, tadv in CLIMA/ELNINO/LANINA

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin

     indir0  = getenv("ENSO_MSE_WKDIR_COMPOSITE") +"/obs/"
     indir = getenv("ENSO_MSE_WKDIR_MSE") +"/obs/" ; envvar set in ENSO_MSE.py,
                                ;processed output from other scripts in this package
     outdir = getenv("OBS_DATA") + "/DATA/" 
                        ;;  the standard location for pre-digested OBS data:  
                       ;; diagnostics/inputdata/obs_data/DATA then ELNINO or LANINA

;;;  read in the dimensions first 
      mode = (/ "ELNINO", "LANINA", "clim" /)
    ivar = 5

    varnames = (/ "madv", "mdiv", "mse",  "omse", "tadv" /)
    varunits =  (/ "[W/m2]", "[W/s2]", "[J/m2]", "[W/m2]", "[W/m2]" /)
    long_name = (/ "Moisture advection",  \
                    "Moisture divergence", \
                    "Moist Static Energy", \
                    "Vertical advection of MSE", \
                    "Temperature adection" /)

      name_dimensions = indir0  + "/netCDF/DATA/xyz_dimensions.txt"
      name_lon = indir0 + "/netCDF/DATA/longitude.out"
      name_lat = indir0 + "/netCDF/DATA/latitude.out"
      name_plevs = indir0 + "/netCDF/DATA/plevels.out"


;;;;  read in the parameter data lon/lat/plevs 
       dataxyz  = asciiread(name_dimensions,-1,"string")
       xdum  = str_get_field(dataxyz(0), 1," ")
       xmax =  stringtointeger( xdum)
       ydum  = str_get_field(dataxyz(1), 1," ")
       ymax =  stringtointeger( ydum)
       zdum  = str_get_field(dataxyz(2), 1," ")
       zmax =  stringtointeger( zdum)
       undef2 = 1.1E+20 
;;;  read in the lon/lat plevs here !!
      tt =  1
      dims3 = (/ tt, zmax, ymax, xmax /)
      dims2 = (/ tt, ymax, xmax /)
       lon = new( xmax, "float")
       lat = new( ymax, "float")
       lev = new( zmax, "float")
	lon@units = "degrees_east"
       lon@_FillValue = undef2
       lon@long_name = "longitude"

       lat@units = "degrees_north"
       lat@long_name = "latitude"
       lat@_FillValue = undef2

       lev@units  = "mb"
       lev@long_name = "pressure levels "
       lev@_FillValue = undef2
 

       lon = fbindirread (name_lon, 0, (/ xmax /) , "float")
       lat = fbindirread (name_lat, 0, (/ ymax /) , "float")
       lev = fbindirread (name_plevs, 0, (/ zmax /) , "float")

      time = new( tt, "float" )
      time = 0 

       time@units  = "months since 0001-01-01"
       time@long_name = "seasonal composites "
       time@_FillValue = -9999

;;;;    2D variables
       dimNames2 = (/"time", "lat", "lon" /)
       dimSizes2 = (/ -1   ,  ymax, xmax /)
       dimUnlim2 = (/ True ,  False, False/)

        datain2 =  new(  dims2, "float")
        datain2!2="lon"
        datain2!1="lat"
        datain2!0="time"

        datain2&lon = lon
        datain2&lat = lat
        datain2&time = time
        datain2@_FillValue =  undef2

;; predefine file attributes

      do n = 0, 2  ;;;  loop over El Nino/La Nina 
      do iv = 0,  ivar - 1
      namein  = indir + "/netCDF/" +  mode(n) + "/MSE_" + varnames(iv) + ".out"
      nameout = outdir + "/netCDF/" +  mode(n) + "/MSE_" + varnames(iv) + ".nc"

     if( n .eq. 2 ) 
       namein  = indir + "/netCDF/" + "/MSE_" + varnames(iv) + "_" + mode(n) +".out"
       nameout = outdir + "/netCDF/" + "/MSE_" + varnames(iv) + "_" + mode(n) + ".nc"
     end if
;;;  read in the data 

       datain2@units     = varunits(iv)
       datain2@long_name = long_name(iv)

       datain2  = fbindirread (namein, 0, dims2 , "float")
;;  set the dimensions and units 
;===================================================================
; create global attributes of the file
;===================================================================
     system("/bin/rm -f " + nameout)
     fout =  addfile( nameout, "c" )
     setfileoption(fout,"DefineMode",True)

       fAtt               = True            ; assign file attributes
	fAtt@title         = "seasonal composite " + mode(n) 
;;; 	fAtt@Conventions   = "None"   
	fAtt@creation_date = systemfunc ("date")        
	fileattdef( fout, fAtt ) 
;;;;;;;;;;;;;;;;; define all attributes here 

	filedimdef(fout, dimNames2, dimSizes2, dimUnlim2)

       filevardef(fout, "time" , typeof(time),  (/"time"/) ) 
       filevardef(fout, "lat"  , typeof(lat),   (/"lat"/) )                       
       filevardef(fout, "lon"  , typeof(lon),   (/"lon"/) )
       filevardef(fout,  varnames(iv), typeof(datain2),  dimNames2 )   

       filevarattdef(fout,"time" ,time)                    ; copy time attributes
       filevarattdef(fout,"lat"  ,lat)                     ; copy lat attributes
       filevarattdef(fout,"lon"  ,lon)                     ; copy lon attributes
       filevarattdef(fout, varnames(iv), datain2)               

       setfileoption(fout,"DefineMode",False)
       fout->time   = (/time/)     
       fout->lat    = (/lat/)
       fout->lon    = (/lon/) 
       fout->$varnames(iv)$  = (/datain2/)
       delete( fout) 

      print( nameout + " ") 
      
      end do  ;;  over 2D variables 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
     end do   ;;  over all  modes   El Nino/ La Nina + clima
      
end

