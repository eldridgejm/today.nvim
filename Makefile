.PHONY: test
test:
	busted \
		--lpath ./lua/?/init.lua \
		--lpath ./lua/?.lua \
		./lua/today/core/test/
