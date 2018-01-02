ifdef ENABLE_XAMARIN
NEEDED_MACCORE_VERSION := 5a97b45faf02315eb266d3670fd1492e34228f0f
NEEDED_MACCORE_BRANCH := 2017-12

MACCORE_DIRECTORY := maccore
MACCORE_MODULE    := git@github.com:xamarin/maccore.git
MACCORE_VERSION   := $(shell cd $(MACCORE_PATH) 2> /dev/null && git rev-parse HEAD 2> /dev/null)
MACCORE_BRANCH    := $(shell cd $(MACCORE_PATH) 2> /dev/null && git symbolic-ref --short HEAD 2> /dev/null)
MACCORE_REMOTE    := origin
MACCORE_BRANCH_AND_REMOTE := $(NEEDED_MACCORE_BRANCH) $(MACCORE_REMOTE)/$(NEEDED_MACCORE_BRANCH)
NEEDED_MACCORE_REMOTE := $(MACCORE_REMOTE)

define CheckVersionTemplate
check-$(1)::
	@if test x$$(IGNORE_$(2)_VERSION) = "x"; then \
		if test ! -d $($(2)_PATH); then \
			if test x$$(RESET_VERSIONS) != "x"; then \
				make reset-$(1) || exit 1; \
			else \
				echo "Your $(1) checkout is $(COLOR_RED)missing$(COLOR_CLEAR), please run 'make reset-$(1)'"; \
				touch .check-versions-failure; \
			fi; \
		else \
			if test "x$($(2)_VERSION)" != "x$(NEEDED_$(2)_VERSION)" ; then \
				if test x$$(RESET_VERSIONS) != "x"; then \
					make reset-$(1) || exit 1; \
				else \
					echo "Your $(1) version is $(COLOR_RED)out of date$(COLOR_CLEAR), please run 'make reset-$(1)' (found $($(2)_VERSION), expected $(NEEDED_$(2)_VERSION)). Alternatively export IGNORE_$(2)_VERSION=1 to skip this check."; \
					test -z "$(BUILD_REVISION)" || $(MAKE) test-$(1); \
					touch .check-versions-failure; \
				fi; \
			elif test "x$($(2)_BRANCH)" != "x$(NEEDED_$(2)_BRANCH)" ; then \
				if test x$$(RESET_VERSIONS) != "x"; then \
					test -z "$(BUILD_REVISION)" || $(MAKE) test-$(1); \
					make reset-$(1) || exit 1; \
				else \
					echo "Your $(1) branch is $(COLOR_RED)out of date$(COLOR_CLEAR), please run 'make reset-$(1)' (found $($(2)_BRANCH), expected $(NEEDED_$(2)_BRANCH)). Alternatively export IGNORE_$(2)_VERSION=1 to skip this check."; \
					touch .check-versions-failure; \
				fi; \
			else \
				echo "$(1) is $(COLOR_GREEN)up-to-date$(COLOR_CLEAR)."; \
			fi; \
		fi; \
	else \
		echo "$(1) is $(COLOR_GRAY)ignored$(COLOR_CLEAR)."; \
	fi

test-$(1)::
	@echo $(1)
	@echo "   $(2)_DIRECTORY=$($(2)_DIRECTORY)"
	@echo "   $(2)_MODULE=$($(2)_MODULE)"
	@echo "   NEEDED_$(2)_VERSION=$(NEEDED_$(2)_VERSION)"
	@echo "   $(2)_VERSION=$($(2)_VERSION)"
	@echo "   $(2)_BRANCH_AND_REMOTE=$($(2)_BRANCH_AND_REMOTE)"
	@echo "   NEEDED_$(2)_BRANCH=$(NEEDED_$(2)_BRANCH)"
	@echo "   NEEDED_$(2)_REMOTE=$(NEEDED_$(2)_REMOTE)"
	@echo "   $(2)_BRANCH=$($(2)_BRANCH)"
	@echo "   $(2)_PATH=$($(2)_PATH) => $(abspath $($(2)_PATH))"

reset-$(1)::
	@if test -d $($(2)_PATH); then \
		if ! (cd $($(2)_PATH) && git show $(NEEDED_$(2)_VERSION) >/dev/null 2>&1 && git log -1 $(NEEDED_$(2)_REMOTE) >/dev/null 2>&1) ; then \
			echo "*** git fetch `basename $$($(2)_PATH)`" && (cd $($(2)_PATH) && git fetch); \
		fi;  \
	else \
		echo "*** git clone $($(2)_MODULE) --recursive $($(2)_DIRECTORY) -b $(NEEDED_$(2)_BRANCH)"; \
		mkdir -p `dirname $($(2)_PATH)`; \
		(cd $(abspath $($(2)_PATH)/..) && git clone $($(2)_MODULE) --recursive $($(2)_DIRECTORY) -b $(NEEDED_$(2)_BRANCH)); \
	fi
	@if test x$$(IGNORE_$(2)_VERSION) = "x"; then \
		echo "*** [$(1)] git checkout -f" $(NEEDED_$(2)_BRANCH) && (cd $($(2)_PATH) && git checkout -f $(NEEDED_$(2)_BRANCH) || git checkout -f -b $($(2)_BRANCH_AND_REMOTE)); \
		echo "*** [$(1)] git reset --hard $(NEEDED_$(2)_VERSION)" && (cd $($(2)_PATH) && git reset --hard $(NEEDED_$(2)_VERSION)); \
	fi
	@echo "*** [$(1)] git submodule update --init --recursive" && (cd $($(2)_PATH) && git submodule update --init --recursive)

print-$(1)::
	@printf "*** %-16s %-45s %s (%s)\n" "$(DIRECTORY_$(2))" "$(MODULE_$(2))" "$(NEEDED_$(2)_VERSION)" "$(NEEDED_$(2)_BRANCH)"

.PHONY: check-$(1) reset-$(1) print-$(1)

reset-versions:: reset-$(1)
check-versions:: check-$(1)
print-versions:: print-$(1)

DEPENDENCY_DIRECTORIES += $($(2)_PATH)

endef

$(MACCORE_PATH):
	$(Q) git clone --recursive $(MACCORE_MODULE) $(MACCORE_PATH)
	$(Q) $(MAKE) reset-maccore

$(eval $(call CheckVersionTemplate,maccore,MACCORE))
-include $(MACCORE_PATH)/mk/versions.mk
$(MACCORE_PATH)/mk/versions.mk: | $(MACCORE_PATH)
endif
