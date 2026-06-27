### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "1"
#> license_url = "https://github.com/mitmath/computational-thinking/blob/Fall23/LICENSE.md"
#> section = "8"
#> title = "Seam Carving"
#> tags = ["lecture", "module1", "dynamic programming", "image", "seam carving", "interactive"]
#> license = "MIT"
#> description = "Content-aware image resizing: repeatedly delete the lowest-energy seam so the important stuff survives. The same dynamic program from the previous lesson, now carving an image live in your browser."
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

# ╔═╡ 8e000010-0000-4000-8000-000000000010
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ 8e000001-0000-4000-8000-000000000001
md"""
# Seam Carving

How do you shrink an image *without* squashing what matters? **Seam carving** is the
trick: find a connected top-to-bottom path of pixels — a **seam** — that crosses the
least "important" stuff, and delete it. Repeat, and the image narrows one pixel at a
time while edges and objects survive.

The "importance" of a pixel is its **energy** (how fast the image changes there), and the
lowest-energy seam is found with **exactly the dynamic program from the last lesson**.
Everything below runs live in your browser.
"""

# ╔═╡ 8e000011-0000-4000-8000-000000000011
PlutoUI.TableOfContents(aside = true)

# ╔═╡ 8e000006-0000-4000-8000-000000000006
begin
    # ── helpers (row-major: index (i-1)*w + j, row 1 = top) ─────────────────────
    # clamped pixel access, so gradients at the border are well-defined
    function pat(img::Vector{Float64}, nr::Int, w::Int, i::Int, j::Int)
        ii = i; jj = j
        ii < 1 && (ii = 1); ii > nr && (ii = nr)
        jj < 1 && (jj = 1); jj > w && (jj = w)
        return img[(ii - 1) * w + jj]
    end

    # render a row-major image as a WasmMakie grayscale figure (convert to the
    # column-major, row-1-on-top layout that image! wants)
    function show_gray(img::Vector{Float64}, nr::Int, w::Int; px::Int = 300)
        disp = Vector{NTuple{4,Float64}}(undef, nr * w)
        for i in 1:nr
            for j in 1:w
                v = img[(i - 1) * w + j]
                disp[j + (nr - i) * w] = (v, v, v, 1.0)
            end
        end
        fig = Figure(size = (px, max(40, round(Int, px * nr / w))))
        ax = Axis(fig[1, 1])
        hidedecorations!(ax); hidespines!(ax)
        image!(ax, (0.0, Float64(w)), (0.0, Float64(nr)), disp,
               Int64(w), Int64(nr); interpolate = false)
        fig
    end
end

# ╔═╡ 8e000007-0000-4000-8000-000000000007
# A synthetic scene: a soft left-to-right background gradient (LOW energy) with a bright
# disk (HIGH-energy edges) a little left of centre. Seam carving should eat the bland
# background and leave the disk intact.
function scene(nr::Int, nc::Int)
    img = Vector{Float64}(undef, nr * nc)
    ci = nr * 0.5
    cj = nc * 0.42
    rad = nr * 0.30
    for i in 1:nr
        for j in 1:nc
            v = 0.25 + 0.40 * (j / nc)
            di = i - ci
            dj = j - cj
            if di * di + dj * dj < rad * rad
                v = 0.95
            end
            img[(i - 1) * nc + j] = v
        end
    end
    return img
end

# ╔═╡ 8e000008-0000-4000-8000-000000000008
# Energy = magnitude of the image gradient (how fast brightness changes). Flat areas are
# cheap to cut; edges are expensive, so seams avoid them.
function energy(img::Vector{Float64}, nr::Int, w::Int)
    e = Vector{Float64}(undef, nr * w)
    for i in 1:nr
        for j in 1:w
            gx = pat(img, nr, w, i, j + 1) - pat(img, nr, w, i, j - 1)
            gy = pat(img, nr, w, i + 1, j) - pat(img, nr, w, i - 1, j)
            e[(i - 1) * w + j] = sqrt(gx * gx + gy * gy)
        end
    end
    return e
end

# ╔═╡ 8e000009-0000-4000-8000-000000000009
# Find the minimum-energy vertical seam with dynamic programming: dp[i,j] = e[i,j] +
# cheapest of the three cells above. Then trace the cheapest bottom cell upward.
# Returns the column of the seam at each row.
function min_seam(e::Vector{Float64}, nr::Int, w::Int)
    dp = copy(e)
    for i in 2:nr
        for j in 1:w
            best = dp[(i - 2) * w + j]
            if j > 1 && dp[(i - 2) * w + j - 1] < best
                best = dp[(i - 2) * w + j - 1]
            end
            if j < w && dp[(i - 2) * w + j + 1] < best
                best = dp[(i - 2) * w + j + 1]
            end
            dp[(i - 1) * w + j] = e[(i - 1) * w + j] + best
        end
    end
    seam = Vector{Int}(undef, nr)
    sj = 1
    for j in 2:w
        dp[(nr - 1) * w + j] < dp[(nr - 1) * w + sj] && (sj = j)
    end
    seam[nr] = sj
    for i in nr:-1:2
        j = seam[i]
        nj = j
        best = dp[(i - 2) * w + j]
        if j > 1 && dp[(i - 2) * w + j - 1] < best
            best = dp[(i - 2) * w + j - 1]
            nj = j - 1
        end
        if j < w && dp[(i - 2) * w + j + 1] < best
            nj = j + 1
        end
        seam[i - 1] = nj
    end
    return seam
end

# ╔═╡ 8e00000a-0000-4000-8000-00000000000a
# Remove `k` seams one after another. Each removal recomputes the energy and the best
# seam on the now-narrower image — that re-use is what makes it dynamic programming.
function carve(img0::Vector{Float64}, nr::Int, nc::Int, k::Int)
    cur = copy(img0)
    w = nc
    steps = k
    steps > (nc - 4) && (steps = nc - 4)
    for _s in 1:steps
        e = energy(cur, nr, w)
        seam = min_seam(e, nr, w)
        nw = w - 1
        nxt = Vector{Float64}(undef, nr * nw)
        for i in 1:nr
            sj = seam[i]
            col = 0
            for j in 1:w
                if j != sj
                    col += 1
                    nxt[(i - 1) * nw + col] = cur[(i - 1) * w + j]
                end
            end
        end
        cur = nxt
        w = nw
    end
    return cur, w
end

# ╔═╡ 8e000002-0000-4000-8000-000000000002
md"""
## The energy map

Here is our scene and its **energy** — bright where the image changes fast (the rim of
the disk), dark where it's smooth (the background). Low-energy regions are the safe place
to cut.
"""

# ╔═╡ 8e00000b-0000-4000-8000-00000000000b
let
    nr, nc = 48, 64
    img = scene(nr, nc)
    show_gray(img, nr, nc; px = 320)
end

# ╔═╡ 8e00000c-0000-4000-8000-00000000000c
let
    nr, nc = 48, 64
    img = scene(nr, nc)
    e = energy(img, nr, nc)
    # normalise energy to 0..1 for display
    hi = e[1]
    for t in 2:(nr * nc)
        e[t] > hi && (hi = e[t])
    end
    hi <= 0.0 && (hi = 1.0)
    for t in 1:(nr * nc)
        e[t] = e[t] / hi
    end
    show_gray(e, nr, nc; px = 320)
end

# ╔═╡ 8e000003-0000-4000-8000-000000000003
md"""
## Carve!

Drag the slider to delete that many lowest-energy seams. The image gets **narrower**,
but the bright disk barely changes — the cuts come out of the bland background, because
that's where the energy (and so the dynamic-programming cost) is lowest.

seams to remove = $(@bind nseams Slider(0:1:40; default = 16, show_value = true))
"""

# ╔═╡ 8e00000d-0000-4000-8000-00000000000d
let
    nr, nc = 48, 64
    img = scene(nr, nc)
    carved, w = carve(img, nr, nc, nseams)
    show_gray(carved, nr, w; px = 320)
end

# ╔═╡ 8e000004-0000-4000-8000-000000000004
md"""
# Summary

- **Energy** measures how much the image changes at each pixel (the gradient magnitude).
- A **seam** is a connected top-to-bottom path; the **lowest-energy seam** is found by the
  *same* minimum-cost-path dynamic program as the previous lesson.
- Deleting seams one by one resizes an image **content-aware**: bland regions vanish,
  important structure stays.

The carved image above is a live WebAssembly island — every slider move re-runs the whole
energy → DP → remove loop in your browser.
""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
WasmMakie = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"

[sources]
WasmMakie = {url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"}

[compat]
PlutoUI = "~0.7.83"
WasmMakie = "~0.1.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "528a15ccaaea2a8f2cfb8a3b8ef12bd3bc6e7ee4"

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
git-tree-sha1 = "de6c9a45585e892ac96fa7ad9fd3b1d3d61277ec"
repo-url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"
uuid = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"
version = "0.1.0"

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
# ╟─8e000001-0000-4000-8000-000000000001
# ╠═8e000010-0000-4000-8000-000000000010
# ╠═8e000011-0000-4000-8000-000000000011
# ╠═8e000006-0000-4000-8000-000000000006
# ╠═8e000007-0000-4000-8000-000000000007
# ╠═8e000008-0000-4000-8000-000000000008
# ╠═8e000009-0000-4000-8000-000000000009
# ╠═8e00000a-0000-4000-8000-00000000000a
# ╟─8e000002-0000-4000-8000-000000000002
# ╠═8e00000b-0000-4000-8000-00000000000b
# ╠═8e00000c-0000-4000-8000-00000000000c
# ╟─8e000003-0000-4000-8000-000000000003
# ╠═8e00000d-0000-4000-8000-00000000000d
# ╟─8e000004-0000-4000-8000-000000000004
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
