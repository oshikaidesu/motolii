# How the 8 seconds at the top of the guide were made

[日本語](make_intro_movie.ja.md)

How the 8 seconds at the top of the [guide](guide.md) were made. Once the engine is assembled (README, "Build and run"), paste the calls below into a shell at the repository's root. They write `~/Movies/Motolii/mv.mp4`.

![Glowing text, a spinning pink ring, a line pattern, a colour shift](../pictures/mv.gif)

Each line is one command of `engine/edit.sh` (`help` lists them all): the Weave recipe, a 3D ring, text, Glow, and last an RGB shift over the whole screen (`shelves/effects/glitch/rgbshift.wgsl`).

```zsh
mkdir -p ~/Movies/Motolii && rm -f ~/Movies/Motolii/mv.motolii
engine/edit.sh ~/Movies/Motolii/mv.motolii <<EOF | grep -E 'NOT|write'
make Weave
add solid ring
say 2 fill ff3366
set 2 size 1.1
set 2 metallic 0.6
set 2 roughness 0.2
key 2 rotate_y 0 0
key 2 rotate_y 8 360
key 2 rotate_x 0 25
key 2 rotate_x 8 -25
add text /System/Library/Fonts/Supplemental/Arial Black.ttf
say 3 text MOTOLII
say 3 fill ffffff
set 3 size 0.26
key 3 y 0 -2.4
key 3 y 1.5 -1.25
key 3 opacity 0 0
key 3 opacity 1.5 1
effect 3 Glow
say 0 script $PWD/shelves/effects/glitch/rgbshift.wgsl
write $HOME/Movies/Motolii/mv.mp4
EOF
```
