### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "3"
#> section = "6"
#> title = "Carbon Emissions & Future Warming"
#> tags = ["lecture", "module3", "track_climate", "modeling", "interactive"]
#> layout = "layout.jlhtml"
#> description = "Tie emissions to temperature: pick how fast we keep adding CO₂ and watch the planet's projected warming over the next century unfold from the Energy Balance Model — live in your browser as WebAssembly."
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

# ╔═╡ d6a00002-0000-4000-8000-000000000002
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ d6a00003-0000-4000-8000-000000000003
PlutoUI.TableOfContents(aside = true)

# ╔═╡ d6a00001-0000-4000-8000-000000000001
md"""
# Carbon emissions and future warming

We can now close the loop between *human choices* and *planetary temperature*. Burning fossil
fuel adds CO₂ to the air; that CO₂ forces the Energy Balance Model; the model warms. Chain
those together and you get a **projection**: given an emissions path, how hot does it get, and
when?

The dial below is the one that actually matters in the real world: **how fast we keep emitting
CO₂**. Set it high and watch temperature climb steeply through the century; bring it toward zero
and warming levels off. This is, in miniature, exactly the calculation behind climate
projections — running live in WebAssembly.
"""

# ╔═╡ d6a00004-0000-4000-8000-000000000004
md"""
CO₂ added per year (ppm) = $(@bind emiti Slider(0:5:60, show_value=true, default=25)) ÷10

years into the future = $(@bind nyears Slider(20:10:200, show_value=true, default=100))
"""

# ╔═╡ d6a00005-0000-4000-8000-000000000005
let
    # start from today (about 420 ppm, ~15 C) and march forward: each year add emissions to
    # CO2, recompute the greenhouse forcing, and Euler-step the temperature. All bonded
    # values are localized first; the loop body uses only locals.
    A = 214.6
    B = 1.77
    C = 51.0
    absorbed = 239.4
    emit = Float64(emiti) / 10.0
    co2 = 420.0
    T = 15.0

    Ts = Vector{Float64}(undef, nyears + 1)
    ts = Vector{Float64}(undef, nyears + 1)
    Ts[1] = T
    ts[1] = 0.0
    for y in 1:nyears
        co2 = co2 + emit
        forcing = 5.35 * log(co2 / 280.0)
        dT = (absorbed - (A + B * T) + forcing) / C
        T = T + dT
        Ts[y + 1] = T
        ts[y + 1] = Float64(y)
    end

    fig = Figure(size = (600, 350))
    ax = Axis(fig[1, 1])
    lines!(ax, [0.0, Float64(nyears)], [14.0, 14.0])    # pre-industrial baseline
    lines!(ax, [0.0, Float64(nyears)], [16.5, 16.5])    # the +2.5C "danger" line
    lines!(ax, ts, Ts)                                   # the projection
    fig
end

# ╔═╡ d6a00006-0000-4000-8000-000000000006
cw_stats = let
    # final CO2 + temperature in a SEPARATE bond-dependent cell so the markdown below
    # interpolates them live (values inside a markdown cell's own `let` bake to the
    # slider defaults).
    A = 214.6
    B = 1.77
    C = 51.0
    absorbed = 239.4
    emit = Float64(emiti) / 10.0
    co2 = 420.0
    T = 15.0
    for y in 1:nyears
        co2 = co2 + emit
        forcing = 5.35 * log(co2 / 280.0)
        dT = (absorbed - (A + B * T) + forcing) / C
        T = T + dT
    end
    (floor(co2), floor(T * 10.0) / 10.0, floor((T - 14.0) * 10.0) / 10.0)
end;

# ╔═╡ d6a00016-0000-4000-8000-000000000016
md"""**In $(nyears) years:** CO2 reaches about **$(cw_stats[1]) ppm** and the planet warms to
about **$(cw_stats[2]) C** -- that is **$(cw_stats[3]) C**
above pre-industrial. Slide emissions toward 0 and the curve bends flat; keep them high and
it sails past the 2 C and 3 C guardrails. The future temperature is, quite literally, a
choice of slope.
"""

# ╔═╡ d6a00007-0000-4000-8000-000000000007
md"""
## What the projection does and doesn't say

This model gets the *shape* of the story right — emissions drive CO₂, CO₂ drives warming, and
cutting emissions bends the curve — with arithmetic you can watch. Real projections add the
ocean's slow uptake of heat and carbon, the feedbacks from the earlier lesson, and a spread of
socio-economic scenarios, which is why they quote *ranges*.

But the core message survives every layer of sophistication: **cumulative emissions set the
warming**, and the steepness of the curve is set by how fast we keep adding carbon. That is the
number climate policy is really arguing about.
"""

# ╔═╡ d6a00008-0000-4000-8000-000000000008
md"""
## Appendix

The Energy Balance Model from this module, driven by a simple linear-emissions CO₂ path and
stepped one year at a time with an inline logarithm for the forcing, drawn with **WasmMakie** —
entirely in-browser WebAssembly. It mirrors the structure of the MIT climate-policy notebook.
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
# ╟─d6a00001-0000-4000-8000-000000000001
# ╠═d6a00002-0000-4000-8000-000000000002
# ╠═d6a00003-0000-4000-8000-000000000003
# ╟─d6a00004-0000-4000-8000-000000000004
# ╠═d6a00005-0000-4000-8000-000000000005
# ╠═d6a00006-0000-4000-8000-000000000006
# ╟─d6a00016-0000-4000-8000-000000000016
# ╟─d6a00007-0000-4000-8000-000000000007
# ╟─d6a00008-0000-4000-8000-000000000008
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
