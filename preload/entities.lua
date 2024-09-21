--load in entities

em.new('obj/template.lua','templateobj')

em.new('obj/GameManager.lua','GameManager')

em.new('obj/LevelManager.lua','LevelManager')

em.new('obj/OptionsList.lua','OptionsList')

em.new('obj/Player.lua','Player')

em.new('obj/notes/Block.lua','Block')
	em.new('obj/notes/Mine.lua','Mine')
	em.new('obj/notes/Hold.lua','Hold')
		em.new('obj/notes/MineHold.lua','MineHold')
	em.new('obj/notes/Side.lua','Side')
	em.new('obj/notes/ExtraTap.lua','ExtraTap')


em.new('obj/HitParticle.lua','HitParticle')
em.new('obj/MissParticle.lua','MissParticle')

em.new('obj/Deco.lua','Deco')

em.new('obj/MenuMusicManager.lua','MenuMusicManager')

em.new('obj/TitleParticle.lua','TitleParticle')
em.new('obj/SideParticle.lua','SideParticle')
em.new('obj/MineExplosion.lua','MineExplosion')

--level specific
em.new('obj/level/lawrence/LawrenceBG.lua','LawrenceBG')
em.new('obj/level/MonitorTheme.lua','MonitorTheme')
em.new('obj/level/rain/Rain.lua','Rain')
em.new('obj/level/rain/RainBG.lua','RainBG')
em.new('obj/level/tutorial/Tutorial.lua','Tutorial')
em.new('obj/level/tutorial/TutorialBG.lua','TutorialBG')
em.new('obj/level/calibration/Calibration.lua','Calibration')

