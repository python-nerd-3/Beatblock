local fonts = {}

fonts = {
	main = love.graphics.newFont("assets/fonts/Axmolotl.ttf", 16),
	digitalDisco = love.graphics.newFont("assets/fonts/DigitalDisco-Thin.ttf", 16),
	jfdot = love.graphics.newFont('assets/fonts/JF-Dot-K14-2004.ttf',14)
}

fonts.main:setLineHeight(0.75)
fonts.digitalDisco:setLineHeight(0.75)


fonts.digitalDisco:setFallbacks(fonts.jfdot)

return fonts