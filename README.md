# Computational Thinking — Module 1, serverless on Snapshot

A republish of **Module 1 (Images · Transformations · Abstractions)** of MIT's
[_Introduction to Computational Thinking_](https://computationalthinking.mit.edu) (18.S191),
by **Alan Edelman, David P. Sanders & Charles E. Leiserson**.

The original course makes its notebooks interactive with a live **PlutoSliderServer**
backend (real infrastructure). This fork strips that machinery out and publishes the
notebooks through [Snapshot](https://snapshot.show) instead: each Pluto notebook is
compiled to **WebAssembly** and runs **entirely in the visitor's browser** — no server,
no kernel, free to host.

Notebooks are adapted where needed for WASM (e.g. WasmMakie/WasmPlot in place of heavy
image/plot backends, and `@bind` widgets that compile). Cells WasmTarget can't handle
yet are published as honest static snapshots, clearly labelled `limited` — a live map
of the frontier.

## Credit & license

Source: <https://github.com/mitmath/computational-thinking> (`Fall24`).

- **Code** — MIT license · **Text** — CC BY-SA 4.0 (see [`LICENSE.md`](./LICENSE.md)).

This is an **unofficial, educational republish**. All course credit belongs to the
original authors.
