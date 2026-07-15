varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_texel;
uniform float u_time;
uniform float u_strength;
uniform float u_tint_amount;

float crystal_hash(vec2 value) {
    return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 crystal_sample_uv(vec2 value) {
    return clamp(value, u_texel * 0.5, vec2(1.0) - (u_texel * 0.5));
}

void main() {
    // Twelve-source-pixel cells split diagonally into stable facets. The
    // normals shift the sampled backdrop by one to three authored pixels.
    vec2 source_pixel = v_vTexcoord / max(u_texel, vec2(0.000001));
    vec2 cell = floor(source_pixel / 12.0);
    vec2 local = fract(source_pixel / 12.0);
    float lower_facet = step(local.x, local.y);
    vec2 facet_id = (cell * 2.0) + vec2(lower_facet, 1.0 - lower_facet);
    float facet_seed = crystal_hash(facet_id);
    float angle = facet_seed * 6.2831853;
    vec2 facet_normal = vec2(cos(angle), sin(angle));
    vec2 refraction = facet_normal * u_texel
        * (0.85 + (facet_seed * 1.45)) * u_strength;

    vec2 center_uv = crystal_sample_uv(v_vTexcoord);
    vec4 center_sample = texture2D(gm_BaseTexture, center_uv);
    vec3 refracted;
    refracted.r = texture2D(gm_BaseTexture,
        crystal_sample_uv(center_uv + (refraction * 1.35))).r;
    refracted.g = center_sample.g;
    refracted.b = texture2D(gm_BaseTexture,
        crystal_sample_uv(center_uv - (refraction * 1.35))).b;

    // Pixel-stable seams and angled highlights make the transparent fill read
    // as cut crystal rather than ordinary tinted glass.
    float diagonal_seam = 1.0 - smoothstep(0.0, 0.085,
        abs(local.x - local.y));
    float cell_edge_distance = min(min(local.x, 1.0 - local.x),
        min(local.y, 1.0 - local.y));
    float cell_seam = 1.0 - smoothstep(0.0, 0.065,
        cell_edge_distance);
    float facing_light = dot(facet_normal, normalize(vec2(-0.55, -0.84)))
        * 0.5 + 0.5;
    float shimmer = 0.92 + (0.08 * sin((u_time * 0.7)
        + (facet_seed * 9.0)));
    float seam_light = max(diagonal_seam * 0.38, cell_seam * 0.24)
        * (0.28 + (facing_light * 0.72)) * shimmer;

    // Dark stained crystal keeps text and meters legible over busy location
    // art. The source remains recognizable, but no longer competes with UI.
    vec3 dark_backdrop = refracted * 0.62;
    vec3 dark_tint = v_vColour.rgb * 0.64;
    vec3 crystal_color = mix(dark_backdrop, dark_tint, u_tint_amount);
    crystal_color += vec3(0.42, 0.68, 1.0) * seam_light * 0.28;
    crystal_color += vec3(0.24, 0.07, 0.30)
        * diagonal_seam * (1.0 - facing_light) * 0.10;

    gl_FragColor = vec4(clamp(crystal_color, 0.0, 1.0),
        center_sample.a * v_vColour.a);
}
