# Recipe Publishing API

This adds a user-scoped recipe publishing flow for local content generation.

## Authentication

Use a user's API key from their profile page.

- Header: `Authorization: Bearer <api_key>`
- Header: `X-Api-Key: <api_key>` also works

## Endpoints

- `POST /api/recipes`
- `PATCH /api/recipes/:slug`

Authenticated users can create recipes as themselves and update only their own recipes.

## Manifest format

Store each recipe as a JSON file:

```json
{
  "title": "Creamy Lemon Chickpea Pasta",
  "blurb": "A bright, budget-friendly vegan pasta with chickpeas and spinach.",
  "instructions": "<p><strong>Ingredients</strong></p><ul><li>12 oz pasta</li><li>1 can chickpeas</li></ul><p><strong>Method</strong></p><ol><li>Boil the pasta.</li><li>Finish the sauce and toss together.</li></ol>",
  "tag_names": "Vegan, Pasta, Dinner, Weeknight",
  "difficulty": 2,
  "prep_time": 25,
  "cost": 11.50,
  "category_slug": "dinner",
  "image": "images/hero.jpg",
  "images": [
    "images/step-1.jpg",
    "images/step-2.jpg"
  ]
}
```

Notes:

- `slug` is optional on create. The server will generate one from `title`.
- `category_slug` is usually easier than `category_id`.
- `image` is the main recipe image.
- `images` is an optional gallery array.
- Paths can be relative to the manifest file.

## Local helper

List categories:

```bash
bin/recipe_publisher categories
```

Create one or many recipes:

```bash
STOVARO_API_KEY=your_api_key_here \
bin/recipe_publisher create tmp/vegan-recipes/chickpea-pasta.json tmp/vegan-recipes/tofu-curry.json
```

Update an existing recipe:

```bash
STOVARO_API_KEY=your_api_key_here \
bin/recipe_publisher update creamy-lemon-chickpea-pasta tmp/vegan-recipes/chickpea-pasta.json
```

Compatibility:

- `POOR_MAN_API_KEY` and `POOR_MAN_API_URL` still work for older local scripts.
- Prefer `STOVARO_API_KEY` and `STOVARO_API_URL` going forward.

## Suggested agent workflow

1. Ask Codex or Claude to generate one recipe manifest in the JSON format above.
2. Have it save the hero image and optional gallery images beside the manifest.
3. Run `bin/recipe_publisher create path/to/manifest.json`.
4. Repeat for as many recipes as you want, or pass multiple manifest files at once.
