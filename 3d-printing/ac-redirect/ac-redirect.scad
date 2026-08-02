// AC exhaust redirect: bolts to the window mount, lifts the flex duct off the sill.
//
// Render (Homebrew only ships OpenSCAD as a macOS cask, so use the flatpak):
//   flatpak run org.openscad.OpenSCAD -o ac-redirect.stl           ac-redirect.scad
//   flatpak run org.openscad.OpenSCAD -o ac-redirect-tail-test.stl -D 'part="tail_test"' ac-redirect.scad
//   flatpak run org.openscad.OpenSCAD -o ac-redirect-plate.stl     -D 'part="plate"'     ac-redirect.scad
//   flatpak run org.openscad.OpenSCAD -o ac-redirect-assembled.stl -D 'print_orientation=false' ac-redirect.scad
// A full render is ~5 min at steps = 130.
//
// Real-world frame: the plate stands vertical in the XZ plane, bolted to the window mount.
// Air leaves the plate along +Y (out into the room). +Z is up.
//
// Shape: an offset. The tube rises out of the plate through bend_r1, levels back off through
// bend_r2, then runs straight out as a round pipe where the flex duct slips over it. The
// duct axis ends up parallel to where it started, 42mm higher -- enough to step over the cat
// bed -- and level, so the duct attaches without kinking up and back down.
//
// The governing constraint is the cat bed, measured 2026-07-31:
//   leading edge  2.25in (57.15mm) out from the panel face
//   top           1.50in (38.10mm) above the window sill, on a wood frame -- no give
//   plate bottom  0.50in (12.70mm) BELOW the sill
// So past 57.15mm of y, the tube's lowest surface must stay above 50.8mm from the plate's
// bottom edge. There are two separate places that can fail: the elbow, and the underside of
// the level run. Check both -- see pitch_deg.
//
// As built: clears the bed by 8.0mm at the elbow and 15.3mm under the straight run, reaches
// 185.6mm into the room, and prints at 257 x 205 x 195.

IN = 25.4;

/* ---------------- plate ---------------- */
duct_w   = 9.125 * IN;  // exhaust ellipse width  (the air passage through the plate)
duct_h   = 4.000 * IN;  // exhaust ellipse height
edge     = 0.500 * IN;  // material left/right of the ellipse; sets plate width
plate_h  = 5.750 * IN;  // plate height, matches the AC unit panel exactly
plate_th = 0.375 * IN;  // plate thickness

// The ellipse sits high in the plate rather than centered, which lifts the whole duct in
// space and buys cat-bed clearance for free. Padding above the ellipse; the remainder of
// the plate hangs below it.
ellipse_top_pad = 0.25 * IN;

bolt_dia   = 4.5;       // mm, M4 clearance hole (M3 -> 3.4, M5 -> 5.5)
bolt_inset = 0.4 * IN;  // hole center inset from each plate corner
corner_r   = 6.0;       // mm plate corner rounding; keep under bolt_inset

// Countersunk M4 (ISO 10642 head is 8.96mm across, 90deg included). Heads sit flush with
// the room-side face, so bolt from inside and put the nuts behind the window mount. The
// mating face stays flat so it can still seal.
countersink = true;
cs_dia      = 9.0;      // mm head diameter
cs_angle    = 90;       // deg included angle

/* ---------------- duct path ---------------- */
// Centerline: bend up out of the plate, bend back to level, then a constant round tail for
// the flex duct and clamp. The cross-section morphs from the plate ellipse to round along
// the way (see squash_r / morph_frac).

// seg_out must stay 0. The cat bed starts 2.25in off the panel face, so any straight run
// here is travel spent going out instead of climbing, right where clearance is tightest --
// 1in of it costs 31mm of clearance. The offset carries the tail far enough off the plate
// for the flex duct on its own.
seg_out  = 0.0;        // straight run off the plate face before the climb starts

// The two bends want different radii, because the cross-section is a different size in each.
// The useful measure is the inner-elbow wall radius, bend_r minus the section's outer
// half-height: under ~15mm it reads as a crease rather than an elbow. Through bend 1 the
// squash holds the section slim (half-height ~53mm) so 90 gives 36mm; by bend 2 it is fully
// round (67.26mm) so 100 gives 33mm. Neither radius affects cat-bed clearance much -- the
// binding point is early in bend 1, before the radius has done anything -- so they are
// nearly free as long as the build plate can take the size.
bend_r1  = 90.0;       // centerline radius, +Y -> +Z  (rise)
bend_r2  = 100.0;      // centerline radius, back to level
seg_tail = 2.5 * IN;   // straight tail: duct engagement + clamp band

// How far the axis tilts up before levelling off, so it sets the size of the offset:
// rise  = (bend_r1 + bend_r2) * (1 - cos(pitch_deg)) = 44.5mm at 40 deg.
// reach = seg_out + (bend_r1 + bend_r2) * sin(pitch_deg) + seg_tail.
//
// The floor is about 37 deg, and it is set by the LEVEL PIPE, not the elbow. Below that the
// offset is too small and the straight run's own underside comes down onto the bed: at
// 30 deg it sits 34.4mm above the sill against a 38.1mm bed, hitting by 3.7mm even though
// the elbow clears fine. 40 leaves 15.3mm under the straight run and keeps the elbow as the
// binding point, with 8.0mm to spare there.
//
// level_out = false drops the second bend, giving one elbow and a tail that exits at
// pitch_deg instead of level.
pitch_deg = 40;
level_out = true;

// Vestigial: these drove an earlier path that turned the duct 90 deg sideways. The current
// path goes straight out into the room, so turn_deg = 0 makes overlap and turn_dir inert.
// riser still has a use -- it inserts a straight run between the two bends, which is what
// the lower/upper split joint needs.
overlap  = 0.0;        // phasing between the rise ramp and the sideways ramp
riser    = 0.0;        // straight climb between the two bends
turn_deg = 0;          // sideways swing; 0 = straight out into the room
turn_dir = -1;         // +1 = tail heads toward +X, -1 = toward -X

// How long the ellipse -> round transition takes, as a multiple of bend 1's arc -- so it
// moves if bend_r1 or pitch_deg change. The absolute length is what matters, and 131mm is
// the knee: below it the taper steepens fast (37 deg at 110mm, over 50 if crammed into a
// single bend), above it nothing improves and the part just gets longer. 2.08 x 62.8mm
// lands on 131mm, just inside the 132.6mm of combined bend arc, so the whole straight run
// is constant round pipe. Larger values are fine -- s_taper lets the round-out spill into
// the straight, which is what makes level_out = false workable.
morph_frac = 2.08;

// Cross-section squash. The plate opening is 28.7 sq-in of flow area but the round tail is
// only 20.1, so the path has to shed area somewhere. Morphing straight to a circle sheds it
// by narrowing a lot and getting 1in TALLER -- the wrong direction, right where the cat bed
// starts. This sheds the same area while staying flat instead: neck down to a
// squash_w x squash_r bore, hold that past the bed, then round out over the rest of the
// path. squash_w is derived for equal flow area with the tail, so it adds no restriction --
// it only moves where the section is wide versus tall. Worth ~14mm of clearance, which the
// design needs; squash_r = 0 reverts to a plain 2-point morph and does not fit.
//
// It costs nothing elsewhere: the squashed section stays narrower than the plate opening
// already is, and it happens where the tube leaves the plate, which prints as near-vertical
// wall. squash_frac is again a fraction of bend 1's arc; what matters is that the squash is
// done by roughly 35mm of arc, where the bed bites.
squash_r    = 40.0;    // inner semi-minor axis at the narrowest point
squash_frac = 0.51;    // where along bend 1 the squash bottoms out, as a fraction of it

/* ---------------- duct fit ---------------- */
// MEASURED off the actual duct, not the nominal 5.5in on its label -- building to the
// nominal figure gives a tail 2.2mm larger than the bore, which will not go on at all.
flex_id      = 5.375 * IN; // flex duct inner diameter, measured 2026-07-31
slip_gap     = 2.0;      // mm the tail OD sits under flex_id. Err loose: a duct clamp takes
                         // up slack, but nothing rescues an oversize tail.
wall         = 3.0;      // mm duct wall
gusset       = 5.0;      // mm flare where the duct meets the plate
tail_chamfer = 4.0;      // mm lead-in chamfer so the duct slides on

// Stop ring where the pipe becomes constant and round: the duct slides on from the tip and
// butts against this, so engagement is always (seg_tail - stop_w) and never more.
stop_h = 4.0;            // mm the ring stands proud of the tail OD
stop_w = 4.0;            // mm ring width along the tail
stop_c = 1.2;            // mm chamfer on both ring edges, so it reads as a collar rather
                         // than a square lip. The duct still butts against a hard face.

/* ---------------- split joint ---------------- */
// Unused at the current size -- the part fits the bed in one piece. If a change outgrows
// the bed, "lower" and "upper" cut it across the straight riser; the upper half carries a
// socket that slips down over the lower half's tube, same idea as the flex duct over the
// tail. Seal with foil tape or silicone. Needs overlap = 0 and riser > joint_len, since the
// socket has to sit on straight tube.
joint_len = 15.0;        // mm socket depth (must stay under riser)
fit_gap   = 0.6;         // mm diametral clearance in the socket

/* ---------------- output ---------------- */
// "plate" and "tail_test" are cheap fit checks -- print both before committing to "all".
part = "all";            // "all" | "lower" | "upper" | "plate" | "tail_test"
plate_test_th = 2.5;     // mm, thickness used by part="plate"; set to plate_th for the real plate
print_orientation = true;
// The sweep hulls consecutive cross-sections, so each step is a flat band. At 72 the bands
// showed as ridges down the elbows; 130 puts them near 1.5mm and they disappear. Render
// time scales with this -- drop it to ~60 while experimenting.
steps = 130;             // centerline samples; raise for smoother, slower renders
$fn   = 72;

/* ---------------- derived ---------------- */
plate_w = duct_w + 2 * edge;
// the duct centerline starts at the origin, so raising the ellipse means dropping the plate
plate_z = -(plate_h / 2 - ellipse_top_pad - duct_h / 2);
tail_od = flex_id - slip_gap;
tail_r  = tail_od / 2 - wall;      // inner radius at the tail
// arc-length breakpoints along the centerline
s1 = seg_out;                           // end of the straight off the plate
a1 = bend_r1 * pitch_deg * PI / 180;    // arc length of the climb ramp
a2 = bend_r2 * turn_deg * PI / 180;     // arc length of the turn ramp
s2 = s1 + a1;                           // end of the climb ramp
t0 = s1 + (1 - overlap) * (a1 + riser); // start of the turn ramp
t1 = t0 + a2;                           // end of the turn ramp
s_top = max(s2, t1);                    // top of the climb, where level_out begins
a3 = level_out ? bend_r2 * pitch_deg * PI / 180 : 0;   // ramp back down to level
s4 = s_top + a3;                        // end of the last bend

s_round  = seg_out + morph_frac * a1;    // section is fully round from here on
squash_w = tail_r * tail_r / squash_r;   // equal flow area with the round tail
s_squash = seg_out + squash_frac * a1;   // narrowest point of the squash
assert(squash_r <= 0 || s_squash < s_round,
       "squash_frac must be below morph_frac -- the squash has to finish before the round-out");

// The round-out may finish past the last bend, inside the straight run. Everything from
// s_taper on is constant round pipe: that is what the duct slips over, and where the stop
// ring sits.
s_taper = max(s4, s_round);
L  = s_taper + seg_tail;
ds      = L / steps;
eps     = 0.01;

// Split plane, on the straight riser. Only meaningful at overlap = 0 with riser > joint_len;
// the split modules assert on that.
y_cut = seg_out + bend_r1;
z_cut = bend_r1 + riser;
socket_id = tail_od + fit_gap;          // slips over the lower half's tube
socket_od = socket_id + 2 * wall;

/* ---------------- centerline + section ---------------- */
function smoothstep(t) = let (u = max(0, min(1, t))) u * u * (3 - 2 * u);

// Two angles steer the path. pitch tilts the axis from +Y up toward +Z; turn swings it
// toward +X. Ramping each linearly in arc length gives a true circular arc of the requested
// radius. pitch rises to pitch_deg, holds through any turn, then eases back to level.
// It never goes negative, so the tube only ever climbs -- which is why levelling off costs
// no cat-bed clearance.
function pitch(s) =
    s <= s1    ? 0 :
    s <  s2    ? pitch_deg * (s - s1) / a1 :
    s <= s_top ? pitch_deg :
    s <  s4    ? pitch_deg * (1 - (s - s_top) / a3) :
    (level_out ? 0 : pitch_deg);
function turn(s)  = turn_dir *
    (s <= t0 ? 0 : s >= t1 ? turn_deg : turn_deg * (s - t0) / (t1 - t0));

// unit tangent = Ry(turn) * Rx(pitch) * [0,1,0]
function dir(s) = [sin(pitch(s)) * sin(turn(s)),
                   cos(pitch(s)),
                   sin(pitch(s)) * cos(turn(s))];

// centerline position at sample i, integrated from the tangent (midpoint rule)
function pos(i) = i <= 0 ? [0, 0, 0] :
    pos(i - 1) + ds * dir((i - 0.5) * ds);

// inner semi-axes at s. Without a squash: the plate ellipse morphs straight to a circle by
// s_round. With one: plate ellipse -> flat squash_w x squash_r bore by s_squash -> circle
// by s_round. smoothstep clamps, so t outside [0,1] just holds the endpoint.
function sect(s) =
    squash_r <= 0
      ? let (t = smoothstep(min(s, s_round) / s_round))
        [duct_w / 2 + (tail_r - duct_w / 2) * t,
         duct_h / 2 + (tail_r - duct_h / 2) * t]
      : s < s_squash
      ? let (t = smoothstep((s - seg_out) / (s_squash - seg_out)))
        [duct_w / 2 + (squash_w - duct_w / 2) * t,
         duct_h / 2 + (squash_r - duct_h / 2) * t]
      : let (t = smoothstep((s - s_squash) / (s_round - s_squash)))
        [squash_w + (tail_r - squash_w) * t,
         squash_r + (tail_r - squash_r) * t];

// wall thickness at s, tapering over the last tail_chamfer to chamfer the tip
function grow(s, outer) = !outer ? 0 :
    s <= L - tail_chamfer ? wall :
    wall - (wall - 0.6) * (s - (L - tail_chamfer)) / tail_chamfer;

// the tail is straight, so back off from the swept end along the final direction
tail_start = pos(steps) - seg_tail * dir(L);

// place children at a point on the path, oriented so local +Z runs along the centerline
module at_path(p, s) {
    translate(p) rotate([0, turn(s), 0]) rotate([pitch(s), 0, 0]) rotate([-90, 0, 0])
        children();
}

module ellipse2d(ab, g) {
    if (g > 0) offset(r = g) scale(ab) circle(d = 2);
    else scale(ab) circle(d = 2);
}

// one thin cross-section slab, normal to the centerline at sample i
module xsect(i, outer) {
    s = i * ds;
    translate(pos(i))
        rotate([0, turn(s), 0]) rotate([pitch(s), 0, 0]) rotate([-90, 0, 0])
            linear_extrude(height = eps) ellipse2d(sect(s), grow(s, outer));
}

// swept shell surface; outer=false gives the bore
module sweep(outer) {
    for (i = [0 : steps - 1])
        hull() { xsect(i, outer); xsect(i + 1, outer); }
}

/* ---------------- parts ---------------- */
module plate_profile() {
    offset(r = corner_r)
        square([plate_w - 2 * corner_r, plate_h - 2 * corner_r], center = true);
}

module plate(th = plate_th) {
    translate([0, -th, plate_z]) rotate([-90, 0, 0])
        linear_extrude(height = th) plate_profile();
}

// plate outline swept along the duct axis, used to keep the gusset inside the plate
module plate_mask(h) {
    translate([0, -plate_th - 1, plate_z]) rotate([-90, 0, 0])
        linear_extrude(height = h) plate_profile();
}

// solid disc; bore() punches it through later, leaving a ring. Chamfered on both edges --
// the cones stay wider than tail_od, so they never cut into the tube.
module stop_ring() {
    d_out = tail_od + 2 * stop_h;
    at_path(tail_start, L) {
        cylinder(h = stop_c, d1 = d_out - 2 * stop_c, d2 = d_out);
        translate([0, 0, stop_c])
            cylinder(h = stop_w - 2 * stop_c, d = d_out);
        translate([0, 0, stop_w - stop_c])
            cylinder(h = stop_c, d1 = d_out, d2 = d_out - 2 * stop_c);
    }
}

module shell() {
    sweep(true);
    if (stop_h > 0) stop_ring();
    // stub the shell back into the plate so the union is solid, not a shared face
    hull() { xsect(0, true); translate([0, -plate_th / 2, 0]) xsect(0, true); }
    // flare onto the plate face for strength at the joint, clipped to the plate outline --
    // the raised ellipse leaves less room above it than the flare wants, and without the
    // clip it pokes 1.65mm past the top edge
    intersection() {
        hull() {
            translate([0, -1, 0])
                rotate([-90, 0, 0]) linear_extrude(eps) ellipse2d(sect(0), wall + gusset);
            translate([0, gusset, 0])
                rotate([-90, 0, 0]) linear_extrude(eps) ellipse2d(sect(0), wall);
        }
        plate_mask(plate_th + gusset + 2);
    }
}

module bore() {
    sweep(false);
    // punch back through the plate, and open the tail
    hull() { xsect(0, false); translate([0, -(plate_th + 2), 0]) xsect(0, false); }
    hull() { xsect(steps, false); translate(dir(L)) xsect(steps, false); }
}

// local +Z runs from y=+1 back through the plate, so the room-side face is at local z=1
module bolt_holes(cs = countersink) {
    over = 0.5;                                                   // keeps the cone off the face plane
    cs_depth = (cs_dia - bolt_dia) / (2 * tan(cs_angle / 2));
    for (sx = [-1, 1], sz = [-1, 1])
        translate([sx * (plate_w / 2 - bolt_inset), 1, plate_z + sz * (plate_h / 2 - bolt_inset)])
            rotate([90, 0, 0]) {
                cylinder(h = plate_th + 2, d = bolt_dia);
                if (cs)
                    translate([0, 0, 1 - over])
                        cylinder(h = cs_depth + over,
                                 d1 = cs_dia + 2 * over * tan(cs_angle / 2),
                                 d2 = bolt_dia);
            }
}

module ac_redirect() {
    difference() {
        union() { plate(); shell(); }
        bore();
        bolt_holes();
    }
}

/* ---------------- split halves ---------------- */
// half-space above the cut plane
module above() { translate([-500, -500, z_cut]) cube([1000, 1000, 1000]); }

module lower_half() {
    assert(overlap == 0 && riser > joint_len,
           "lower/upper need overlap = 0 and riser > joint_len -- the socket must sit on straight tube");
    difference() { ac_redirect(); above(); }
}

module upper_half() {
    assert(overlap == 0 && riser > joint_len,
           "lower/upper need overlap = 0 and riser > joint_len -- the socket must sit on straight tube");
    translate([0, y_cut, 0]) difference() {
        union() {
            translate([0, -y_cut, 0]) intersection() { ac_redirect(); above(); }
            // skirt reaching down over the lower half, plus a cone above the cut that
            // merges the skirt into the tube wall (without it the skirt floats free)
            translate([0, 0, z_cut - joint_len]) cylinder(h = joint_len, d = socket_od);
            translate([0, 0, z_cut]) cylinder(h = wall, d1 = socket_od, d2 = tail_od);
        }
        // socket bore, stopping at z_cut so the lower half butts against a ledge
        translate([0, 0, z_cut - joint_len - 1]) cylinder(h = joint_len + 1, d = socket_id);
        // carry the real bore up through the cone so it is not a solid plug
        translate([0, 0, z_cut - eps])
            cylinder(h = wall + 2 * eps, d = tail_od - 2 * wall);
    }
}

// plate only: outline, ellipse and bolt holes, no duct. Thin by default so it is a
// cheap fit template against the window mount -- verify before printing the full part.
module plate_only(th = plate_test_th) {
    difference() {
        plate(th);
        translate([0, 1, 0]) rotate([90, 0, 0])
            linear_extrude(height = th + 2) ellipse2d(sect(0), 0);
        bolt_holes(cs = false);  // a 2.25mm countersink would nearly perforate the template
    }
}

// short ring at tail diameter -- print this first to check the flex duct fit
module tail_test(h = 15) {
    tip = wall - 0.6;  // outer wall thins by this much at the tip, matching grow()
    difference() {
        union() {
            cylinder(h = h - tail_chamfer, d = tail_od);
            translate([0, 0, h - tail_chamfer])
                cylinder(h = tail_chamfer, d1 = tail_od, d2 = tail_od - 2 * tip);
        }
        translate([0, 0, -1]) cylinder(h = h + 2, d = tail_od - 2 * wall);
    }
}

/* ---------------- output ---------------- */
module oriented(th) {
    if (print_orientation) translate([0, 0, th]) rotate([90, 0, 0]) children();
    else children();
}

// the upper half already has a flat annular face normal to -Z; just drop it to the bed
module upper_oriented() {
    if (print_orientation) translate([0, -y_cut, joint_len - z_cut]) upper_half();
    else upper_half();
}

if (part == "tail_test") tail_test();
else if (part == "plate") oriented(plate_test_th) plate_only();
else if (part == "lower") oriented(plate_th) lower_half();
else if (part == "upper") upper_oriented();
else oriented(plate_th) ac_redirect();
