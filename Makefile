# global file that calls all other modules
include rules.mk
MODULES = src

all: $(MODULES)

$(MODULES):
	$(MAKE) -C $(@)

clean install:
	for target in $(MODULES) ; do $(MAKE) -C $$target $(@);done



.PHONY: clean $(MODULES)
