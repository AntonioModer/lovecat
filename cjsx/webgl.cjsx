_ = require 'lodash'

simple_vertex_shader = """
attribute vec2 pos;
uniform vec2 canvas_dim;
void main(void) {
    float x = pos.x / canvas_dim.x * 2.0 - 1.0;
    // float y = 1.0 - pos.y / canvas_dim.y * 2.0;
    float y = pos.y / canvas_dim.y * 2.0 - 1.0;
    gl_Position = vec4(x, y, 0, 1);
}
"""

draw_shape = (gl, shader, params, vertex_type, vertex_list) ->
    gl.useProgram(shader)

    rect = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, rect)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertex_list), gl.STATIC_DRAW)

    attr_pos = gl.getAttribLocation(shader, "pos");
    gl.enableVertexAttribArray(attr_pos)
    gl.vertexAttribPointer(attr_pos, 2, gl.FLOAT, false, 0, 0)

    unif_canvas_dim = gl.getUniformLocation(shader, "canvas_dim")
    gl.uniform2f(unif_canvas_dim, gl.canvas.width, gl.canvas.height)

    for k,v of params
        unif = gl.getUniformLocation(shader, k);
        if not _.isArray(v)
            gl.uniform1f(unif, v)
        else
            switch v.length
                when 2
                    gl.uniform2f(unif, v[0], v[1])

    gl.drawArrays(vertex_type, 0, vertex_list.length/2)

module.exports =
    compile_shader: (gl, source) ->
        shader_0 = gl.createShader(gl.VERTEX_SHADER, simple_vertex_shader)
        gl.shaderSource(shader_0, simple_vertex_shader)
        gl.compileShader(shader_0)
        if not gl.getShaderParameter(shader_0, gl.COMPILE_STATUS)
            console.error "shader failed to compile:", gl.getShaderInfoLog(shader_0)
            return

        shader = gl.createShader(gl.FRAGMENT_SHADER, source)
        gl.shaderSource(shader, source)
        gl.compileShader(shader)
        if not gl.getShaderParameter(shader, gl.COMPILE_STATUS)
            console.error "shader failed to compile:", gl.getShaderInfoLog(shader)
            return

        program = gl.createProgram()
        gl.attachShader(program, shader_0)
        gl.attachShader(program, shader)
        gl.linkProgram(program)
        if not gl.getProgramParameter(program, gl.LINK_STATUS)
            console.error "shader failed to link:", gl.getProgramInfoLog(program)
            return

        return program

    draw_rect: (gl, L,T,W,H, shader, params) ->
        draw_shape(gl, shader, params, gl.TRIANGLE_STRIP, [
            L,   T
            L,   T+H
            L+W, T
            L+W, T+H
        ] )

    draw_circle: (gl, X,Y,R, shader, params, num_vertex=300) ->
        arr = [X, Y]
        for i in [0..num_vertex]
            theta = i / num_vertex * Math.PI*2
            x = X+Math.cos(theta)*R
            y = Y+Math.sin(theta)*R
            arr.push(x)
            arr.push(y)
        draw_shape(gl, shader, params, gl.TRIANGLE_FAN, arr)
