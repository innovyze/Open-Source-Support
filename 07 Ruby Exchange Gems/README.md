# Ruby Exchange Gems

A free library of community-contributed Ruby gems that target the **Ruby Open Data Exchange** API used by InfoWorks ICM, InfoAsset Manager, ICMLive, InfoWorks WS Pro, and other products that embed Ruby.

The full source of every gem lives **in this folder**. Clone the repo (or just the gem folder) and use it straight away.

## ⚠️ Pure Ruby only

Gems hosted here **must be 100% Ruby**. No C extensions, no native compiled code, no dependencies on gems that ship native extensions.

**Why:** the embedded Ruby interpreter inside ICM (and other products) cannot load native libraries built against a different Ruby ABI. Pure Ruby is the only guarantee a gem will run inside the product.

## Catalog

| # | Gem | Author | Products | Domain | License |
|---|---|---|---|---|---|
| _No gems yet — be the first._ | | | | | |

## How to use a gem

1. Clone or download this repo (or just the gem's folder)
2. Open the gem's own `README.md` for product-specific install instructions
3. Common patterns: drop `lib/` into your script's load path, or `gem build *.gemspec && gem install *.gem` from the gem folder

## Contributing a gem

**PRs are welcome — we'll do our best to nurse them through review and get them merged.** If something's unclear or your gem doesn't quite fit the requirements yet, open the PR anyway and we'll figure it out together.

Open a PR adding your gem folder, ideally with a row added to the catalog table above. Requirements:

- ✅ **100% Ruby** — no C extensions, no `ext/` folder, no `extconf.rb`, no `s.extensions` in gemspec, every transitive dep also pure Ruby
- ✅ Useful to authors of Ruby Open Data Exchange scripts
- ✅ Packaged as a proper Ruby gem (`.gemspec` at the gem root, code under `lib/`)
- ✅ Permissive license — **MIT**, **Apache-2.0**, or **BSD**
- ❌ No bundled proprietary binaries, licensed datasets, customer data, or secrets

Each gem folder should contain:

```
<gem-name>/
├── <gem-name>.gemspec
├── README.md     # one-liner, supported products + versions, install, minimal usage, limitations
├── LICENSE
├── lib/
│   └── <gem_name>.rb
└── test/         # or spec/  (recommended)
```

Maintainer review: pure-Ruby check, license, no secrets, gemspec validity, smoke install. You retain copyright and can publish to rubygems.org independently.

## Naming

"Exchange" refers to the Innovyze/Autodesk **Open Data Exchange** Ruby API.

## Disclaimer

Gems are contributed by the community under their own licenses. Inclusion does not imply endorsement, support, or warranty by Autodesk/Innovyze. Use at your own risk. Gems that stop working against current product versions or are abandoned may be removed.
