# SwiftViewModelClient

A Swift client for [IknowViewModels](https://github.com/iknow/iknow_view_models).

This framework is in use in production, but many aspects of the interface are undecided and may change suddenly between versions.

## Benchmarks

The benchmarks package requires jemalloc. SwiftPM does not appear to
use the regular pkg-config interface. Instead manually set the
PKG_CONFIG_PATH

    ❯ export PKG_CONFIG_PATH=$(nix-shell -p 'pkg-config' -p 'jemalloc' --run 'echo $PKG_CONFIG_PATH_FOR_TARGET')
