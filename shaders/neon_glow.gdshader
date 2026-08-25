shader_type spatial;
// ============================================================
// Neon Glow Shader — efect "circuit luminos" pentru The Neon Network
// Folosește emissive cu pulsație în timp + fresnel pentru margini stralucitoare.
// Atașează ca ShaderMaterial pe MeshInstance3D-uri (pereți, portaluri, chei).
// ============================================================

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.02, 0.02, 0.06);
uniform vec3 neon_color : source_color = vec3(0.0, 1.0, 0.85);
uniform float emission_strength : hint_range(0.0, 8.0) = 3.5;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.35;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;

void fragment() {
	// Color base
	vec3 col = base_color;
	if (use_texture) {
		col *= texture(albedo_texture, UV).rgb;
	}
	ALBEDO = col;

	// Pulsație neon în timp (sinusoidă)
	float pulse = 1.0 - pulse_amount + pulse_amount * sin(TIME * pulse_speed);

	// Efect Fresnel: marginile mesh-ului devin mai luminoase
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	EMISSION = neon_color * emission_strength * pulse * (0.4 + 0.6 * fresnel);
	METALLIC = 0.3;
	ROUGHNESS = 0.4;
}
