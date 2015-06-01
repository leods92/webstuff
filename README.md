# Deploy
Be sure to have Divshot's CLI tool (`npm install -g divshot-cli`).
In order to deploy, run command `bundle exec jekyll build && divshot push production`.

# Development run
Run the server: `jekyll serve`.
This runs server on `http://localhost:4000` and automatically regenerate HTML files when MD files are changed.

You may also simulate production server by running `divshot s`.
