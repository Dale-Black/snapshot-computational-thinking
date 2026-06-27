### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "2"
#> section = "5"
#> title = "Random Variables & the Bell Curve"
#> tags = ["lecture", "module2", "track_data", "probability", "interactive"]
#> layout = "layout.jlhtml"
#> description = "Add up a handful of random numbers and something magical happens: the lumpy distribution of a single die smooths into a perfect bell curve. The Central Limit Theorem, live in your browser as WebAssembly."
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

# ╔═╡ c5a00002-0000-4000-8000-000000000002
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ c5a00003-0000-4000-8000-000000000003
PlutoUI.TableOfContents(aside = true)

# ╔═╡ c5a00001-0000-4000-8000-000000000001
md"""
# Random variables and the bell curve

Roll one die: every face is equally likely — a flat distribution. Roll two and add them:
7 is now far more common than 2 or 12. Add up *more* random numbers and the histogram of
the total grows a smooth, symmetric hump.

This is the **Central Limit Theorem**, one of the deepest facts in all of probability:
**the sum (or average) of many independent random variables looks like a bell curve — a
normal distribution — almost no matter what you started with.** It's why the normal
distribution is everywhere, from measurement error to test scores to stock returns.

Below, each "sample" is the sum of `k` random numbers drawn uniformly from `[0,1]`. Slide
`k` from 1 upward and watch a flat slab morph into a bell, live in WebAssembly.
"""

# ╔═╡ c5a00004-0000-4000-8000-000000000004
md"""
numbers added per sample (k) = $(@bind k Slider(1:1:12, show_value=true, default=1))

number of samples = $(@bind nsamples Slider(500:500:8000, show_value=true, default=3000))
"""

# ╔═╡ c5a00005-0000-4000-8000-000000000005
let
    # One flat loop: draw nsamples*k uniforms as a single stream, and every k of them
    # forms one sample (their sum). Histogram those sums over [0, k]. Keeping it to a
    # single loop is what lets the bonded counts compile cleanly to wasm.
    nbins = 40
    counts = Vector{Float64}(undef, nbins)
    for b in 1:nbins
        counts[b] = 0.0
    end
    s = 20261
    acc = 0.0
    j = 0
    grand = nsamples * k
    lo = 0.0
    hi = Float64(k)
    for t in 1:grand
        s = (s * 16807) % 2147483647
        acc += Float64(s) / 2147483647.0      # one uniform[0,1]
        j += 1
        if j == k                              # one full sample is ready
            frac = (acc - lo) / (hi - lo)
            b = Int64(floor(frac * (nbins - 1))) + 1
            if b < 1
                b = 1
            end
            if b > nbins
                b = nbins
            end
            counts[b] += 1.0
            acc = 0.0
            j = 0
        end
    end
    centers = Vector{Float64}(undef, nbins)
    for b in 1:nbins
        centers[b] = lo + (hi - lo) * (Float64(b) - 0.5) / Float64(nbins)
    end
    fig = Figure(size = (600, 340))
    ax = Axis(fig[1, 1])
    for b in 1:nbins
        lines!(ax, [centers[b], centers[b]], [0.0, counts[b]])   # a histogram bar
    end
    fig
end

# ╔═╡ c5a00006-0000-4000-8000-000000000006
md"""**At k = $(k):** each sample is the sum of $(k) uniform random numbers, so its
average value is k/2 = $(floor(Float64(k) * 5.0) / 10.0). At **k = 1** the histogram is
flat (a single uniform is equally likely anywhere). By **k = 2** it is a triangle, and
from about **k = 6** it is already an excellent bell curve. That convergence — fast, and
from a flat starting shape — is the Central Limit Theorem in action.
"""

# ╔═╡ c5a00007-0000-4000-8000-000000000007
md"""
## Why it matters

The Central Limit Theorem is the reason the normal distribution earns its central place:
anything that is the accumulation of many small independent effects ends up bell-shaped.
Measurement noise, the heights of people, the average of a survey — all are sums of many
little randomnesses, so all are approximately normal.

It also underpins **why averaging helps**: the average of `n` measurements has a spread
that shrinks like 1/√n, so it clusters ever more tightly around the truth. Estimation,
error bars, and confidence intervals all flow from this one theorem.
"""

# ╔═╡ c5a00008-0000-4000-8000-000000000008
md"""
## Appendix

The MIT lecture uses `Distributions.jl` and `Plots.jl`. WebAssembly can't run those in the
browser, so the random numbers come from an inline **Park-Miller** generator and the
histogram is drawn with **WasmMakie**. The phenomenon — sums of uniforms converging to a
bell — is identical.
"""

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
# ╟─c5a00001-0000-4000-8000-000000000001
# ╠═c5a00002-0000-4000-8000-000000000002
# ╠═c5a00003-0000-4000-8000-000000000003
# ╟─c5a00004-0000-4000-8000-000000000004
# ╠═c5a00005-0000-4000-8000-000000000005
# ╟─c5a00006-0000-4000-8000-000000000006
# ╟─c5a00007-0000-4000-8000-000000000007
# ╟─c5a00008-0000-4000-8000-000000000008
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
