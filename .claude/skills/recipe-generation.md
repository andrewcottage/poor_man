---
name: recipe-generation
description: Use when generating, previewing, or publishing seed recipes and categories on Stovaro via MCP tools
---

# Recipe Generation Workflow

You have access to Stovaro MCP tools for managing recipes and categories. Follow these workflows.

## Check What Exists First

1. Use `get_categories` to see all current categories
2. Use `search_recipes` to check if similar recipes already exist
3. Use `get_trending_recipes` to understand what's popular

## Single Recipe Generation

1. `preview_seed_recipe` with a descriptive prompt (e.g., "Classic French onion soup with gruyere croutons")
   - Set `dietary_preference`, `skill_level`, `target_difficulty`, `servings` as needed
   - **Never set `publish_immediately: true`** unless explicitly asked
2. `get_seed_preview` with the returned `generation_id` to check status (wait for "ready")
3. Review the preview data (title, blurb, category, tags)
4. `publish_seed_recipe` with the `generation_id` when approved

## Bulk Recipe Generation

1. `queue_seed_recipe_batch` with `category_names` and `count_per_category`
2. `list_seed_recipes_by_category` to monitor progress
3. Review previews with `get_seed_preview` for individual recipes
4. Publish individually with `publish_seed_recipe`

## Category Creation

1. `preview_seed_category` with a descriptive prompt (e.g., "Mediterranean cuisine")
2. `get_seed_category_preview` to check status
3. `publish_seed_category` when ready

## Monitoring

- `list_seed_runs` — recent recipe seed runs
- `list_seed_category_runs` — recent category seed runs
- `list_seed_recipes_by_category` — recipes grouped by category

## Best Practices

- Always preview before publishing
- Check existing categories before creating duplicates
- Use `customization_notes` for editorial guidance (e.g., "focus on quick weeknight meals")
- Generation takes time — check status before trying to publish
- A "needs_attention" status means something went wrong; check `seed_publish_error`
