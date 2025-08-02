LISTING_DIR := z_listing
LISTING_FILE := $(LISTING_DIR)/listing.txt
ROOT := .

.PHONY: list

list:
	@mkdir -p $(LISTING_DIR)
	@echo "Generating file listing into $(LISTING_FILE)..."
	@> $(LISTING_FILE)
	@find $(ROOT) -type f \
		! -path "$(LISTING_FILE)" \
		! -path "$(ROOT)/$(LISTING_DIR)/*" \
		! -path "$(ROOT)/.*" \
		! -regex '.*/\..*' \
	| while read file; do \
		echo "=== $$file ===" >> $(LISTING_FILE); \
		cat $$file >> $(LISTING_FILE); \
		echo "\n" >> $(LISTING_FILE); \
	done
	@echo "Done."
