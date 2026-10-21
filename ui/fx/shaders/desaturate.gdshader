shader_type canvas_item;
// Greys a CanvasGroup's contents as one picture: an unchosen Dragon Card on the
// choice of dragon, its colours brought back as it is chosen.
render_mode unshaded;

uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_nearest;
// 0 leaves the colours as they are, 1 is grey.
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = textureLod(screen, SCREEN_UV, 0.0);
	// The group's buffer is premultiplied.
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR *= vec4(mix(c.rgb, vec3(l), amount), c.a);
}
