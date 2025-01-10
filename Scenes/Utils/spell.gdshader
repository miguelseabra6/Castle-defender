shader_type spatial;

uniform vec4 base_color = vec4(0.1, 0.6, 1.0, 1.0); // Main color of the sphere
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;        // Glow intensity
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;          // Speed of the pulsing glow
uniform float ripple_speed : hint_range(0.0, 5.0) = 1.0;          // Speed of the ripple effect
uniform float ripple_scale : hint_range(0.1, 10.0) = 1.5;         // Size of the ripples

void fragment() {
    // Base color
    vec3 color = base_color.rgb;

    // Pulse effect using sine wave
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

    // Ripple effect using the UV coordinates
    float ripple = sin((UV.x + UV.y) * ripple_scale + TIME * ripple_speed);

    // Combine pulse and ripple for a dynamic glow
    vec3 glow_color = color * (1.0 + pulse * glow_intensity) * (0.8 + ripple * 0.2);

    // Output the final color
    ALBEDO = glow_color;
    EMISSION = glow_color * glow_intensity;
    ALPHA = base_color.a;
}
