local Questions = {}

local static = {
	{ id = "animal_01", prompt = "Which one is an animal?", answers = { "TIGER", "TABLE" }, correct = 1, category = "animals" },
	{ id = "food_01", prompt = "Which one is a fruit?", answers = { "CHAIR", "APPLE" }, correct = 2, category = "food" },
	{ id = "science_01", prompt = "Humans need air to breathe.", answers = { "TRUE", "FALSE" }, correct = 1, category = "science" },
	{ id = "compare_01", prompt = "Which is larger?", answers = { "ANT", "ELEPHANT" }, correct = 2, category = "comparison" },
	{ id = "color_01", prompt = "What color is grass usually?", answers = { "GREEN", "PURPLE" }, correct = 1, category = "colors" },
	{ id = "logic_01", prompt = "Which can hold water?", answers = { "CUP", "SOCK" }, correct = 1, category = "logic" },
	{ id = "geo_01", prompt = "Which is a planet?", answers = { "MARS", "PIZZA" }, correct = 1, category = "geography" },
	{ id = "silly_01", prompt = "Which would you wear on your foot?", answers = { "HAT", "SHOE" }, correct = 2, category = "common-sense" },
}

local function arithmetic(random)
	local a = random:NextInteger(1, 9)
	local b = random:NextInteger(1, 9)
	local total = a + b
	local wrong = total + (random:NextNumber() < 0.5 and -1 or 1)
	local correctSide = random:NextInteger(1, 2)
	local answers = correctSide == 1 and { tostring(total), tostring(wrong) } or { tostring(wrong), tostring(total) }
	return {
		id = string.format("math_%d_%d_%d", a, b, correctSide),
		prompt = string.format("%d + %d = ?", a, b),
		answers = answers,
		correct = correctSide,
		category = "mathematics",
	}
end

function Questions.next(random, previousId)
	for _ = 1, 5 do
		local question
		if random:NextNumber() < 0.35 then
			question = arithmetic(random)
		else
			local source = static[random:NextInteger(1, #static)]
			question = table.clone(source)
			question.answers = table.clone(source.answers)
			if random:NextNumber() < 0.5 then
				question.answers[1], question.answers[2] = question.answers[2], question.answers[1]
				question.correct = 3 - question.correct
			end
		end
		if question.id ~= previousId then
			return question
		end
	end
	return arithmetic(random)
end

return Questions
