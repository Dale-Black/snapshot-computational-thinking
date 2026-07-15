### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "2"
#> section = "1"
#> title = "Random Walks"
#> tags = ["lecture", "module2", "track_data", "probability", "interactive"]
#> layout = "layout.jlhtml"
#> description = "A random walk takes one step left or right at every tick of the clock. Watch a single walk wander, then run thousands at once and see the bell curve of diffusion emerge — all live in your browser as WebAssembly."
#> license = "MIT"

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

# ╔═╡ b1a00002-0000-4000-8000-000000000002
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ b1a00001-0000-4000-8000-000000000001
md"""
# Random walks

A **random walk** is the simplest model of *something that moves by chance*. At
every tick of the clock it takes a single step — **+1** (right) with probability
$p$, or **−1** (left) otherwise — and we record where it is.

Tiny rule, surprisingly rich behaviour: random walks describe a diffusing
molecule, a share price, a foraging animal, the error in a noisy measurement. In
this lesson you'll watch **one** walk wander, then run **thousands** at once and
see a smooth **bell curve** appear out of pure randomness.

Everything below the sliders runs **in your browser as WebAssembly** — no Julia
server, no install. The randomness is a small hand-written generator (a *linear
congruential generator*), so it compiles to plain integer arithmetic and every
seed reproduces exactly the same walk.
"""

# ╔═╡ b1a00003-0000-4000-8000-000000000003
PlutoUI.TableOfContents(aside = true)

# ╔═╡ b1a00004-0000-4000-8000-000000000004
md"""
## One walk, step by step

Move the sliders and the path below redraws instantly. `steps` is how long the
clock runs, `p` tilts the coin toward the right, and `seed` picks which particular
random walk you see.
"""

# ╔═╡ b1a00006-0000-4000-8000-000000000006
md"""
steps = $(@bind nsteps Slider(10:10:400, show_value=true, default=120))

p (probability of stepping right) = $(@bind prob Slider(0.0:0.05:1.0, show_value=true, default=0.5))

seed = $(@bind seed Slider(1:50, show_value=true, default=7))
"""

# ╔═╡ b1a00007-0000-4000-8000-000000000007
path = let
    # one walk, computed inline (the Float `prob` is used directly in this cell —
    # threading it through a helper miscompiles under WasmTarget today)
    s = (seed * 2654435761 + 12345) % 2147483647   # an LCG state in [1, 2^31-1)
    if s == 0
        s = 1
    end
    xs = Vector{Float64}(undef, nsteps + 1)
    pos = 0.0
    xs[1] = pos
    for i in 1:nsteps
        s = (s * 16807) % 2147483647          # advance the Park-Miller generator
        u = Float64(s) / 2147483647.0         # a fraction in (0, 1)
        pos += u < prob ? 1.0 : -1.0
        xs[i + 1] = pos
    end
    xs
end;

# ╔═╡ b1a00008-0000-4000-8000-000000000008
let
    # the step index 0, 1, …, nsteps on the x-axis (integer loop — StepRangeLen
    # iteration is not wasm-compilable yet)
    steps_axis = Vector{Float64}(undef, nsteps + 1)
    for i in 0:nsteps
        steps_axis[i + 1] = Float64(i)
    end
    fig = Figure(size = (560, 320))
    ax = Axis(fig[1, 1])
    lines!(ax, [0.0, Float64(nsteps)], [0.0, 0.0])   # the starting height (0)
    lines!(ax, steps_axis, path)                      # the walk itself
    fig
end

# ╔═╡ b1a00009-0000-4000-8000-000000000009
md"""**After $(nsteps) steps this walk ended at position $(path[nsteps + 1]).**
Slide `seed` to meet a different walk, or `p` to bias the coin — at `p = 1` it
marches straight up, at `p = 0` straight down, and at `p = 0.5` it drifts aimlessly.
"""

# ╔═╡ b1a0000a-0000-4000-8000-000000000010
md"""
## Many walks → the bell curve

One walk is unpredictable. But run **many** *fair* walks (an even coin, `p = 0.5`)
and a clear pattern appears: the final positions pile up into a **bell-shaped curve**
(a normal distribution) centred on 0. This is *diffusion* — the same mathematics
behind why a drop of ink spreads evenly through water.

A key fact: the typical distance from the centre grows like **√steps**, not like
steps — randomness spreads *slowly*. Drag `walks` up and watch the histogram fill in.
(The one-walk sliders above still bias a single walk with `p`.)
"""

# ╔═╡ b1a0000b-0000-4000-8000-000000000011
md"""
number of walks = $(@bind nwalks Slider(50:50:2000, show_value=true, default=600))
"""

# ╔═╡ b1a0000d-0000-4000-8000-000000000013
let
    # Histogram of the final positions, drawn as vertical bars. We run all the walks
    # in ONE flat loop (a single RNG stream chopped into `nwalks` chunks of `nsteps`)
    # so the Float `prob` is only ever used at single-loop depth — the bonded value
    # currently miscompiles inside a doubly-nested loop under WasmTarget.
    lo = -Float64(nsteps)
    hi = Float64(nsteps)
    nbins = 41
    counts = Vector{Float64}(undef, nbins)
    for k in 1:nbins
        counts[k] = 0.0
    end
    s = 777
    pos = 0.0
    j = 0
    grand = nwalks * nsteps
    for t in 1:grand
        s = (s * 16807) % 2147483647
        u = Float64(s) / 2147483647.0
        pos += u < 0.5 ? 1.0 : -1.0     # fair coin (the standard diffusion demo)
        j += 1
        if j == nsteps           # one walk just finished — record where it landed
            tt = (pos - lo) / (hi - lo)
            b = Int64(floor(tt * (nbins - 1))) + 1
            if b < 1
                b = 1
            end
            if b > nbins
                b = nbins
            end
            counts[b] += 1.0
            pos = 0.0
            j = 0
        end
    end
    fig = Figure(size = (560, 320))
    ax = Axis(fig[1, 1])
    for k in 1:nbins
        center = lo + (hi - lo) * (k - 1) / (nbins - 1)
        lines!(ax, [center, center], [0.0, counts[k]])  # one bar
    end
    fig
end

# ╔═╡ b1a0000e-0000-4000-8000-000000000014
rw_stats = let
    # mean and spread of the final positions, accumulated in ONE flat pass. Returns a
    # tuple so the markdown cell below can interpolate it: computing the numbers in a
    # SEPARATE bond-dependent cell is what makes the live readout track the sliders
    # (values buried inside a markdown cell's own `let` get baked to slider defaults).
    m_total = 0.0
    sq_total = 0.0
    s = 777
    pos = 0.0
    j = 0
    grand = nwalks * nsteps
    for t in 1:grand
        s = (s * 16807) % 2147483647
        u = Float64(s) / 2147483647.0
        pos += u < 0.5 ? 1.0 : -1.0     # fair coin (the standard diffusion demo)
        j += 1
        if j == nsteps
            m_total += pos
            sq_total += pos * pos
            pos = 0.0
            j = 0
        end
    end
    m = m_total / nwalks
    var = sq_total / nwalks - m * m
    if var < 0.0
        var = 0.0
    end
    sd = sqrt(var)
    expected = sqrt(Float64(nsteps))
    (floor(m * 100.0) / 100.0, floor(sd * 100.0) / 100.0, floor(expected * 100.0) / 100.0)
end;

# ╔═╡ b1a00016-0000-4000-8000-000000000016
md"""**Across $(nwalks) walks:** mean final position is about **$(rw_stats[1])**,
spread (standard deviation) is about **$(rw_stats[2])**.

For a fair walk (p = 0.5) the mean sits near 0 and the spread tracks
sqrt(steps) = **$(rw_stats[3])** -- that's diffusion in one number.
"""

# ╔═╡ b1a0000f-0000-4000-8000-000000000015
md"""
## Appendix

The original MIT lecture builds random walks with Julia's `rand` and the
`Distributions.jl` / `Plots.jl` stack. WebAssembly can't run that machinery in the
browser, so here the randomness is a hand-written **linear congruential generator**
(pure integer arithmetic) and the picture is drawn with **WasmMakie**. The
mathematics — Bernoulli steps, the √n spread, the emergent bell curve — is exactly
the same.
"""

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
# ╟─b1a00001-0000-4000-8000-000000000001
# ╠═b1a00002-0000-4000-8000-000000000002
# ╠═b1a00003-0000-4000-8000-000000000003
# ╟─b1a00004-0000-4000-8000-000000000004
# ╟─b1a00006-0000-4000-8000-000000000006
# ╠═b1a00007-0000-4000-8000-000000000007
# ╠═b1a00008-0000-4000-8000-000000000008
# ╟─b1a00009-0000-4000-8000-000000000009
# ╟─b1a0000a-0000-4000-8000-000000000010
# ╟─b1a0000b-0000-4000-8000-000000000011
# ╠═b1a0000d-0000-4000-8000-000000000013
# ╠═b1a0000e-0000-4000-8000-000000000014
# ╟─b1a00016-0000-4000-8000-000000000016
# ╟─b1a0000f-0000-4000-8000-000000000015
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
