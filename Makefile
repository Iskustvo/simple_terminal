UPSTREAM_DIR = $(shell realpath st)
PATCHES = $(shell find "$$(realpath patches)" -type f | sort)

.PHONY: all st patch clean get_upstream_patch

define error_message_for_getting_upstream_patch
[1;31m Invalid use of "get_upstream_patch"!
[0;33m"get_upstream_patch" is a Make target, not a Make variable, so use it as following:
[0;32m    make get_upstream_patch URL=https://st.suckless.org/patches/[patch_directory]/[patch_file]
[0m
endef

ifdef get_upstream_patch
$(error $(error_message_for_getting_upstream_patch))
endif

all: st

st: patch
	@echo "Building simple terminal"
	@$(MAKE) -C $(UPSTREAM_DIR)

patch: clean
	@for patch in $(PATCHES); do                                                                            \
	    echo "Applying patch: $${patch}";                                                                   \
	    patch --directory "$(UPSTREAM_DIR)" --input "$${patch}" --no-backup-if-mismatch --quiet || exit -1; \
	    git -C '$(UPSTREAM_DIR)' diff > "$${patch}";                                                        \
	    git -C '$(UPSTREAM_DIR)' add .;                                                                     \
	done

clean:
	@echo 'Cleaning upstream directory'
	@git -C '$(UPSTREAM_DIR)' reset --hard --quiet
	@git -C '$(UPSTREAM_DIR)' clean -dffq

# Target used for smart downloading of upstream patches into current setup.
#
# Usage:
#     make get_upstream_patch URL=https://st.suckless.org/patches/[patch_directory]/[patch_file]
#
get_upstream_patch:
	@PATCH_NAME="$$(echo '$(URL)'                                                                                      \
	                | sed -n '/https:\/\/st.suckless.org\/patches\/[^ /]\+\/[^ /]\+/                                   \
	                          {                                                                                        \
	                              s|.*/\([^ /]\+\)/[^ /]\+$$|\1|;                                                      \
	                              p;                                                                                   \
	                          }')";                                                                                    \
	                                                                                                                   \
	if [ -z "$${PATCH_NAME}" ]; then                                                                                   \
	    printf $$'\e[1;31mError: %s\n\e[0;33m%s\n\e[32m%s\n\e[0m'                                                      \
	           'Invalid value of Make variable URL: $(URL)'                                                            \
	           'It must be provided in the following format:'                                                          \
	           '    make get_upstream_patch URL=https://st.suckless.org/patches/[patch_directory]/[patch_file]' >& 2;  \
	    exit 1;                                                                                                        \
	fi;                                                                                                                \
	                                                                                                                   \
	PATCH_DIRECTORY="$$(find patches -maxdepth 1 -mindepth 1 -regextype 'sed' -regex ".*/[0-9]\+-$${PATCH_NAME}")";    \
	if [ -n "$${PATCH_DIRECTORY}}" ]; then                                                                             \
	    echo "[1;33mWarning: Patch directory for \"$${PATCH_NAME}\" already exists: $${PATCH_DIRECTORY}[0m";       \
	                                                                                                                   \
	    EXISTING_PATCHES=($$(find "$${PATCH_DIRECTORY}" -mindepth 1 -maxdepth 1));                                     \
	    if (( "$${#EXISTING_PATCHES[@]}" != 1 )); then                                                                 \
	        echo "[1;31mExisting patch directory doesn't have exactly one patch. Aborting![0m" >&2;                \
	        exit 1;                                                                                                    \
	    fi;                                                                                                            \
	                                                                                                                   \
	    EXISTING_PATCH="$${EXISTING_PATCHES[@]}";                                                                      \
	    if [ -n "$$(echo "$${EXISTING_PATCH}" | sed -n '/MODIFIED\.diff$$/ =')" ]; then                                \
	        printf $$'\e[1;31m%s\n\e[0;33m%s\n\e[32m%s\n\e[0m'                                                         \
	             "Patch $${EXISTING_PATCH} was modified by hand, won't replace it. Aborting!"                          \
	             'Consider replacing it manually after you download new patch with following command:'                 \
	             "    wget --output-document "$${PATCH_DIRECTORY}/$$(basename $(URL))" --quiet '$(URL)'" >&2;          \
	        exit 1;                                                                                                    \
	    fi;                                                                                                            \
	                                                                                                                   \
	    NEW_PATCH_FILE="$${PATCH_DIRECTORY}/$$(basename $(URL))";                                                      \
	    echo "[1;33mWarning: Replacing \"$${EXISTING_PATCH}\" with \"$${NEW_PATCH_FILE}\"[0m";                     \
	    rm $${EXISTING_PATCH};                                                                                         \
	    wget --output-document "$${NEW_PATCH_FILE}" --quiet '$(URL)';                                                  \
	                                                                                                                   \
	    exit 0;                                                                                                        \
	fi;                                                                                                                \
	                                                                                                                   \
	LAST_PATCH_NUMBER="$$(find patches -mindepth 1 -maxdepth 1 -printf '%P\n'                                          \
	                      | sort                                                                                       \
	                      | tail -n 2                                                                                  \
	                      | head -n 1                                                                                  \
	                      | cut -d '-' -f 1)";                                                                         \
	PATCH_DIRECTORY="patches/$$(( $${LAST_PATCH_NUMBER} + 1 ))-$${PATCH_NAME}";                                        \
	PATCH_FILE="$${PATCH_DIRECTORY}/$$(basename $(URL))";                                                              \
	                                                                                                                   \
	mkdir -p "$${PATCH_DIRECTORY}";                                                                                    \
	wget --output-document "$${PATCH_FILE}" --quiet '$(URL)';
