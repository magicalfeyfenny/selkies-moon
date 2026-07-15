varying vec2 v_texcoord;
varying vec3 v_world_position;
varying vec3 v_world_normal;

uniform vec4 u_tex_uv;
uniform vec3 u_camera;
uniform vec3 u_light_dir;
uniform vec3 u_light_color;
uniform vec3 u_rim_dir;
uniform vec3 u_rim_color;
uniform vec3 u_ambient;
uniform vec3 u_fog_color;
uniform float u_fog_start;
uniform float u_fog_end;
uniform float u_emissive;
uniform float u_time;

void main() {
    vec2 atlas_uv = u_tex_uv.xy + (v_texcoord * u_tex_uv.zw);
    vec4 albedo = texture2D(gm_BaseTexture, atlas_uv);
    vec3 normal = normalize(v_world_normal);
    float key = max(dot(normal, -normalize(u_light_dir)), 0.0);
    float rim = max(dot(normal, -normalize(u_rim_dir)), 0.0);

    // Quantized light preserves the authored pixel-art texture at 640x360.
    key = floor(key * 7.0 + 0.5) / 7.0;
    rim = floor(rim * 5.0 + 0.5) / 5.0;
    vec3 lit = albedo.rgb * (u_ambient + u_light_color * key + u_rim_color * rim * 0.42);

    float bright = max(albedo.r, max(albedo.g, albedo.b));
    float chroma = bright - min(albedo.r, min(albedo.g, albedo.b));
    float emissive_mask = smoothstep(0.34, 0.78, bright + chroma * 0.7);
    float pulse = 0.92 + sin(u_time * 1.8 + v_world_position.y * 0.11) * 0.08;
    lit += albedo.rgb * emissive_mask * u_emissive * pulse;

    float distance_to_camera = length(v_world_position - u_camera);
    float fog = clamp((distance_to_camera - u_fog_start) / max(0.001, u_fog_end - u_fog_start), 0.0, 1.0);
    // One-value ordered stipple prevents smooth fog from fighting the pixel grid.
    float dither = mod(floor(gl_FragCoord.x) + floor(gl_FragCoord.y) * 2.0, 4.0) / 4.0;
    fog = clamp(fog + (dither - 0.375) * 0.035, 0.0, 1.0);
    gl_FragColor = vec4(mix(lit, u_fog_color, fog), albedo.a);
}
