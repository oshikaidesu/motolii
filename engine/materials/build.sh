#!/bin/zsh
# The Filament materials (materials/*.mat) compiled by Filament's own matc into out/filament_webgpu/*.filamat, and the
# rooms' light made once by Filament's cmgen. Called by build.sh after deps/filament.sh; a material is compiled again
# only when its .mat or a .glsl it includes is newer.
set -e
cd "$(dirname "$0")/.."
SRC=third_party/filament_src
MATC=$SRC/out/wgpu/tools/matc/matc
mkdir -p out/filament_webgpu/out
# (the rooms' light, made once by Filament's own cmgen from its environments, as poster.sh and blocks.sh make them with the SDK's)
[ -f out/small_studio/small_studio_ibl.ktx ] && [ -f out/lightroom/lightroom_ibl.ktx ] || (cd $SRC/out/wgpu && ninja cmgen > /dev/null)
[ -f out/small_studio/small_studio_ibl.ktx ] || $SRC/out/wgpu/tools/cmgen/cmgen -q -x out/small_studio --format=ktx --size=512 $SRC/third_party/environments/studio_small_02_2k.hdr
[ -f out/lightroom/lightroom_ibl.ktx ] || $SRC/out/wgpu/tools/cmgen/cmgen -q -x out/lightroom --format=ktx --size=512 $SRC/third_party/environments/lightroom_14b.hdr
for d in lightroom small_studio graffiti_shelter_2k studio_small_02_2k venetian_crossroads_2k parking_garage_2k pillars_2k; do [ -d out/$d ] && ln -sfn ../../$d out/filament_webgpu/out/$d 2> /dev/null; done; true
for f in effected effected_world effected_solid thick_glass far_side far_look bubble poster own_glass flat blade matte floor_lit solid_cloth solid_subsurface shape points solid_image sketch; do
    [ -f materials/$f.mat ] || continue
    [ out/filament_webgpu/$f.filamat -nt materials/$f.mat ] && [ out/filament_webgpu/$f.filamat -nt materials/studio.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/spectrum.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/matte.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/blend_way.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/deep.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/deep_vertex.glsl ] && continue
    shade=lit; [ $f = flat ] && shade=unlit
    $MATC -a webgpu -a metal -p desktop -TBLENDING=transparent -TCUT=opaque -TSHADE=$shade -o out/filament_webgpu/$f.filamat materials/$f.mat > out/filament_webgpu/$f.log 2>&1 ||
        $MATC -g -a webgpu -a metal -p desktop -TBLENDING=transparent -TCUT=opaque -o out/filament_webgpu/$f.filamat materials/$f.mat > out/filament_webgpu/$f.log 2>&1 ||
        echo "no WebGPU material: $f (out/filament_webgpu/$f.log)"
    [ $f = floor_lit ] && { $MATC -a webgpu -a metal -p desktop -TBLENDING=transparent -TCUT=masked -o out/filament_webgpu/floor_lit_matte.filamat materials/floor_lit.mat > out/filament_webgpu/floor_lit_matte.log 2>&1 ||
        echo "no WebGPU material: floor_lit_matte"; }   # (the same, cut by a matte: what the matte leaves out is not rendered, materials/matte.glsl)
    [ $f = solid_image ] && { $MATC -a webgpu -a metal -p desktop -TSHADE=unlit -DFLAT -o out/filament_webgpu/solid_image_flat.filamat materials/solid_image.mat > out/filament_webgpu/solid_image_flat.log 2>&1 ||
        echo "no WebGPU material: solid_image_flat"; }   # (the same, unlit)
    { [ $f = effected ] || [ $f = effected_world ]; } && for way in add multiply screen; do   # (a thing with effects of its own lies on what is behind as it says too, as flat's ways)
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$way -DLAY_$way -o out/filament_webgpu/${f}_$way.filamat materials/$f.mat > out/filament_webgpu/${f}_$way.log 2>&1 || echo "no WebGPU material: ${f}_$way"
    done
    [ $f = flat ] && for way in add multiply screen opaque; do   # (the ways a sheet lies on what is behind it: Filament's own blending; opaque: the colour behind everything, rendered before the solid things)
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$way -TSHADE=unlit -DLAY_$way -o out/filament_webgpu/flat_$way.filamat materials/flat.mat > out/filament_webgpu/flat_$way.log 2>&1 || echo "no WebGPU material: flat_$way"
    done
    [ $f = flat ] && for way in transparent add multiply screen; do   # (the same in the lamps' light; a soft edge's shine goes with it, Filament's fade: transparent keeps a highlight whole)
        blend=$way; [ $way = transparent ] && blend=fade
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$blend -TSHADE=lit -DLIT -DLAY_$way -o out/filament_webgpu/flat_lit_$way.filamat materials/flat.mat > out/filament_webgpu/flat_lit_$way.log 2>&1 || echo "no WebGPU material: flat_lit_$way"
    done
    [ $f = flat ] && for wear in wear:lit:WEAR:fade cloth:cloth:CLOTH:fade subsurface:subsurface:SUBSURFACE:fade lacquer:lit:LACQUER:fade bubble:lit:BUBBLE:transparent glass:unlit:GLASS:transparent; do   # (a material a flat thing wears, its image its colour: document/material.h doc_material, stage/render/render_stage.h flat_laid)
        parts=(${(s.:.)wear})
        lit=-DLIT; [ $parts[2] = unlit ] && lit=
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$parts[4] -TSHADE=$parts[2] $lit -D$parts[3] -o out/filament_webgpu/flat_$parts[1].filamat materials/flat.mat > out/filament_webgpu/flat_$parts[1].log 2>&1 || echo "no WebGPU material: flat_$parts[1] (out/filament_webgpu/flat_$parts[1].log)"
    done
    [ $f = bubble ] && { $MATC -a webgpu -a metal -p desktop -DWORN -o out/filament_webgpu/bubble_worn.filamat materials/bubble.mat > out/filament_webgpu/bubble_worn.log 2>&1 || echo "no WebGPU material: bubble_worn"; }   # (a thing wearing Bubble: stage/render/render_layers.h solid_wear)
done
