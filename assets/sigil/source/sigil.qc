$modelname "zombiesurvival/sigil/sigil.mdl"
$bodygroup "frame"
{
 studio "frame.smd"
 blank
}
$bodygroup "crystal"
{
 studio "crystal.smd"
 blank
}
$bodygroup "core"
{
 blank
 studio "core.smd"
}
$cdmaterials "zombiesurvival/sigil/"
$surfaceprop "metal"
$bbox -16.5 -16.5 -0.8937 16.5 16.5 104.5
$hboxset "default"
$hbox 0 "root" -16.5 -16.5 -0.8937 16.5 16.5 104.5
$sequence "idle" "idle.smd" fps 1
$collisionmodel "collision.smd"
{
 $mass 100
}
