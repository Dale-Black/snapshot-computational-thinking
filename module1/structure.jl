### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "1"
#> license_url = "https://github.com/mitmath/computational-thinking/blob/Fall23/LICENSE.md"
#> section = "9"
#> title = "Taking Advantage of Structure"
#> tags = ["lecture", "module1", "type", "matrix", "structure", "sparse", "interactive"]
#> license = "MIT"
#> description = "A diagonal matrix is mostly zeros; a multiplication table is mostly redundant. Spotting structure lets you store and compute with far less. See it live in your browser."
#> 
#>     [[frontmatter.author]]
#>     name = "MIT mathematics"
#>     url = "https://github.com/mitmath"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 9c000010-0000-4000-8000-000000000010
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ 9c000001-0000-4000-8000-000000000001
md"""
# Taking Advantage of Structure

A list of a million numbers that are all `0` except one isn't really a million numbers
of information — it's *one position*. A diagonal matrix is "mostly zeros". A
multiplication table looks big but is built from just one row and one column. The art
of scientific computing is **spotting the structure** so you can store and compute with
far less. Below, every kind of structure is shown as an image — drag the sliders and
watch it.
"""

# ╔═╡ 9c000011-0000-4000-8000-000000000011
PlutoUI.TableOfContents(aside = true)

# ╔═╡ 9c000006-0000-4000-8000-000000000006
begin
    # WasmMakie grayscale helper: a FLAT, column-major Vector{Float64} of length nr*nc,
    # row 1 drawn at the top. (No Matrix literals — they trap inside wasm kernels.)
    function gray_figure(vals::Vector{Float64}, nr::Int, nc::Int; px::Int = 320)
        pix = Vector{NTuple{4,Float64}}(undef, nr * nc)
        for k in 1:(nr * nc)
            v = vals[k]
            pix[k] = (v, v, v, 1.0)
        end
        fig = Figure(size = (px, max(40, round(Int, px * nr / nc))))
        ax = Axis(fig[1, 1])
        hidedecorations!(ax)
        hidespines!(ax)
        image!(ax, (0.0, Float64(nc)), (0.0, Float64(nr)), pix,
               Int64(nc), Int64(nr); interpolate = false)
        fig
    end
end

# ╔═╡ 9c000002-0000-4000-8000-000000000002
md"""
## A one-hot vector

The simplest structure: a vector that is `0` everywhere except a single `1`. Whatever
its length, all you need to know is *where* the 1 is. Below it's drawn as a strip of
cells (white = the hot entry).

length n = $(@bind n9 Slider(4:1:24; default = 12, show_value = true))

hot position k = $(@bind k9 Slider(1:24; default = 4, show_value = true))
"""

# ╔═╡ 9c000007-0000-4000-8000-000000000007
let
    nn = n9
    kk = k9
    kk > nn && (kk = nn)
    vals = Vector{Float64}(undef, nn)
    for t in 1:nn
        vals[t] = 0.12
    end
    vals[kk] = 0.97
    gray_figure(vals, 1, nn; px = 420)
end

# ╔═╡ 9c000003-0000-4000-8000-000000000003
md"""
## Diagonal matrices

A **diagonal** matrix is `0` off the diagonal. An $n\times n$ matrix has $n^2$ entries,
but a diagonal one is fully described by just $n$ numbers — so Julia's `Diagonal` type
*stores only the diagonal* and skips the zeros entirely. Look for structure where it exists!

size n = $(@bind nd Slider(4:1:18; default = 9, show_value = true))
"""

# ╔═╡ 9c000008-0000-4000-8000-000000000008
let
    m = nd
    vals = Vector{Float64}(undef, m * m)
    for i in 1:m
        for j in 1:m
            vals[j + (m - i) * m] = (i == j) ? 0.92 : 0.12
        end
    end
    gray_figure(vals, m, m; px = 300)
end

# ╔═╡ 9c000004-0000-4000-8000-000000000004
md"""
## Sparse matrices

A **sparse** matrix is *mostly* zeros — not necessarily on the diagonal, just few and
far between. Instead of every entry, you store only the handful of nonzero `(row, col,
value)` triples. Slide the density up and watch the (deterministic) scatter of nonzeros
fill in; at low density there's almost nothing to store.

nonzero density = $(@bind dens Slider(0.0:0.05:0.6; default = 0.18, show_value = true))
"""

# ╔═╡ 9c000009-0000-4000-8000-000000000009
let
    m = 16
    vals = Vector{Float64}(undef, m * m)
    thr = dens * 17.0
    for i in 1:m
        for j in 1:m
            on = ((i * 7 + j * 13) % 17) < thr
            vals[j + (m - i) * m] = on ? 0.9 : 0.08
        end
    end
    gray_figure(vals, m, m; px = 300)
end

# ╔═╡ 9c000005-0000-4000-8000-000000000005
md"""
## Hidden structure: a multiplication table

This one has **no zeros at all**, yet it's still highly structured. Entry $(i, j)$ is
just $i \times j$ — so the whole $n \times n$ grid is rebuilt from a single row and a
single column ($2n$ numbers, not $n^2$). That's **low rank**: a smooth, redundant pattern
hiding in what looks like a full matrix.

size n = $(@bind nm Slider(4:1:18; default = 10, show_value = true))
"""

# ╔═╡ 9c00000a-0000-4000-8000-00000000000a
let
    m = nm
    vals = Vector{Float64}(undef, m * m)
    denom = Float64(m * m)
    for i in 1:m
        for j in 1:m
            vals[j + (m - i) * m] = (i * j) / denom
        end
    end
    gray_figure(vals, m, m; px = 300)
end

# ╔═╡ 9c00000b-0000-4000-8000-00000000000b
md"""
# Summary

- **Structure** is information you *don't* have to store. A one-hot vector is a single
  position; a diagonal matrix is $n$ numbers, not $n^2$.
- **Sparse** matrices keep only their nonzeros; **low-rank** ones (like a multiplication
  table) rebuild a whole grid from a row and a column.
- In Julia these are real *types* (`Diagonal`, `SparseMatrixCSC`, …) that store the
  compact form and run the fast algorithm automatically — "look for structure where it
  exists".

Every image above is a live WebAssembly island, rebuilt as you drag the sliders.
""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
WasmMakie = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"

[sources]
WasmMakie = {rev = "v0.1.3", url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"}

[compat]
PlutoUI = "~0.7.83"
WasmMakie = "~0.1.3"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "ed96a65ac2ea39ef97240be43398759a5bb5caed"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.WasmMakie]]
deps = ["Base64"]
git-tree-sha1 = "7fe9806ba609b6aca12d7a2ecb30071efa4fc221"
repo-rev = "v0.1.3"
repo-url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"
uuid = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"
version = "0.1.3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"
"""

# ╔═╡ Cell order:
# ╟─9c000001-0000-4000-8000-000000000001
# ╠═9c000010-0000-4000-8000-000000000010
# ╠═9c000011-0000-4000-8000-000000000011
# ╠═9c000006-0000-4000-8000-000000000006
# ╟─9c000002-0000-4000-8000-000000000002
# ╠═9c000007-0000-4000-8000-000000000007
# ╟─9c000003-0000-4000-8000-000000000003
# ╠═9c000008-0000-4000-8000-000000000008
# ╟─9c000004-0000-4000-8000-000000000004
# ╠═9c000009-0000-4000-8000-000000000009
# ╟─9c000005-0000-4000-8000-000000000005
# ╠═9c00000a-0000-4000-8000-00000000000a
# ╟─9c00000b-0000-4000-8000-00000000000b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
