shader_type spatial;

// Render configuration:
// - depth_prepass_alpha: allows alpha-tested shadows
// - depth_draw_opaque: standard opaque rendering
// - cull_disabled: render both front and back faces (good for thin leaves)
// - world_vertex_coords: use world space in vertex function
// - blend_mix: standard blend mode for transparent materials
// - diffuse_burley, specular_schlick_ggx: physically-based lighting models
render_mode depth_prepass_alpha, depth_draw_opaque, cull_disabled, world_vertex_coords, blend_mix, diffuse_burley, specular_schlick_ggx;

// Albedo (base color) texture, with mipmaps and repeat enabled
uniform sampler2D texture_albedo: source_color, filter_linear_mipmap, repeat_enable;

// Unused in this shader, but may be used for translucency or subsurface scattering
uniform vec4 transmission;

// UV scale multiplier
uniform float uv = 1.0;

// Adjust the green channel to dynamically tint the material
uniform float green_multiplier = 1.0;

// Wind animation control
uniform float sway_speed = 1.0;
uniform float sway_strength = 0.05;
uniform float sway_phase_len = 8.0;

// PBR surface properties
uniform float metallic : hint_range(0, 1) = 0.0;
uniform float roughness : hint_range(0, 1) = 1.0;
uniform float specular : hint_range(0, 1) = 0.5;

void vertex() {
    // Use vertex color red channel to determine sway strength (commonly painted in Blender)
    float strength = COLOR.r * sway_strength;

    // Apply sine-based wave motion to the vertex position
    // Using TIME makes the movement animated
    VERTEX.x += sin(VERTEX.x * sway_phase_len * 1.123 + TIME * sway_speed) * strength;
    VERTEX.y += sin(VERTEX.y * sway_phase_len + TIME * sway_speed * 1.12412) * strength;
    VERTEX.z += sin(VERTEX.z * sway_phase_len * 0.9123 + TIME * sway_speed * 1.3123) * strength;
}

void fragment() {
    // Sample the albedo texture and multiply with vertex color (for tinting/fading)
    vec4 albedo_tex = texture(texture_albedo, UV * uv) * COLOR;

    // (This normal_tex line is not used — possibly a leftover)
    vec4 normal_tex = texture(texture_albedo, UV);

    // Set final surface color and transparency
    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;

    // Modify green channel to allow dynamic color shifting
    ALBEDO.g *= green_multiplier;

    // Set PBR values
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;

    // Discard pixels with alpha below 0.5 (alpha cutout — for leaves, grass, etc.)
    ALPHA_SCISSOR_THRESHOLD = 0.5;
}
