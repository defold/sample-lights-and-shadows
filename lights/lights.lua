local M = {}

local lights = {}

local id = 0

local OCCLUDER = {
	target = nil,
	width = 0,
	height = 0,
	params = {}
}

local SHADOWMAP = {
	target = nil,
	width = 0,
	height = 0,
	params = {}
}

local quad_pred = nil
local clear_color = nil

local WHITE = vmath.vector4(1, 1, 1, 1)

-- draw lights to quad with shadow_map as input texture
local function draw_light(light, view, projection)
	local window_width = render.get_window_width()
	local window_height = render.get_window_height()
	local size = math.max(window_width, window_height)

	render.set_viewport(0, 0, window_width, window_height)
	render.set_projection(projection)
	render.set_view(view)
	
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
	render.enable_texture(0, SHADOWMAP.target, render.BUFFER_COLOR_BIT)

	local constants = render.constant_buffer()
	constants.light_pos = vmath.vector4(light.position.x, light.position.y, light.position.z, 0)
	--constants.size = vmath.vector4(size, size, 1, 0)
	constants.size = vmath.vector4(light.size, light.size / window_width, 1, 0)
	-- Color clamped to 0.0, 1.0
	constants.color = light.color
	constants.falloff = vmath.vector4(light.falloff, 0, 0, 0)
	--constants.falloff = vmath.vector4(size / light.size, 0, 0, 0)
	constants.angle = vmath.vector4(light.angle.x, light.angle.y, light.angle.z, light.angle.w)

	--render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
	render.draw(quad_pred, constants)

	render.disable_texture(0, SHADOWMAP.target)
end

-- draw 1D shadow map containing distance to occluder
-- draw using the shadow_map.material
-- use the occluder_target as input
local function draw_shadow_map(light)
	-- Set viewport
	render.set_viewport(0, 0, SHADOWMAP.width, SHADOWMAP.height)

	-- Set projection
	render.set_projection(vmath.matrix4_orthographic(0, light.size, 0, 1, -1, 1))

	-- Set view matrix to middle
	render.set_view(
	vmath.matrix4_look_at(
	vmath.vector3(-light.size_half, -light.size_half, 0),
	vmath.vector3(-light.size_half, -light.size_half, -1),
	vmath.vector3(0, 1, 0)))

	render.set_render_target_size(SHADOWMAP.target, SHADOWMAP.width, SHADOWMAP.height)
	render.set_render_target(SHADOWMAP.target, { transient = { render.BUFFER_DEPTH_BIT } } )

	-- Clear then draw
	render.clear({[render.BUFFER_COLOR_BIT] = clear_color})

	render.enable_material("shadow_map")
	render.enable_texture(0, OCCLUDER.target, render.BUFFER_COLOR_BIT)

	-- Constants
	local constants = render.constant_buffer()
	constants.resolution = vmath.vector4(SHADOWMAP.width)
	constants.size = vmath.vector4(light.size, light.size, 1, 0)

	render.draw(quad_pred, constants)

	-- Reset
	render.disable_texture(0, OCCLUDER.target)
	render.disable_material()
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

-- draw anything that should occlude light (ie with occluder predicate tag)
-- draw it to a low res render target (occluder_target)
local function draw_occluder(light, view, projection, occluder_predicate)
	render.set_render_target_size(OCCLUDER.target, OCCLUDER.width, OCCLUDER.height)

	-- Set viewport
	render.set_viewport(0, 0, OCCLUDER.width, OCCLUDER.height)

	-- Set projection so occluders fill the render target
	render.set_projection(vmath.matrix4_orthographic(0, light.size, 0, light.size, -5, 5))

	-- Set view matrix to light position
	render.set_view(
	vmath.matrix4_look_at(
	vmath.vector3(-light.size_half, -light.size_half, 0) + light.position, 
	vmath.vector3(-light.size_half, -light.size_half, -1) + light.position,
	vmath.vector3(0, 1, 0)))

	-- Clear then draw
	render.set_render_target(OCCLUDER.target, { transient = { render.BUFFER_DEPTH_BIT } } )
	render.clear({[render.BUFFER_COLOR_BIT] = clear_color})

	-- Draw occluder
	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
	render.disable_state(render.STATE_CULL_FACE)

	render.draw(occluder_predicate)

	-- Reset render target
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

function M.init(config)
	local width = render.get_width()
	local height = render.get_height()

	OCCLUDER.width = width
	OCCLUDER.height = height
	OCCLUDER.params = {
		format = render.FORMAT_RGBA,
		width = OCCLUDER.width,
		height = OCCLUDER.height,
		min_filter = render.FILTER_LINEAR,
		mag_filter = render.FILTER_LINEAR,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}
	OCCLUDER.target = render.render_target({[render.BUFFER_COLOR_BIT] = OCCLUDER.params})

	SHADOWMAP.width = width
	SHADOWMAP.height = 1
	SHADOWMAP.params = {
		format = render.FORMAT_RGBA,
		width = SHADOWMAP.width,
		height = SHADOWMAP.height,
		min_filter = render.FILTER_LINEAR,
		mag_filter = render.FILTER_LINEAR,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}
	SHADOWMAP.target = render.render_target({[render.BUFFER_COLOR_BIT] = SHADOWMAP.params})
	
	quad_pred = render.predicate({ "light_quad" })
	clear_color = vmath.vector4(0,0,0,1)
end

function M.set_clear_color(color)
	clear_color = color
end

function M.draw(view, projection, occluder_predicate)


	--draw_occluder(light, view, projection, occluder_predicate)
	
	for _,light in ipairs(lights) do
		draw_occluder(light, view, projection, occluder_predicate)
		draw_shadow_map(light)
		draw_light(light, view, projection)
	end
	--debug(view, projection, window_width, window_height)
end


function M.add(properties)
	assert(properties)
	assert(properties.radius, "You must specify a radius")
	assert(properties.position, "You must specify a position")

	id = id + 1

	local size = properties.radius * 2

	lights[id] = {
		id = id,
		position = properties.position,
		color = properties.color or WHITE,
		angle = properties.angle or 360,
		falloff = properties.falloff or 1,
		size = size,
		size_half = size * 0.5,
	}

	return id
end

function M.remove(id)
	assert(id)
	assert(lights[id], "Unable to find light")
	lights[id] = nil
end

function M.set_light_radius(id, radius)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(radius)
	local light = lights[id]
	local size = radius * 2
	light.size = size
	light.size_half = size * 0.5
end

function M.set_position(id, position)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(position, "You must provide a position")
	lights[id].position = position
end

function M.set_angle(id, angle)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(angle, "You must provide an angle")
	lights[id].angle = angle
end

return M