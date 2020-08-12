include ../rules.mk
# app config
APPNAME			= hadk
SCRIPTS			= hadk.env \
				hadk.source \
				hadk.build

SUB_SCRIPTS		= hadk.config \
				hadk.tools \
				hadk.base.env \
				hadk.base \
				msg \
				config

all: $(SCRIPTS)

$(SCRIPTS): ${SCRIPTS:=.in.sh} $(SUB_SCRIPTS:=.in.sh)
	$(SHPP) $(SHPPFLAGS) $(@).in.sh  -o $@
	chmod +x $@

install: install_bin
install_bin: $(SCRIPTS)
	$(INSTALL) -dm755 $(bindir)
	$(INSTALL) -m755 $(^) $(bindir)

clean:
	rm -f $(SCRIPTS)

.PHONY: all clean install install_bin
