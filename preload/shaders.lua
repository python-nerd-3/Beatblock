local shaders = {}

shaders.videoshader = love.graphics.newShader('assets/shaders/videoshader.glsl')
shaders.palshader = love.graphics.newShader('assets/shaders/palshader.glsl')
shaders.outline = love.graphics.newShader('assets/shaders/outline.glsl')
shaders.ontop = love.graphics.newShader('assets/shaders/ontop.glsl')
shaders.bgnoise = love.graphics.newShader('assets/shaders/bgnoise.glsl')
shaders.recolor = love.graphics.newShader('assets/shaders/recolor.glsl')
shaders.texturestencil = love.graphics.newShader('assets/shaders/texturestencil.glsl')
shaders.cursor = love.graphics.newShader('assets/shaders/cursor.glsl')

return shaders