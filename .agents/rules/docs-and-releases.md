# Docs and releases

- The documentation site is `docs/`, published by GitHub Pages from `master` at https://psyb0t.github.io/safe-transmission/ with the Just the Docs theme (`remote_theme` pinned in `docs/_config.yml`, colors in `docs/_sass/`).
- Every page has front matter with a unique `title` and a `description` of 50 to 170 characters, and exactly one `#` heading. Keep `docs/` flat: a file name is its URL.
- Links between pages use the relative `.md` path. A link to a file outside `docs/` uses the full `https://github.com/psyb0t/safe-transmission/blob/master/<path>` URL. Wrap code blocks containing `{{` or `{%` in `<!-- {% raw %} -->` and `<!-- {% endraw %} -->`.
- After a docs change, run `make docs` and check the built site before handing off.
- The README is the front door: what the image is, the quick start, and a Documentation section with full site URLs. Reference material (variables, volumes, ports, security notes) lives in `docs/`. Each fact has one home. README links to repository files use full `https://github.com/psyb0t/safe-transmission/blob/master/...` URLs, because Docker Hub shows the README too.
- A change to a variable, volume, port, log message or startup step updates the matching docs page and `AGENTS.md` in the same change.
- Prose: no em dashes, "directory" never "folder", no AI vocabulary, sentence case headings in the docs, one paragraph per source line. Do not mention local scratch directories in committed text.
- There is no version file. A release is an annotated `vX.Y.Z` tag on a `master` commit whose pipeline run passed; the pipeline promotes that run's `:sha-<commit>` image to the tag and cuts the GitHub release from the tag notes. `CHANGELOG.md` gets one `## vX.Y.Z` section with the date per release, written at release time.
