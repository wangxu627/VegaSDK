local timelinetest = {}
local timeline
local context

function timelinetest.setup()
	timeline = vega.timeline()
	context = {}
end

function timelinetest.test_should_call_function_at_second_frame()
	-- given:
	local functionwasexecuted = false
	local contextarg = nil
	local function f(c)
		functionwasexecuted = true
		contextarg = c
	end
	timeline.actions = {
		[2] = f
	}

	-- when / then:
	timeline:update(context)
	assert_false(functionwasexecuted, "Should not have executed the function yet, the function should execute only in the next frame.")

	timeline:update(context)
	assert_true(functionwasexecuted, "Should have executed the function after update the second frame.")
	assert_equal(context, contextarg, "Should pass the context as argument to the function.")
end

function timelinetest.test_should_call_two_actions()
	-- given:
	local firstfunctioncalls = 0
	local secondfunctioncalls = 0
	local function firstfunction() firstfunctioncalls = firstfunctioncalls + 1 end
	local function secondfunction() secondfunctioncalls = secondfunctioncalls + 1 end
	timeline.actions = {
		[2] = firstfunction,
		[4] = secondfunction
	}

	-- when / then:
	timeline:update(context)
	assert_equal(0, firstfunctioncalls, "Should not have called the first function yet after first update.")
	assert_equal(0, secondfunctioncalls, "Should not have called the second function yet after first update.")

	timeline:update(context)
	assert_equal(1, firstfunctioncalls, "Should have called the first function 1 time after second update.")
	assert_equal(0, secondfunctioncalls, "Should not have called the second function yet after second update.")

	timeline:update(context)
	assert_equal(1, firstfunctioncalls, "Should have called the first function 1 time after third update.")
	assert_equal(0, secondfunctioncalls, "Should not have called the second function yet after third update.")

	timeline:update(context)
	assert_equal(1, firstfunctioncalls, "Should have called the first function 1 time after fourth update.")
	assert_equal(1, secondfunctioncalls, "Should have called the second function 1 time after fourth update.")
end

function timelinetest.test_should_call_two_actions_at_same_frame()
	-- given:
	local firstfunctioncalls = 0
	local secondfunctioncalls = 0
	local calledfunctions = {}
	local function firstfunction()
		table.insert(calledfunctions, firstfunction)
	end
	local function secondfunction()
		table.insert(calledfunctions, secondfunction)
	end
	timeline.actions = {
		[1] = { firstfunction, secondfunction }
	}

	-- when:
	timeline:update(context)

	-- then:
	assert_equal(firstfunction, calledfunctions[1], "Should have called the first function.")
	assert_equal(secondfunction, calledfunctions[2], "Should have called the second function.")
end

function timelinetest.test_should_call_table_function()
	-- given:
	local functionwasexecuted = false
	local contextarg = nil
	local selfarg = nil
	local t = {
		execute = function(self, c)
			functionwasexecuted = true
			contextarg = c
			selfarg = self
		end
	}
	timeline.actions = {
		[1] = t
	}

	-- when:
	timeline:update(context)

	-- then:
	assert_true(functionwasexecuted, "Should have executed the table function.")
	assert_equal(context, contextarg, "Should pass the context as argument to the function.")
	assert_equal(t, selfarg, "Should pass the table as argument to the function.")
end

function timelinetest.test_should_finish_after_all_actions_are_executed()
	-- given:
	timeline.actions = {
		[1] = function() end,
		[3] = function() end
	}

	-- when / then:
	timeline:update(context)
	timeline:update(context)
	assert_nil(timeline.finished, "Should not have finished because there is one action to be executed.")

	timeline:update(context)
	assert_true(timeline.finished, "Should set the finished field, because all actions were executed.")
end

function timelinetest.test_should_finish_after_action_table_was_finished()
	-- given:
	local t = {
		execute = function() end
	}
	timeline.actions = {
		[2] = t
	}

	-- when / then:
	timeline:update(context)
	timeline:update(context)
	assert_nil(timeline.finished, "Should not have finished because the action table was not finished yet.")

	t.finished = true
	timeline:update(context)
	assert_true(timeline.finished, "Should set the finished field, because the action table was finished.")
end

function timelinetest.test_should_finish_after_all_actions_tables_were_finished()
	-- given:
	local t1 = {
		execute = function() end
	}
	local t2 = {
		execute = function() end
	}
	timeline.actions = {
		[1] = { t1, t2 }
	}

	-- when / then:
	timeline:update(context)
	assert_nil(timeline.finished, "Should not have finished because the attached tables were not finished yet.")

	t1.finished = true
	timeline:update(context)
	assert_nil(timeline.finished, "Should not have finished because one of the attached tables was not finished yet.")

	t2.finished = true
	timeline:update(context)
	assert_true(timeline.finished, "Should set the finished field, because all attached tables were finished.")
end

function timelinetest.test_should_finish_when_there_is_no_actions()
	-- given:
	timeline.actions = {}

	-- when:
	timeline:update(context)

	-- then:
	assert_true(timeline.finished, "Should set the finished field.")
end

function timelinetest.test_should_attach_controller_to_scene_when_call_execute_function()
	-- given:
	local scene = vega.scene()
	context.scene = scene

	-- when:
	timeline:execute(context)

	-- then:
	assert_equal(1, #scene.controllers, "The scene should have 1 attached controller.")
	assert_equal(timeline, scene.controllers[1], "The timeline should be the attached controller.")
end

function timelinetest.test_should_create_table_with_initial_values()
	-- given:
	local actions = {}

	-- when:
	timeline = vega.timeline {
		actions = actions,
		frame = 2,
	}

	-- then:
	assert_equal(actions, timeline.actions, "timeline.actions is not the expected.")
	assert_equal(2, timeline.frame, "timeline.frame is not the expected.")
end

return timelinetest