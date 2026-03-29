dev:
  hugo server --buildDrafts --environment production --disableFastRender

build:
  hugo --environment production --minify

build-verbose:
  hugo --environment production --minify -v

clean:
  rm -rf public resources

serve: clean dev

build-check: clean
  hugo --environment production --minify --printPathWarnings

@list-output:
  echo "Generated files in public/:"; find public -type f | head -20
