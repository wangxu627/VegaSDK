local texttest = {}
local text = {}

local function createvalidfont()
	return {
		texture = {
			width = 10,
			height = 20
		}
	}
end

function texttest.setup()
	text = vega.drawables.text()
end

function texttest.test_should_have_valid_font()
	-- given:
	text.font = createvalidfont()

	-- when:
	local validfont = text:hasvalidfont()

	-- then:
	assert_true(validfont)
end

function texttest.test_should_not_have_valid_font_if_doesnt_have_font()
	-- given:
	text.font = nil

	-- when:
	local validfont = text:hasvalidfont()

	-- then:
	assert_false(validfont)
end

function texttest.test_should_not_have_valid_font_if_font_doesnt_have_texture()
	-- given:
	text.font = {
		texture = nil
	}

	-- when:
	local validfont = text:hasvalidfont()

	-- then:
	assert_false(validfont)
end

function texttest.test_should_not_have_valid_font_if_font_doesnt_have_texture_width()
	-- given:
	text.font = {
		texture = {
			width = nil,
			height = 20
		}
	}

	-- when:
	local validfont = text:hasvalidfont()

	-- then:
	assert_false(validfont)
end

function texttest.test_should_not_have_valid_font_if_font_doesnt_have_texture_height()
	-- given:
	text.font = {
		texture = {
			width = 10,
			height = nil
		}
	}

	-- when:
	local validfont = text:hasvalidfont()

	-- then:
	assert_false(validfont)
end

function texttest.test_should_have_valid_data()
	-- given:
	text.font = createvalidfont()
	text.content = ""
	text.fontsize = 0

	-- when:
	local validdata = text:hasvaliddata()

	-- then:
	assert_true(validdata)
end

function texttest.test_should_not_have_valid_data_if_doesnt_have_valid_font()
	-- given:
	text.hasvalidfont = function() return false end
	text.content = ""
	text.fontsize = 0

	-- when:
	local validdata = text:hasvaliddata()

	-- then:
	assert_false(validdata)
end

function texttest.test_should_not_have_valid_data_if_doesnt_have_content()
	-- given:
	text.font = createvalidfont()
	text.content = nil
	text.fontsize = 0

	-- when:
	local validdata = text:hasvaliddata()

	-- then:
	assert_false(validdata)
end

function texttest.test_should_not_have_valid_data_if_doesnt_have_fontsize()
	-- given:
	text.font = createvalidfont()
	text.content = ""
	text.fontsize = nil

	-- when:
	local validdata = text:hasvaliddata()

	-- then:
	assert_false(validdata)
end

function texttest.test_char_width_should_be_calculated_with_font_texture_width_and_fontsize()
	-- given:
	text.font = {
		texture = {
			width = 160,
			height = 32,
		}
	}
	text.fontsize = 200

	-- when:
	local charwidth = text:widthforascii(12)

	-- then:
	assert_equal(1000, charwidth)
end

function texttest.test_char_width_should_be_calculated_with_font_metric_and_fontsize()
	-- given:
	text.font = {
		texture = {
			width = 123,
			height = 32,
		},
		metrics = {
			[12] = 10
		}
	}
	text.fontsize = 200

	-- when:
	local charwidth = text:widthforascii(12)

	-- then:
	assert_equal(1000, charwidth)
end

function texttest.test_char_width_should_be_calculated_with_font_texture_width_if_char_metric_is_unknow()
	-- given:
	text.font = {
		texture = {
			width = 160,
			height = 32,
		},
		metrics = {
			[13] = 123
		}
	}
	text.fontsize = 200

	-- when:
	local charwidth = text:widthforascii(12)

	-- then:
	assert_equal(1000, charwidth)
end

function texttest.test_should_process_lines()
	-- given:
	text.content = "This is a text\nwith multiple\nlines."
	text.font = createvalidfont()
	text.widthforascii = function() return 10 end

	-- when:
	local next1, text1, width1 = text:processline(1)
	local next2, text2, width2 = text:processline(next1)
	local next3, text3, width3 = text:processline(next2)

	-- then:
	assert_equal(16, next1, "The initial index of line above the first is not the expected.")
	assert_equal("This is a text", text1, "The first line text is not the expected.")
	assert_equal(140, width1, "The first line width is not the expected.")

	assert_equal(30, next2, "The initial index of line above the second is not the expected.")
	assert_equal("with multiple", text2, "The second line text is not the expected.")
	assert_equal(130, width2, "The second line width is not the expected.")

	assert_equal(36, next3, "The initial index of line above the third is not the expected.")
	assert_equal("lines.", text3, "The first line text is not the expected.")
	assert_equal(60, width3, "The first line width is not the expected.")
end

function texttest.test_should_wrap_line_to_max_width_when_process_lines()
	-- given:
	text.content = "This is a text with original single line."
	text.font = createvalidfont()
	text.maxlinewidth = 120
	text.widthforascii = function() return 10 end

	-- when:
	local next1, text1, width1 = text:processline(1)
	local next2, text2, width2 = text:processline(next1)
	local next3, text3, width3 = text:processline(next2)
	local next4, text4, width4 = text:processline(next3)

	-- then:
	assert_equal(11, next1, "The initial index of line above the first is not the expected.")
	assert_equal("This is a", text1, "The first line text is not the expected.")
	assert_equal(90, width1, "The first line width is not the expected.")

	assert_equal(21, next2, "The initial index of line above the second is not the expected.")
	assert_equal("text with", text2, "The second line text is not the expected.")
	assert_equal(90, width2, "The second line width is not the expected.")

	assert_equal(30, next3, "The initial index of line above the third is not the expected.")
	assert_equal("original", text3, "The first line text is not the expected.")
	assert_equal(80, width3, "The first line width is not the expected.")

	assert_equal(42, next4, "The initial index of line above the fourth is not the expected.")
	assert_equal("single line.", text4, "The fourth line text is not the expected.")
	assert_equal(120, width4, "The fourth line width is not the expected.")
end

function texttest.test_should_calculate_line_position()
	-- given:
	text.fontsize = 10

	-- when:
	local pos = text:lineposition(3, 400)

	-- then:
	assert_equal(0, pos.x, "x is not the expected.")
	assert_equal(30, pos.y, "y is not the expected.")
end

function texttest.test_should_calculate_line_position_align_left()
	-- given:
	text.fontsize = 10
	text.size = { x = 1000, y = 1 }
	text.align = "left"

	-- when:
	local pos = text:lineposition(3, 400)

	-- then:
	assert_equal(0, pos.x, "x is not the expected.")
	assert_equal(30, pos.y, "y is not the expected.")
end

function texttest.test_should_calculate_line_position_align_right()
	-- given:
	text.fontsize = 10
	text.size = { x = 1000, y = 1 }
	text.align = "right"

	-- when:
	local pos = text:lineposition(3, 400)

	-- then:
	assert_equal(600, pos.x, "x is not the expected.")
	assert_equal(30, pos.y, "y is not the expected.")
end

function texttest.test_should_calculate_line_position_align_center()
	-- given:
	text.fontsize = 10
	text.size = { x = 1000, y = 1 }
	text.align = "center"

	-- when:
	local pos = text:lineposition(3, 400)

	-- then:
	assert_equal(300, pos.x, "x is not the expected.")
	assert_equal(30, pos.y, "y is not the expected.")
end

return texttest