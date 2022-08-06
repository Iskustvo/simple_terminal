UPSTREAM_DIR = $(shell realpath st)
PATCHES = $(shell find "$$(realpath patches)" -type f | sort)

.PHONY: all st patch clean get_upstream_patch

all: st

st: patch
	@echo "Building simple terminal"
	@$(MAKE) -C $(UPSTREAM_DIR)

patch: clean
	@for patch in $(PATCHES); do                                                                            \
	    echo "Applying patch: $${patch}";                                                                   \
	    patch --directory "$(UPSTREAM_DIR)" --input "$${patch}" --no-backup-if-mismatch --quiet || exit -1; \
	    git -C '$(UPSTREAM_DIR)' add .;                                                                     \
	done

clean:
	@echo 'Cleaning upstream directory'
	@cd $(UPSTREAM_DIR) && git reset --hard --quiet && git clean -dfq

get_upstream_patch:
	@PATCH_NAME="$$(echo '$(LINK)'                                                                                     \
	                | sed -n '/https:\/\/st.suckless.org\/patches\/[^ /]\+\/[^ /]\+/                                   \
	                          {                                                                                        \
	                              s|.*/\([^ /]\+\)/[^ /]\+$$|\1|;                                                      \
	                              p;                                                                                   \
	                          }')";                                                                                    \
	                                                                                                                   \
	if [ -z "$${PATCH_NAME}" ]; then                                                                                   \
	    printf '%s\n%s\n'                                                                                              \
	           'Invalid value of variable LINK: $(LINK)'                                                               \
	           'It must be in format https://st.suckless.org/patches/[patch_directory]/[patch_file]' >& 2;             \
	    exit 1;                                                                                                        \
	fi;                                                                                                                \
	                                                                                                                   \
	if [ -n "$$(find patches -mindepth 1 -maxdepth 1 -printf '%P\n' | sed -n "/^[0-9]\+-$${PATCH_NAME}$$/ =")" ]; then \
	    echo "Patch directory for \"$${PATCH_NAME}\" already exists - Aborting" >& 2;                                  \
	    exit 1;                                                                                                        \
	fi;                                                                                                                \
	                                                                                                                   \
	LAST_PATCH_NUMBER="$$(find patches -mindepth 1 -maxdepth 1 -printf '%P\n'                                          \
	                      | sort                                                                                       \
	                      | tail -n 2                                                                                  \
	                      | head -n 1                                                                                  \
	                      | cut -d '-' -f 1)";                                                                         \
	PATCH_DIRECTORY="patches/$$(( $${LAST_PATCH_NUMBER} + 1 ))-$${PATCH_NAME}";                                        \
	PATCH_FILE="$${PATCH_DIRECTORY}/1-$$(basename $(LINK))";                                                           \
	                                                                                                                   \
	mkdir -p "$${PATCH_DIRECTORY}";                                                                                    \
	wget --output-document "$${PATCH_FILE}" --quiet '$(LINK)';
