model BasicBuilder -ndm 3 -ndf 3


# define nodes
set Verbose 0;
set Verbose 1;

set USEPML 0;
set LX 50;
set LY 1.0;
set LZ 1.0;
set NX 50;
set NY 1;
set NZ 1;
set dx [expr $LX/$NX];
set dy [expr $LY/$NY];
set dz [expr $LZ/$NZ];



# define material
set Vs 200.;# m/s
set v 0.3;  # Poisson's ratio
set den 2000; # kg/m^3
set G [expr $Vs*$Vs*$den]; # kPa
set E [expr 2.0*$G*(1.0+$v)]; # Pa
set rho [expr $den/1000.0]; # ton/m^3
set E [expr $E/1000.0]; # MPa
set E 2.0e6; # kPa
set nu 0.3;  # Poisson's ratio
set rho 1.0; # ton/m^3
set matTag 1;

nDMaterial ElasticIsotropic $matTag $E $v $rho



# define nodes
for {set i 0} {$i <= $NX} {incr i} {
    for {set j 0} {$j <= $NY} {incr j} {
        for {set k 0} {$k <= $NZ} {incr k} {
            set nodeTag [expr $i*($NY+1)*($NZ+1) + $j*($NZ+1) + $k + 1];
            set x [expr $i*$dx];
            set y [expr $j*$dy];
            set z [expr $k*$dz];
            node $nodeTag $x $y $z;
            if {$Verbose} {
                puts "node $nodeTag $x $y $z";
            }
        }
    }
}



# define elements
for {set i 0} {$i < $NX} {incr i} {
    for {set j 0} {$j < $NY} {incr j} {
        for {set k 0} {$k < $NZ} {incr k} {
            set eleTag [expr $i*($NY)*($NZ) + $j*($NZ) + $k + 1];
            set node1 [expr $i*($NY+1)*($NZ+1) + $j*($NZ+1) + $k + 1];
            set node2 [expr ($i+1)*($NY+1)*($NZ+1) + $j*($NZ+1) + $k + 1];
            set node3 [expr ($i+1)*($NY+1)*($NZ+1) + ($j+1)*($NZ+1) + $k + 1];
            set node4 [expr $i*($NY+1)*($NZ+1) + ($j+1)*($NZ+1) + $k + 1];
            set node5 [expr $i*($NY+1)*($NZ+1) + $j*($NZ+1) + ($k+1) + 1];
            set node6 [expr ($i+1)*($NY+1)*($NZ+1) + $j*($NZ+1) + ($k+1) + 1];
            set node7 [expr ($i+1)*($NY+1)*($NZ+1) + ($j+1)*($NZ+1) + ($k+1) + 1];
            set node8 [expr $i*($NY+1)*($NZ+1) + ($j+1)*($NZ+1) + ($k+1) + 1];
            set b1    0.0;
            set b2    0.0;
            set b3    0.0;
            element stdBrick $eleTag $node1 $node2 $node3 $node4 $node5 $node6 $node7 $node8 $matTag $b1 $b2 $b3;
            if {$Verbose} {
                puts "element stdBrick $eleTag $node1 $node2 $node3 $node4 $node5 $node6 $node7 $node8 $matTag $b1 $b2 $b3";
            }
        }
    }
}

# define boundary conditions
# Find the maximum coordinate in the x direction
set nodeTags [getNodeTags]
set maxX 0.0
foreach nodeTag $nodeTags {
    set x [nodeCoord $nodeTag 1]
    if {$x > $maxX} {
        set maxX $x
    }
}

if {$USEPML} {
    # using PML
    puts "Using PML"
    fixX $maxX 1 1 1 1 1 1 1 1 1
} else {
    # using free field
    puts "Using fixed boundary"
    fixX $maxX 1 1 1
}
if {$Verbose} {
    puts "maxX: $maxX"
    puts "Fixing nodes at x = $maxX"
}


# find corner nodes
set CornerNodes {}
set BorderNodes {}
set InteriorNodes {}
foreach nodeTag $nodeTags {

    set xCoord [nodeCoord $nodeTag 1]
    set yCoord [nodeCoord $nodeTag 2]
    set zCoord [nodeCoord $nodeTag 3]
    if { abs($xCoord) < 1.0e-6 } {
        if { abs($yCoord) < 1.0e-6 } {
            if { abs($zCoord) < 1.0e-6 || abs($zCoord - $LZ) < 1.0e-6 } {
                lappend CornerNodes $nodeTag
            } else {
                lappend BorderNodes $nodeTag
            }
        } elseif { abs($yCoord - $LY) < 1.0e-6 } {
            if { abs($zCoord) < 1.0e-6 || abs($zCoord - $LZ) < 1.0e-6 } {
                lappend CornerNodes $nodeTag
            } else {
                lappend BorderNodes $nodeTag
            }
        } elseif { abs($zCoord) < 1.0e-6 || abs($zCoord - $LZ) < 1.0e-6 } {
            lappend BorderNodes $nodeTag
        } else {
            lappend InteriorNodes $nodeTag
        }
    }
}
if {$Verbose} {
    puts "CornerNodes: $CornerNodes"
    puts "BorderNodes: $BorderNodes"
    puts "InteriorNodes: $InteriorNodes"
}


# define loads
set patternTag 1;
set tsTag 1;
set cFactor 1.0;

# calculting different load factors
set Total    [expr $NY*$NZ]
set Corner   [expr 1.0/($Total)/4.0]
set Border   [expr 1.0/($Total)/2.0]
set Interior [expr 1.0/($Total)/1.0]

if {$Verbose} {
    puts "Total: $Total"
    puts "Corner: $Corner"
    puts "Border: $Border"
    puts "Interior: $Interior"
}

set tsTag 1;
timeSeries Path $tsTag -fileTime "Load/LoadTime.txt" -filePath "Load/LoadForce.txt" 

pattern Plain $patternTag $tsTag -fact $cFactor {
    foreach nodeTag $CornerNodes {
        load $nodeTag $CornerLoad 0.0 0.0
    }
    
    foreach nodeTag $BorderNodes {
        load $nodeTag $BorderLoad 0.0 0.0
    }
    foreach nodeTag $InteriorNodes {
        load $nodeTag $InteriorLoad 0.0 0.0
    }
}


# define analysis
constraints Transformation;
numberer RCM;
system BandGeneral;
test NormDispIncr 1.0e-6 10;
algorithm Linear -factorOnce
integrator LoadControl 1.0;
analysis Transient;
set dt 0.02








