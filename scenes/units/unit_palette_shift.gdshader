shader_type canvas_item;

uniform vec4 target_dark : source_color = vec4(0.6, 0.08, 0.08, 1.0);
uniform vec4 target_mid : source_color = vec4(0.95, 0.18, 0.16, 1.0);
uniform vec4 target_light : source_color = vec4(1.0, 0.56, 0.42, 1.0);
uniform float palette_strength : hint_range(0.0, 1.0) = 0.0;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float blue_mask = smoothstep(0.08, 0.24, color.b - color.r)
		* smoothstep(-0.08, 0.04, color.g - color.r);
	float mid_blend = smoothstep(0.24, 0.56, luminance);
	float light_blend = smoothstep(0.56, 0.84, luminance);
	vec3 dark_to_mid = mix(target_dark.rgb, target_mid.rgb, mid_blend);
	vec3 palette_color = mix(dark_to_mid, target_light.rgb, light_blend);
	float palette_mask_total = min(blue_mask, 1.0);
	vec3 palette_mixed = mix(color.rgb, palette_color, palette_mask_total * palette_strength);
	vec3 grayscale = vec3(luminance);
	COLOR = vec4(mix(palette_mixed, grayscale, grayscale_amount), color.a);
}
