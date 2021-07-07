.PHONY: test
test:
	busted \
		-v \
		--lpath ./lua/?/init.lua \
		--lpath ./lua/?.lua \
		./lua/today/core/test/

.PHONY: docs
docs:
	ldoc lua/

.PHONY: style
style:
	./stylua lua/
