shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;


uniform vec4 deep_blue : source_color = vec4(0.015, 0.06, 0.35, 1.0);
uniform vec4 electric_blue : source_color = vec4(0.02, 0.3, 1.0, 1.0);
uniform vec4 cyan : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform vec4 inner_glow : source_color = vec4(0.35, 0.9, 1.0, 1.0);


uniform float spin_speed : hint_range(-5.0, 5.0) = 0.8;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;
uniform float pulse_amount : hint_range(0.0, 0.2) = 0.035;

uniform float gradient_speed : hint_range(0.0, 5.0) = 0.5;


uniform float twist_strength : hint_range(0.0, 30.0) = 9.0;
uniform float vortex_radius : hint_range(0.1, 0.8) = 0.5;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.09;
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;


mat2 rotate(float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return mat2(
        vec2(c, -s),
        vec2(s, c)
    );
}



void fragment() {

    // Center UV
    vec2 uv = UV - 0.5;

    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Pulsation
    float pulse = sin(TIME * pulse_speed);

    float breathing = pulse * pulse_amount;

    // Spin
    float rotation = TIME * spin_speed;

    // Vortex twist
    float twist = (1.0 - smoothstep(0.0, vortex_radius, dist))
        * twist_strength;

    float animated_angle = angle + rotation + twist * pulse * 0.35;

    // Breathing distortion
    float radius = dist + breathing;

    // Animated radial gradient
    float gradient = sin(
        radius * 13.0
        - TIME * gradient_speed * 3.0
        + animated_angle * 2.0
    );

    gradient = gradient * 0.5 + 0.5;

    // Colour blending
    vec3 color = mix(
        deep_blue.rgb,
        electric_blue.rgb,
        smoothstep(0.0, 0.65, gradient)
    );

    color = mix(
        color,
        cyan.rgb,
        smoothstep(0.45, 1.0, gradient)
    );

    // Bright inner energy
    float center_glow = 1.0 - smoothstep(0.0, 0.32, dist);

    color = mix(
        color,
        inner_glow.rgb,
        center_glow * 0.8
    );

    // Vortex details
    float spiral = sin(
        animated_angle * 5.0
        - dist * 22.0
        - TIME * 2.0
    );

    float spiral_glow = smoothstep(0.65, 1.0, spiral);

    color += cyan.rgb * spiral_glow * 0.4;

    // Circular alpha
    float alpha = 1.0 - smoothstep(
        vortex_radius - edge_softness,
        vortex_radius,
        dist
    );

    // Edge glow
    float edge = 1.0 - smoothstep(
        vortex_radius - 0.12,
        vortex_radius,
        dist
    );

    color += electric_blue.rgb * edge * 0.5;

    // Final output
    ALBEDO = color;

    EMISSION = color * glow_strength;

    ALPHA = alpha;
}
