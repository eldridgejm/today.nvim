.PHONY: test
test:
	busted \
		-v \
		--lpath ./lua/?/init.lua \
		--lpath ./lua/?.lua \
		./lua/today/core/test/

.PHONY: pre-commit
pre-commit: test style check

.PHONY: docs
docs:
	ldoc lua/ --ignore

.PHONY: style
style:
	stylua lua/

.PHONY: check
check:
	luacheck lua/ \
		--exclude-files '**/vendor/*.lua' \
		--exclude-files '**/test/*.lua' \
		--ignore 'vim'
