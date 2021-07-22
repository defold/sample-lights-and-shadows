local M = {}

local lights = {}

local id = 0

local occluder_target = nil
local shadow_map_target = nil
local quad_pred = nil
local clear_color = nil


function M.init()
	local color_params = { format = render.FORMAT_RGBA,
							width = 64,
							height = 64,
							min_filter = render.FILTER_LINEAR,
							mag_filter = render.FILTER_LINEAR,
							u_wrap = render.WRAP_CLAMP_TO_EDGE,
							v_wrap = render.WRAP_CLAMP_TO_EDGE }

	occluder_target = render.render_target({[render.BUFFER_COLOR_BIT] = color_params})
	shadow_map_target = render.render_target({[render.BUFFER_COLOR_BIT] = color_params})
	quad_pred = render.predicate({ "light_quad" })
	clear_color = vmath.vector4(0,0,0,1)
end

function M.set_clear_color(color)
	clear_color = color
end


-- draw quad using the light_map material
-- with shadow_map as input texture
local function draw_light(light, view, projection, window_width, window_height, blend_func)
	render.set_viewport(0, 0, window_width, window_height)
	render.set_projection(projection)
	render.set_view(view)

	render.set_render_target(render.RENDER_TARGET_DEFAULT)

	render.enable_material("light_map")
	render.enable_texture(0, shadow_map_target, render.BUFFER_COLOR_BIT)

	local constants = render.constant_buffer()
	constants.light_pos = vmath.vector4(light.position.x, light.position.y, light.position.z, 0)
	constants.size = vmath.vector4(light.size.x, light.size.y, light.size.z, 0)
	-- Color clamped to 0.0, 1.0
	constants.color = light.color
	constants.property = vmath.vector4(light.radial_falloff, 0, 0, 0)
	constants.angle = vmath.vector4(light.angle.x, light.angle.y, light.angle.z, light.angle.w)

	-- Call blend_func before draw
	blend_func()
	render.draw(quad_pred, constants)

	render.disable_texture(0, shadow_map_target)
	render.disable_material()

end

local function draw_occluder(light, draw_func)
	-- Set render target size to precision
	render.set_render_target_size(occluder_target, light.size_scaled.x, light.size_scaled.y)

	-- Set viewport
	render.set_viewport(0, 0, light.size_scaled.x, light.size_scaled.y)

	-- Set projection so occluders fill the render target
	render.set_projection(vmath.matrix4_orthographic(0, light.size.x, 0, light.size.y, -5, 5))

	-- Set view matrix to light position
	render.set_view(
		vmath.matrix4_look_at(
		vmath.vector3(-light.size_half.x, -light.size_half.y, 0) + light.position, 
		vmath.vector3(-light.size_half.x, -light.size_half.y, -1) + light.position,
		vmath.vector3(0, 1, 0)))

	-- Clear then draw
	render.set_render_target(occluder_target, { transient = { render.BUFFER_DEPTH_BIT, render.BUFFER_STENCIL_BIT } } )
	render.clear({[render.BUFFER_COLOR_BIT] = clear_color})

	draw_func()
end

local function draw_shadow_map(light)
	-- Set render target size to precision
	render.set_render_target_size(shadow_map_target, light.size_scaled.x, 1)

	-- Set viewport
	render.set_viewport(0, 0, light.size_scaled.x, light.size_scaled.y)
	
	-- Set projection so occluders fill the render target
	render.set_projection(vmath.matrix4_orthographic(0, light.size.x, 0, 1, -5, 5))

	-- Set view matrix to middle
	render.set_view(
		vmath.matrix4_look_at(
		vmath.vector3(-light.size_half.x, -light.size_half.y, 0),
		vmath.vector3(-light.size_half.x, -light.size_half.y, -1),
		vmath.vector3(0, 1, 0)))

	-- Clear then draw
	render.set_render_target(shadow_map_target, { transient = { render.BUFFER_DEPTH_BIT, render.BUFFER_STENCIL_BIT } } )
	render.clear({[render.BUFFER_COLOR_BIT] = clear_color})

	render.enable_material("shadow_map")
	render.enable_texture(0, occluder_target, render.BUFFER_COLOR_BIT)

	-- Only resolution.x
	local constants = render.constant_buffer()
	constants.resolution = vmath.vector4(light.size_scaled.x)
	constants.size = vmath.vector4(light.size.x, light.size.y, light.size.z, 0)
	render.draw(quad_pred, constants)

	render.disable_texture(0, occluder_target)
	render.disable_material()
end


function M.draw(view, projection, occluder_predicate)
	local window_width = render.get_window_width()
	local window_height = render.get_window_height()

	for index, light in ipairs(lights) do
		draw_occluder(light, function ()
			render.set_depth_mask(false)
			render.disable_state(render.STATE_DEPTH_TEST)
			render.disable_state(render.STATE_STENCIL_TEST)
			render.enable_state(render.STATE_BLEND)
			render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
			render.disable_state(render.STATE_CULL_FACE)

			render.draw(occluder_predicate)
		end)

		draw_shadow_map(light)

		draw_light(light, view, projection, window_width, window_height, function ()
			--render.set_blend_func(render.BLEND_ONE, render.BLEND_ONE)
		end)
	end
end

function M.enable_light(light)
	local index = #lights + 1
	id = id + 1

	lights[index] = {
		position = light.position,
		size = light.size,
		precision = light.precision,
		color = light.color,
		angle = light.angle,
		radial_falloff = light.radial_falloff,

		-- Defined in runtime
		id = id,
		size_half = light.size * 0.5,
		size_scaled = light.size * light.precision,
	}

	return lights[index]
end

function M.disable_light(light)
	-- Find index
	local index = 0
	for _index, value in ipairs(lights) do
		if value.id == light.id then
			index = _index
			break
		end
	end

	if index == 0 then
		error("Can't find active light with ID:" .. light.id)
	end

	for i = index, #lights do
		lights[i] = lights[i + 1]
	end
end

function M.set_light_size(light, size)
	light.size = size
	light.size_half = size * 0.5
	light.size_scaled = size * light.precision
end

return M