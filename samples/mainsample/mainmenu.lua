require "vega"
require "sampleutil"
require "firstsample"
require "secondsample"

mainmenu = {}

function mainmenu:load(context)
end

function mainmenu:execute(context)
	context.scene = vega.scene {
		backgroundcolor = 0xff000000
	}
	sampleutil.createbuttonslayer(context, {
		{
			label = "first",
			callback = function(context)
				context.nextmodule = firstsample
				print(context.nextmodule)
			end
		},
		{
			label = "second",
			callback = function(context)
				context.nextmodule = secondsample
				print(context.nextmodule)
			end
		},
	})
end

vega.mainloop.context.module = mainmenu
