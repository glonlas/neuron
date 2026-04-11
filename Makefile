SKILL_NAME  := llm-wiki
SKILL_DIR   := $(CURDIR)
CONFIG_DIR  := $(HOME)/.llm-wiki

AGENTS_SKILLS := $(HOME)/.agents/skills
CLAUDE_SKILLS := $(HOME)/.claude/skills

.PHONY: install setup uninstall

install: setup
	@echo ""
	@echo "Installing skill symlinks..."
	@mkdir -p "$(AGENTS_SKILLS)"
	@mkdir -p "$(CLAUDE_SKILLS)"
	@for target in "$(AGENTS_SKILLS)/$(SKILL_NAME)" "$(CLAUDE_SKILLS)/$(SKILL_NAME)"; do \
		real=$$(realpath "$$target" 2>/dev/null || echo ""); \
		if [ "$$real" = "$(SKILL_DIR)" ]; then \
			echo "  already linked: $$target"; \
		else \
			ln -sfn "$(SKILL_DIR)" "$$target" && echo "  linked: $$target -> $(SKILL_DIR)"; \
		fi; \
	done
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo " NEXT STEP — Generate your identity filter"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo " Paste this prompt into ChatGPT (or any LLM that knows you):"
	@echo ""
	@echo "  ┌─────────────────────────────────────────────────────────┐"
	@echo "  │ Based on everything you know about me from our          │"
	@echo "  │ conversations — my job, projects, interests, goals,     │"
	@echo "  │ and the topics I regularly ask about — please generate  │"
	@echo "  │ a filter-identity.md file for my personal LLM Wiki.    │"
	@echo "  │                                                         │"
	@echo "  │ The file must follow this structure:                    │"
	@echo "  │                                                         │"
	@echo "  │ # Identity Filter                                       │"
	@echo "  │                                                         │"
	@echo "  │ ## Who is this wiki for?                                │"
	@echo "  │ [2-3 sentences: my role, domains, key interests]        │"
	@echo "  │                                                         │"
	@echo "  │ ## What matters (scoring dimensions)                    │"
	@echo "  │ | Dimension | Weight | Description |                   │"
	@echo "  │ [6-9 rows tailored to me, weights summing to 1.0]      │"
	@echo "  │                                                         │"
	@echo "  │ ## Minimum relevance threshold                          │"
	@echo "  │ Score: **0.4** out of 1.0                              │"
	@echo "  │                                                         │"
	@echo "  │ ## Scoring instructions                                 │"
	@echo "  │ [Guidance with a concrete example using my domains]     │"
	@echo "  │                                                         │"
	@echo "  │ ## Evolution log                                        │"
	@echo "  │ *No changes yet.*                                       │"
	@echo "  └─────────────────────────────────────────────────────────┘"
	@echo ""
	@echo " Then save the output to:"
	@echo "   $(CONFIG_DIR)/filter-identity.md"
	@echo ""
	@echo " Finally, edit your vault path and run wiki bootstrap:"
	@echo "   1. edit $(CONFIG_DIR)/config.yaml  (set vault_path)"
	@echo "   2. wiki bootstrap                   (in Claude Code)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

setup:
	@echo "Setting up personal config at $(CONFIG_DIR)..."
	@mkdir -p "$(CONFIG_DIR)"
	@if [ ! -f "$(CONFIG_DIR)/config.yaml" ]; then \
		cp "$(SKILL_DIR)/schema/config.example.yaml" "$(CONFIG_DIR)/config.yaml" && \
		echo "  created: $(CONFIG_DIR)/config.yaml"; \
	else \
		echo "  exists:  $(CONFIG_DIR)/config.yaml"; \
	fi
	@if [ ! -f "$(CONFIG_DIR)/filter-identity.md" ]; then \
		cp "$(SKILL_DIR)/schema/filter-identity.example.md" "$(CONFIG_DIR)/filter-identity.md" && \
		echo "  created: $(CONFIG_DIR)/filter-identity.md"; \
	else \
		echo "  exists:  $(CONFIG_DIR)/filter-identity.md"; \
	fi
	@if [ ! -f "$(CONFIG_DIR)/query-log.md" ]; then \
		cp "$(SKILL_DIR)/schema/query-log.example.md" "$(CONFIG_DIR)/query-log.md" && \
		echo "  created: $(CONFIG_DIR)/query-log.md"; \
	else \
		echo "  exists:  $(CONFIG_DIR)/query-log.md"; \
	fi

uninstall:
	@echo "Removing skill symlinks..."
	@removed=0; \
	for target in "$(AGENTS_SKILLS)/$(SKILL_NAME)" "$(CLAUDE_SKILLS)/$(SKILL_NAME)"; do \
		if [ -L "$$target" ]; then \
			rm "$$target" && echo "  removed: $$target" && removed=1; \
		fi; \
	done; \
	[ "$$removed" = "0" ] && echo "  no symlinks found" || true
	@echo ""
	@printf "Remove personal config at $(CONFIG_DIR)? [y/N] "; \
	read ans; \
	case "$$ans" in \
		[Yy]*) rm -rf "$(CONFIG_DIR)" && echo "  removed: $(CONFIG_DIR)";; \
		*)     echo "  kept: $(CONFIG_DIR)";; \
	esac
