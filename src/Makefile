include ../rules.mk
# app config
APPNAME			= hadk
SCRIPTS 		= hadk.env \
				hadk.source \
				hadk.build

SUB_SCRIPTS 		= hadk.config \
				hadk.tools \
				msg \
				config

all: $(SCRIPTS)

$(SCRIPTS): ${SCRIPTS:=.in.sh} $(SUB_SCRIPTS:=.in.sh)
	$(SHPP) $(SHPPFLAGS) $(@).in.sh  -o $@
	chmod +x $@

clean:
	rm -f $(SCRIPTS)

.PHONY: all clean 
