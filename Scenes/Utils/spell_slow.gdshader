shader_type spatial;

uniform vec4 base_color = vec4(0.5, 0.1, 0.5, 0.9); // Dark purple color
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;        // Glow intensity
uniform float pulse_speed : hint_range(0.0, 10.0) = 8.0;          // Speed of the pulsing glow
uniform float ripple_speed : hint_range(0.0, 5.0) = 1.0;          // Speed of the ripple effect
uniform float ripple_scale : hint_range(0.1, 10.0) = 1.5;         // Size of the ripples
uniform float swirl_strength : hint_range(0.0, 10.0) = 3.0;       // Swirl effect strength

void fragment() {
    // Base color
    vec3 color = base_color.rgb;

    // Pulse effect using sine wave
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

    // Ripple effect using UV coordinates
    float ripple = sin((UV.x + UV.y) * ripple_scale + TIME * ripple_speed);

    // Swirl effect using UV coordinates
    float angle = atan(UV.y - 0.5, UV.x - 0.5) + TIME * swirl_strength;
    float swirl = sin(angle) * 0.5 + 0.5;

    // Edge glow effect
    float edge = smoothstep(0.4, 0.5, length(UV - vec2(0.5)));

    // Combine effects for a dynamic magical glow
    vec3 glow_color = color * (1.0 + pulse * glow_intensity) * (0.8 + ripple * 0.2 + swirl * 0.3) + edge * 0.4;

    // Output the final color
    ALBEDO = glow_color;
    EMISSION = glow_color * glow_intensity * (0.5 + pulse);
    ALPHA = base_color.a;
}
