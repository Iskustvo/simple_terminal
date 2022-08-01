UPSTREAM_DIR = $(shell realpath st)
PATCHES = $(shell find "$$(realpath patches)" -type f | sort)

.PHONY: all patch clean

all: patch
	@echo "Building"
	@$(MAKE) -C $(UPSTREAM_DIR)

patch: clean
	@for patch in $(PATCHES); do                                                                            \
	    echo "Applying patch: $${patch}";                                                                   \
	    patch --directory "$(UPSTREAM_DIR)" --input "$${patch}" --no-backup-if-mismatch --quiet || exit -1; \
	done

clean:
	@echo 'Cleaning upstream directory'
	@cd $(UPSTREAM_DIR) && git reset --hard --quiet && git clean -dfq
