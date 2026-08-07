/*
 * Modular desk extender
 *
 * Flatpak STL exports (run from this file's directory):
 *   flatpak run org.openscad.OpenSCAD -o desk-extender-chunk.stl -D 'part="chunk"' desk_extender.scad
 *   flatpak run org.openscad.OpenSCAD -o desk-extender-keys.stl -D 'part="keys"' desk_extender.scad
 *   flatpak run org.openscad.OpenSCAD -o desk-extender-fit-test.stl -D 'part="fit_test"' desk_extender.scad
 *
 * Coordinate system in the assembled preview:
 *   X = chest of drawers (left) to electronics desk (right)
 *   Y = front of the furniture to the AS/400
 *   Z = height above the chest of drawers
 *
 * Set `part` to "chunk", "keys", or "fit_test" before exporting an STL.
 */

$fn = 48;

part = "assembled"; // [assembled, chunk, keys, fit_test]

// Assembly configuration
chunk_count = 4;
chunk_depth_in = 4;

// Measured furniture geometry
gap_width_in = 9;
left_overlap_in = 1;
right_overlap_in = 1;
target_rise_in = 3;
desk_height_difference_in = 0.75;
bridge_thickness_in = 3/8;

// Side-to-side locating lips
locating_lip_depth_in = 1/2;
locating_lip_thickness_in = 1/8;
furniture_edge_clearance = 0; // Confirmed by physical fit test

// Corner gussets
gusset_run_in = 1;
gusset_drop_in = 1;

// Removable bow-tie key tuning (millimeters)
key_length = 40;
key_outer_height = 20;
key_neck_height = 12;
key_side_clearance = 0.20; // Added to overall slot dimensions
key_thickness_clearance = 0.25;

inch = 25.4;
epsilon = 0.05;

gap_width = gap_width_in * inch;
left_overlap = left_overlap_in * inch;
right_overlap = right_overlap_in * inch;
extender_width = left_overlap + gap_width + right_overlap;
target_rise = target_rise_in * inch;
desk_height_difference = desk_height_difference_in * inch;
bridge_thickness = bridge_thickness_in * inch;
locating_lip_depth = locating_lip_depth_in * inch;
locating_lip_thickness = locating_lip_thickness_in * inch;
gusset_run = gusset_run_in * inch;
gusset_drop = gusset_drop_in * inch;
bridge_bottom = target_rise - bridge_thickness;
chunk_depth = chunk_depth_in * inch;
key_thickness = min(left_overlap, right_overlap) - key_thickness_clearance;
left_key_z = bridge_bottom / 2;
right_key_z = (desk_height_difference + bridge_bottom) / 2;

module bridge_solid(depth = chunk_depth) {
    union() {
        // Horizontal load surface.
        translate([0, 0, bridge_bottom])
            cube([extender_width, depth, bridge_thickness]);

        // Left support rests on the 32-inch chest of drawers.
        cube([left_overlap, depth, bridge_bottom + epsilon]);

        // Right support stops 0.75 inch higher to rest on the desk.
        translate([
            left_overlap + gap_width,
            0,
            desk_height_difference
        ])
            cube([
                right_overlap,
                depth,
                bridge_bottom - desk_height_difference + epsilon
            ]);

        // These two lips hang inside the furniture gap and merge into the
        // supports above. They extend below the adjacent furniture tops to
        // prevent the extender shifting sideways into the gap.
        translate([
            left_overlap - epsilon + furniture_edge_clearance,
            0,
            -locating_lip_depth
        ])
            cube([
                locating_lip_thickness + epsilon,
                depth,
                bridge_bottom + locating_lip_depth + epsilon
            ]);

        translate([
            left_overlap + gap_width
                - furniture_edge_clearance
                - locating_lip_thickness,
            0,
            desk_height_difference - locating_lip_depth
        ])
            cube([
                locating_lip_thickness + epsilon,
                depth,
                bridge_bottom
                    - desk_height_difference
                    + locating_lip_depth
                    + epsilon
            ]);

        continuous_gussets(depth);
    }
}

// Extrudes a polygon drawn in X/Z coordinates along the Y axis.
module xz_prism(points, y, thickness) {
    multmatrix([
        [1, 0, 0, 0],
        [0, 0, 1, y],
        [0, 1, 0, 0],
        [0, 0, 0, 1]
    ])
        linear_extrude(height = thickness)
            polygon(points);
}

module continuous_gussets(depth) {
    left_anchor = left_overlap + locating_lip_thickness - epsilon;
    right_anchor = left_overlap + gap_width - locating_lip_thickness + epsilon;

    xz_prism([
        [left_anchor, bridge_bottom + epsilon],
        [left_anchor + gusset_run, bridge_bottom + epsilon],
        [left_anchor, bridge_bottom - gusset_drop]
    ], 0, depth);

    xz_prism([
        [right_anchor, bridge_bottom + epsilon],
        [right_anchor, bridge_bottom - gusset_drop],
        [right_anchor - gusset_run, bridge_bottom + epsilon]
    ], 0, depth);
}

function bow_tie_points(length, outer_height, neck_height) = [
    [-length / 2, 0],
    [-length / 4,  outer_height / 2],
    [0,             neck_height / 2],
    [length / 4,   outer_height / 2],
    [length / 2,   0],
    [length / 4,  -outer_height / 2],
    [0,            -neck_height / 2],
    [-length / 4, -outer_height / 2]
];

// Extrudes a Y/Z bow-tie profile along X.
module bow_tie_prism(
    x,
    y,
    z,
    thickness,
    length = key_length,
    outer_height = key_outer_height,
    neck_height = key_neck_height
) {
    multmatrix([
        [0, 0, 1, x],
        [1, 0, 0, y],
        [0, 1, 0, z],
        [0, 0, 0, 1]
    ])
        linear_extrude(height = thickness)
            polygon(bow_tie_points(length, outer_height, neck_height));
}

module key_slot_pair(y) {
    slot_length = key_length + key_side_clearance;
    slot_outer_height = key_outer_height + key_side_clearance;
    slot_neck_height = key_neck_height + key_side_clearance;

    bow_tie_prism(
        -epsilon,
        y,
        left_key_z,
        left_overlap + 2 * epsilon,
        slot_length,
        slot_outer_height,
        slot_neck_height
    );
    bow_tie_prism(
        left_overlap + gap_width - epsilon,
        y,
        right_key_z,
        right_overlap + 2 * epsilon,
        slot_length,
        slot_outer_height,
        slot_neck_height
    );
}

module chunk_installed(depth = chunk_depth) {
    difference() {
        bridge_solid(depth);

        // Each end contains half of two bow-tie slots. Neighboring halves form
        // complete slots when identical chunks are placed together. The buried
        // ends taper to points so the slot closes gradually without bridging.
        key_slot_pair(0);
        key_slot_pair(depth);
    }
}

module bow_tie_key_installed(x, y, z) {
    bow_tie_prism(x, y, z, key_thickness);
}

module assembled() {
    for (index = [0 : chunk_count - 1])
        translate([0, index * chunk_depth, 0])
            chunk_installed();

    // Show two removable bow-tie keys at every seam.
    color("DimGray")
        for (seam = [1 : chunk_count - 1])
            for (side = [0 : 1]) {
                key_x = side == 0
                    ? key_thickness_clearance / 2
                    : left_overlap + gap_width + key_thickness_clearance / 2;
                key_z = side == 0 ? left_key_z : right_key_z;
                bow_tie_key_installed(
                    key_x,
                    seam * chunk_depth,
                    key_z
                );
            }
}

module chunk_for_printing() {
    // The front/back cross-section sits on the bed. This orientation avoids
    // trying to print a nine-inch horizontal bridge in midair.
    translate([0, target_rise, 0])
        rotate([90, 0, 0])
            chunk_installed();
}

module bow_tie_key_for_printing() {
    linear_extrude(height = key_thickness)
        polygon(bow_tie_points(
            key_length,
            key_outer_height,
            key_neck_height
        ));
}

module keys_for_printing() {
    keys_needed = 2 * (chunk_count - 1);
    spacing_x = key_length + 6;
    spacing_y = key_outer_height + 6;
    columns = 3;

    for (index = [0 : keys_needed - 1])
        translate([
            (index % columns) * spacing_x + key_length / 2,
            floor(index / columns) * spacing_y + key_outer_height / 2,
            0
        ])
            bow_tie_key_for_printing();
}

module connector_fit_test() {
    coupon_margin = 5;
    coupon_width = key_length + 2 * coupon_margin;
    coupon_depth = key_outer_height + 2 * coupon_margin;
    coupon_thickness = min(left_overlap, right_overlap);

    difference() {
        cube([coupon_width, coupon_depth, coupon_thickness]);
        translate([coupon_width / 2, coupon_depth / 2, -epsilon])
            linear_extrude(height = coupon_thickness + 2 * epsilon)
                polygon(bow_tie_points(
                    key_length + key_side_clearance,
                    key_outer_height + key_side_clearance,
                    key_neck_height + key_side_clearance
                ));
    }

    translate([
        coupon_width + 8 + key_length / 2,
        key_outer_height / 2,
        0
    ])
        bow_tie_key_for_printing();
}

if (part == "assembled") {
    assembled();
} else if (part == "chunk") {
    chunk_for_printing();
} else if (part == "keys") {
    keys_for_printing();
} else if (part == "fit_test") {
    connector_fit_test();
}
