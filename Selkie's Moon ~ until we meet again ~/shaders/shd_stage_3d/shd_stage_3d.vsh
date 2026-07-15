attribute vec3 in_Position;
attribute vec3 in_Normal;
attribute vec2 in_TextureCoord;

varying vec2 v_texcoord;
varying vec3 v_world_position;
varying vec3 v_world_normal;

void main() {
    vec4 object_position = vec4(in_Position, 1.0);
    vec4 world_position = gm_Matrices[MATRIX_WORLD] * object_position;
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_position;
    v_world_position = world_position.xyz;
    v_world_normal = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
    v_texcoord = vec2(in_TextureCoord.x, 1.0 - in_TextureCoord.y);
}
