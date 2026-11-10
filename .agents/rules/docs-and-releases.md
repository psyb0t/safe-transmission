# Docs and releases

- The documentation site is `docs/`, published by GitHub Pages from `master` at https://psyb0t.github.io/safe-transmission/ with the Just the Docs theme (`remote_theme` pinned in `docs/_config.yml`, colors in `docs/_sass/`).
- Keep `docs/` flat: a file name is its URL.
- Wrap code blocks containing `{{` or `{%` in `<!-- {% raw %} -->` and `<!-- {% endraw %} -->`.
- After a docs change, run `make docs` and check the built site.
- README links to repository files use full `https://github.com/psyb0t/safe-transmission/blob/master/...` URLs, because Docker Hub shows the README too.
- A change to a variable, volume, port, log message or startup step updates the matching docs page and `AGENTS.md` in the same change.
- There is no version file. A release is an annotated `vX.Y.Z` tag on a `master` commit whose pipeline run passed; the pipeline promotes that run's `:sha-<commit>` image to the tag and cuts the GitHub release from the tag notes. `CHANGELOG.md` gets one `## vX.Y.Z` section with the date per release.
