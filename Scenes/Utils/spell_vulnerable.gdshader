shader_type spatial;

uniform vec4 base_color = vec4(0.4, 0.0, 0.0, 1.0); // Dark red base color
uniform float glow_intensity : hint_range(1.0, 10.0) = 7.0;        // Intense glow
uniform float pulse_speed : hint_range(0.0, 10.0) = 1.2;           // Speed of the pulsing glow
uniform float ripple_speed : hint_range(0.0, 5.0) = 1.5;           // Speed of the ripple effect
uniform float ripple_scale : hint_range(0.1, 10.0) = 2.2;          // Size of the ripples

void fragment() {
    // Base color setup
    vec3 color = base_color.rgb;

    // Create a dynamic pulse effect
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

    // Ripple effect using UV
    float ripple = sin((UV.x + UV.y) * ripple_scale + TIME * ripple_speed);

    // Intense edge glow that radiates outward
    float edge = smoothstep(0.35, 0.5, length(UV - vec2(0.5)));

    // Add a shimmer effect for chaotic magic
    float shimmer = sin(UV.x * 12.0 + TIME * 8.0) * 0.04;

    // Combine effects into a powerful glow
    vec3 glow_color = color * (1.0 + pulse * glow_intensity) * (0.8 + ripple * 0.3) + edge * 6.0 + shimmer;

    // Output the final color
    ALBEDO = vec3(0.0);  // Keep base dark to focus on the glow
    EMISSION = glow_color * glow_intensity * (1.2 + pulse);
    ALPHA = base_color.a;
}
