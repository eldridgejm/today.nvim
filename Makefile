.PHONY: test
test:
	# set the envvar BUSTED_FILTER to filter tests by name
	busted \
		-v \
		--lpath ./lua/?/init.lua \
		--lpath ./lua/?.lua \
		--filter "${BUSTED_FILTER}" \
		./lua/today/core/test/

.PHONY: pre-commit
pre-commit: test check style

.PHONY: docs
docs:
	ldoc .

.PHONY: style
style:
	stylua lua/

.PHONY: check
check:
	luacheck lua/ \
		--exclude-files '**/vendor/*.lua' \
		--exclude-files '**/test/*.lua' \
		--ignore 'vim'

.PHONY: init
init:
	echo "Installing pre-commit hooks"
	echo "make pre-commit" > ./.git/hooks/pre-commit
	chmod +x ./.git/hooks/pre-commit
