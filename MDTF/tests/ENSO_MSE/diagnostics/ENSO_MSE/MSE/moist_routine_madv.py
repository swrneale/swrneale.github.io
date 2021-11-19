import numpy as np

'''
    routine to calculate the horizontal moisture advection and its
    vertical integral
    
    INPUT: 3 dimensional atmospheric variables:
    dimensions:  IMAX, JMAX, ZMAX
    variables : HGT: geopotential height [m]
               TA : temperature [K]
               HUS:  specific humidity [kg/kg]
               UA:  U wind compoment [m/s]
               VA:  V wind component [m/s]
    1 dimensional INPUT:
         LON(IMAX) - longitude deg.
         LAT(JMAX) - latitude deg.
         PLEV(ZMAX) - pressure levels [mb]
         REARTH  - radius of earth in  [m]

OUTPUT: MADV3  3 dimensional horizontal moisture advection  [W/kg]
        MADV1  2 dimensional vertical integral of
                      horizontal moisture advection  [W/m2]
missing data are flaged by UNDEF which is a very large number
'''

def moisture_adv(imax, jmax, zmax, lon, lat, plev, hgt, ta, hus, ua, va, rearth):
    # various constants
    pi = 4.0 * np.arctan(1.0)
    lh = 2.5e+6
    cp = 1004.0
    
    rd = 287.0
    gg = 9.82
 
    plev = plev.reshape((1,1,zmax), order='F')
    rho = plev * 100./(rd * ta)

##     vertical differentiation 
    kk = np.arange(0, zmax)
    k1 = np.fmax(0, kk-1)
    k2 = np.fmin(zmax-1, kk+1)
    dz = 0.5 * (hgt[:, :, k2] - hgt[:, :, k1])

###   similar make dx and dy centered horizontal differentiation  
    ii = np.arange(0, imax)
    i1 = np.fmax( 0, ii-1)
    i2 = np.fmin( imax-1, ii+1)
 
    jj = np.arange(0, jmax)
    j1 = np.fmax( 1, jj-1)
    j2 = np.fmin( jmax-2, jj+1)
     
    lon = lon.reshape( (imax, 1, 1), order = 'F')
    lat = lat.reshape( (1, jmax, 1), order = 'F') 
    dxx =  rearth * np.cos(lat[:, jj, :]*pi/180.0) * (lon[i2, :, :]-lon[i1, :, :]) * pi/180.0 
    dyy =  rearth * (lat[:,j2, :] - lat[:,j1, :]) * pi/180.0
####
##    moisture advection 
    madv3 = - lh * ( ua[:,:,:] * (hus[i2,:,:]-hus[i1,:,:])/dxx[:,:,:] +   \
                     va[:,:,:] * (hus[:,j2,:]-hus[:,j1,:])/dyy[:,:,:]  )


    madv3.mask[:, 0, :] = True
    madv3.mask[:, jmax-1, :] = True

    madv1 = np.sum( rho * madv3 * dz, axis = 2)
    return madv1, madv3
