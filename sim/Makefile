# General purpose
SHELL		:= bash
rootdir		:= $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
heredir		:= $(realpath .)
BUILDDIR	?= /tmp/build-$(USER)
hdlsrcs		:= $(wildcard $(rootdir)/*.vhd)
HDLSRCS		:= $(patsubst $(rootdir)/%,%,$(hdlsrcs))
TAGSDIR		:= $(BUILDDIR)/tags
TAGS		:= $(addprefix $(TAGSDIR)/,$(HDLSRCS))

V		:= @
Q		:= --quiet

# Mentor Graphics Modelsim
CONFIGFILE	:= $(BUILDDIR)/modelsim.ini
LIBNAME		:= work
LIBDIR		:= $(BUILDDIR)/$(LIBNAME)
VLIB		:= vlib
VMAP		:= vmap
VCOM		:= vcom
VCOMFLAGS	:= -ignoredefaultbinding -nologo -quiet -2008
VSIM		:= vsim
VSIMFLAGS	:= -c -do 'run -all; quit'
VSIMIFLAGS	:= -voptargs="+acc"

# Messages
define HELP_message
make targets:
  make help             print this message (default goal)
  make F=foo.vhd com    compile foo.vhd
  make com              compile all VHDL source files
  make U=foo sim        simulate design unit foo (file foo.vhd), command line interface
  make U=foo simi       simulate design unit foo (file foo.vhd), graphical user interface
  make clean            delete all automatically created files and directories

directories:
  hdl sources          $(rootdir)
  build directory      $(BUILDDIR)

customizable make variables:
  BUILDDIR             ($(BUILDDIR))
endef
export HELP_message

# Help
help:
	$(V)echo "$$HELP_message"

ifeq ($(heredir),$(rootdir))

# Compilation
ifeq ($(F),)

com: $(TAGS)

else

com: $(TAGSDIR)/$(F)

endif

$(TAGS): $(TAGSDIR)/%: % | $(CONFIGFILE) $(TAGSDIR) $(LIBDIR)
	$(V)$(MAKE) $(Q) -C $(TAGSDIR) -f $(rootdir)/Makefile $*

$(BUILDDIR):
	$(V)echo [MKDIR] $@ && \
	mkdir -p $@

$(TAGSDIR): | $(BUILDDIR)
	$(V)echo [MKDIR] $@ && \
	mkdir -p $@

$(LIBDIR): | $(BUILDDIR)
	$(V)echo '[VLIB] $(LIBNAME)' && \
	cd $(BUILDDIR) && \
	$(VLIB) $(LIBNAME)

$(CONFIGFILE): | $(BUILDDIR) $(LIBDIR)
	$(V)echo '[VMAP] $(LIBNAME) $(LIBNAME)' && \
	cd $(BUILDDIR) && \
	$(VMAP) $(LIBNAME) $(LIBNAME)

clean:
	$(V)echo '[RM] $(BUILDDIR)' && \
	rm -rf $(BUILDDIR)

# Simulation
ifeq ($(U),)

sim simi:
	$(V)echo "Please specify the design unit to simulate:" && \
	echo "make U=foo $@"

else

sim simi: | $(CONFIGFILE) $(TAGSDIR) $(LIBDIR)
	$(V)$(MAKE) $(Q) -C $(TAGSDIR) -f $(rootdir)/Makefile U=$(U) $@

endif

else ifeq ($(heredir),$(realpath $(TAGSDIR)))

-include $(rootdir)/dep.mk

$(HDLSRCS): %: $(rootdir)/%
	$(V)echo '[VCOM] $*' && \
	cd $(BUILDDIR) && \
	$(VCOM) $(VCOMFLAGS) $(rootdir)/$* && \
	touch $(TAGSDIR)/$*

sim simi: $(U).vhd

sim:
	$(V)echo "[VSIM] $(U)" && \
	cd $(BUILDDIR) && \
	$(VSIM) $(VSIMFLAGS) $(U)

simi:
	$(V)echo "[VSIM] $(U)" && \
	cd $(BUILDDIR) && \
	$(VSIM) $(VSIMIFLAGS) $(U)

endif

