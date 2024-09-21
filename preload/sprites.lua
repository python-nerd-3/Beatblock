require("math")
local sprites = {}

if math.random() >= 0.80 then
	sprites.note= {
		square = love.graphics.newImage("assets/game/square.png"),
		inverse = love.graphics.newImage("assets/game/inverse.png"),
		hold = love.graphics.newImage("assets/game/hold.png"),
		mine = love.graphics.newImage("assets/game/mine.png"),
			mineexplosionparticle = love.graphics.newImage("assets/game/mineExplosionParticle.png"),
		side = love.graphics.newImage("assets/game/side.png"),
			sideparticle = love.graphics.newImage("assets/game/sideParticle.png"),
		minehold = love.graphics.newImage("assets/game/minehold.png"),
			mineholdparticle = love.graphics.newImage("assets/game/mineholdParticle.png"),
			mineholdparticle2 = love.graphics.newImage("assets/game/mineholdParticle2.png")
		
	}
else
	sprites.note= {
		square = love.graphics.newImage("assets/game/square.png"),
		inverse = love.graphics.newImage("assets/game/grilled.png"),
		hold = love.graphics.newImage("assets/game/hold.png"),
		mine = love.graphics.newImage("assets/game/mine.png"),
			mineexplosionparticle = love.graphics.newImage("assets/game/mineExplosionParticle.png"),
		side = love.graphics.newImage("assets/game/side.png"),
			sideparticle = love.graphics.newImage("assets/game/sideParticle.png"),
		minehold = love.graphics.newImage("assets/game/minehold.png"),
			mineholdparticle = love.graphics.newImage("assets/game/mineholdParticle.png"),
			mineholdparticle2 = love.graphics.newImage("assets/game/mineholdParticle2.png")
		
	}
end
if math.random() > 0.0 then
	print("I'M ANSWEARING!")
	sprites.note.inverse = love.graphics.newImage("assets/game/grilled.png")
end
sprites.player = {
	idle = love.graphics.newImage("assets/game/cranky/idle.png"),
	happy = love.graphics.newImage("assets/game/cranky/happy.png"),
	miss = love.graphics.newImage("assets/game/cranky/miss.png"),
	angry = love.graphics.newImage("assets/game/cranky/angry.png"),
	colonthree = love.graphics.newImage("assets/game/cranky/colonthree.png")
}
sprites.songselect = {
	artistlink = love.graphics.newImage("assets/songselect/artistlink.png"),
	--fg = love.graphics.newImage("assets/game/selectfg.png"),
	grades = {
		fnone = love.graphics.newImage("assets/results/small/fnone.png"),
		snone = love.graphics.newImage("assets/results/small/snone.png"),
		anone = love.graphics.newImage("assets/results/small/anone.png"),
		bnone = love.graphics.newImage("assets/results/small/bnone.png"),
		cnone = love.graphics.newImage("assets/results/small/cnone.png"),
		dnone = love.graphics.newImage("assets/results/small/dnone.png"),

		splus = love.graphics.newImage("assets/results/small/splus.png"),
		aplus = love.graphics.newImage("assets/results/small/aplus.png"),
		bplus = love.graphics.newImage("assets/results/small/bplus.png"),
		cplus = love.graphics.newImage("assets/results/small/cplus.png"),
		dplus = love.graphics.newImage("assets/results/small/dplus.png"),

		aminus = love.graphics.newImage("assets/results/small/aminus.png"),
		bminus = love.graphics.newImage("assets/results/small/bminus.png"),
		cminus = love.graphics.newImage("assets/results/small/cminus.png"),
		dminus = love.graphics.newImage("assets/results/small/dminus.png"),
		
		perfectnone = love.graphics.newImage("assets/results/small/perfectnone.png"),

	}
}
sprites.results = {
	grades = {
		a = love.graphics.newImage("assets/results/big/a.png"),
		b = love.graphics.newImage("assets/results/big/b.png"),
		c = love.graphics.newImage("assets/results/big/c.png"),
		d = love.graphics.newImage("assets/results/big/d.png"),
		f = love.graphics.newImage("assets/results/big/f.png"),
		plus = love.graphics.newImage("assets/results/big/plus.png"),
		minus = love.graphics.newImage("assets/results/big/minus.png"),
		none = love.graphics.newImage("assets/results/big/none.png"),
		s = love.graphics.newImage("assets/results/big/s.png"),
		perfect = love.graphics.newImage("assets/results/big/perfect.png")
	},
	accessibility = love.graphics.newImage("assets/results/accessibility.png")
}
sprites.title = {
	logo = love.graphics.newImage("assets/title/logo.png")
}

sprites.editor = {
	--[[
	Square = love.graphics.newImage("assets/editor/editorSquare.png"),
  Palette = love.graphics.newImage("assets/editor/editorPalette.png"),
  Rect51x26 = love.graphics.newImage("assets/editor/editorRect51x26.png"),
  Rect41x33 = love.graphics.newImage("assets/editor/editorRect41x33.png"),
  Selected = love.graphics.newImage("assets/editor/editorSelected.png"),
  PlaySymbol = love.graphics.newImage("assets/editor/editorPlaySymbol.png"),
  TextBox = love.graphics.newImage("assets/editor/editorTextBox.png")
	]]
	genericevent = love.graphics.newImage("assets/editor/genericevent.png"),
	selected = love.graphics.newImage("assets/editor/selected.png"),
	beaticon = love.graphics.newImage("assets/editor/beaticon.png"),
	events = {
		play = love.graphics.newImage("assets/editor/events/play.png"),
		width = love.graphics.newImage("assets/editor/events/width.png"),
		showresults = love.graphics.newImage("assets/editor/events/showresults.png"),
		setcolor = love.graphics.newImage("assets/editor/events/setcolor.png"),
		setbgcolor = love.graphics.newImage("assets/editor/events/setbgcolor.png"),
		outline = love.graphics.newImage("assets/editor/events/outline.png"),
		tag = love.graphics.newImage("assets/editor/events/tag.png"),
		deco = love.graphics.newImage("assets/editor/events/deco.png"),
		extratap = love.graphics.newImage("assets/editor/events/extratap.png"),
    paddlecount = love.graphics.newImage("assets/editor/events/paddlecount.png"),
    mirrorzone = love.graphics.newImage("assets/editor/events/mirror.png"),
    ease = love.graphics.newImage("assets/editor/events/ease.png"),
    noise = love.graphics.newImage("assets/editor/events/noise.png"),
		bookmark = love.graphics.newImage("assets/editor/events/bookmark.png"),
    setbpm = love.graphics.newImage("assets/editor/events/setbpm.png"),
    forceplayersprite = love.graphics.newImage("assets/editor/events/forceplayersprite.png"),
    setboolean = love.graphics.newImage("assets/editor/events/setboolean.png"),
		paddle = love.graphics.newImage("assets/editor/events/paddle.png")
	}
}


sprites.noisetexture = love.graphics.newImage('assets/shaders/noisetexture.png')
sprites.cat = love.graphics.newImage('assets/cat.png')
sprites.mouse = love.graphics.newImage('assets/mouse.png')

return sprites