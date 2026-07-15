### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "3"
#> section = "4"
#> title = "Snowball Earth & Tipping Points"
#> tags = ["lecture", "module3", "track_climate", "modeling", "interactive"]
#> layout = "layout.jlhtml"
#> description = "Ice reflects sunlight, so a colder Earth gets colder still — a feedback so strong the planet can flip into a frozen state and stay there. Push the Sun and the starting temperature and discover the climate's two stable worlds, live in your browser as WebAssembly."
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

# ╔═╡ d4a00002-0000-4000-8000-000000000002
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ d4a00003-0000-4000-8000-000000000003
PlutoUI.TableOfContents(aside = true)

# ╔═╡ d4a00001-0000-4000-8000-000000000001
md"""
# Snowball Earth and tipping points

Add one ingredient to the Energy Balance Model and the climate develops a split personality.
The ingredient is the **ice–albedo feedback**: ice and snow are bright and reflect sunlight, so

> a colder planet grows more ice → reflects more sunlight → gets colder still.

This runaway can flip the Earth into a completely frozen **Snowball** state — and the geological
record says it really happened, more than once. The remarkable part is that *the same Sun and the
same CO₂* can support **two stable climates**: a warm one near 14 °C and a frozen one far below.
Which one you end up in depends on where you start and how strong the Sun is.

Set the starting temperature and the solar strength below, and watch the planet fall into one
basin or the other — a live demonstration of a **tipping point** in WebAssembly.
"""

# ╔═╡ d4a00004-0000-4000-8000-000000000004
md"""
starting temperature (°C) = $(@bind t0i Slider(-60:5:30, show_value=true, default=14))

solar strength (% of today) = $(@bind solari Slider(85:1:115, show_value=true, default=100))

years to simulate = $(@bind nyears Slider(20:10:400, show_value=true, default=200))
"""

# ╔═╡ d4a00005-0000-4000-8000-000000000005
let
    # Energy Balance Model with a temperature-dependent albedo. Everything bonded is turned
    # into a local before the loop; the year loop computes albedo from the CURRENT
    # temperature (a local), so ice grows and shrinks as the planet warms and cools.
    A = 214.6
    B = 1.77
    C = 51.0
    S = Float64(solari) / 100.0 * 1368.0
    T = Float64(t0i)

    Ts = Vector{Float64}(undef, nyears + 1)
    ts = Vector{Float64}(undef, nyears + 1)
    Ts[1] = T
    ts[1] = 0.0
    for y in 1:nyears
        alb = 0.3
        if T < 0.0
            alb = 0.3 + 0.3 * (0.0 - T) / 10.0   # icier as it gets colder
        end
        if alb > 0.6
            alb = 0.6                             # fully ice-covered
        end
        absorbed = (1.0 - alb) * S / 4.0
        dT = (absorbed - (A + B * T)) / C
        T = T + dT
        Ts[y + 1] = T
        ts[y + 1] = Float64(y)
    end

    fig = Figure(size = (600, 360))
    ax = Axis(fig[1, 1])
    lines!(ax, [0.0, Float64(nyears)], [14.0, 14.0])     # the warm equilibrium
    lines!(ax, [0.0, Float64(nyears)], [0.0, 0.0])       # freezing line
    lines!(ax, ts, Ts)                                    # the planet's fate
    fig
end

# ╔═╡ d4a00006-0000-4000-8000-000000000006
sb_final = let
    # final temperature in a SEPARATE bond-dependent cell so the markdown below
    # interpolates it live (values inside a markdown cell's own `let` bake to the
    # slider defaults).
    A = 214.6
    B = 1.77
    C = 51.0
    S = Float64(solari) / 100.0 * 1368.0
    T = Float64(t0i)
    for y in 1:nyears
        alb = 0.3
        if T < 0.0
            alb = 0.3 + 0.3 * (0.0 - T) / 10.0
        end
        if alb > 0.6
            alb = 0.6
        end
        absorbed = (1.0 - alb) * S / 4.0
        dT = (absorbed - (A + B * T)) / C
        T = T + dT
    end
    floor(T * 10.0) / 10.0
end

# ╔═╡ d4a00016-0000-4000-8000-000000000016
md"""**Final temperature: $(sb_final) C** -- $(sb_final < -5.0 ? "a frozen Snowball Earth" : "a warm, ice-free world"). Start just a few
degrees colder, or dim the Sun a percent or two, and the planet can tip irreversibly into
the frozen basin: once ice covers everything, it reflects so much sunlight that even
today's Sun struggles to melt it back. Two stable worlds, one tipping point between them.
"""

# ╔═╡ d4a00007-0000-4000-8000-000000000007
md"""
## Tipping points and hysteresis

The deepest lesson here is **hysteresis**: the path in differs from the path out. Slowly dim the
Sun and the warm Earth cools gently — until, at a threshold, it *jumps* to the Snowball state.
Brighten the Sun back to where it started and the Earth stays frozen; you have to push it far
*past* the original brightness before it jumps back to warm. The system remembers its history.

This is the defining feature of climate **tipping points** — ice sheets, the Atlantic
circulation, the Amazon — and why they are so dangerous: crossing one is easy and reversing it
is not. A simple feedback in a one-line model already shows the whole behaviour.
"""

# ╔═╡ d4a00008-0000-4000-8000-000000000008
md"""
## Appendix

The Energy Balance Model from the earlier lessons, extended with a temperature-dependent
albedo, stepped one year at a time and drawn with **WasmMakie** — all in-browser WebAssembly.
The two stable states and the tipping behaviour are exactly those in the MIT Snowball-Earth
notebook.
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
# ╟─d4a00001-0000-4000-8000-000000000001
# ╠═d4a00002-0000-4000-8000-000000000002
# ╠═d4a00003-0000-4000-8000-000000000003
# ╟─d4a00004-0000-4000-8000-000000000004
# ╠═d4a00005-0000-4000-8000-000000000005
# ╠═d4a00006-0000-4000-8000-000000000006
# ╟─d4a00016-0000-4000-8000-000000000016
# ╟─d4a00007-0000-4000-8000-000000000007
# ╟─d4a00008-0000-4000-8000-000000000008
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
