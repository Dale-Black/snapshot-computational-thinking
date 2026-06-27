### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "2"
#> section = "6"
#> title = "Random Walks in 2D"
#> tags = ["lecture", "module2", "track_data", "probability", "interactive"]
#> layout = "layout.jlhtml"
#> description = "Let a walker wander the plane, one random step at a time, and trace the meandering path it leaves behind. The same diffusion that smears ink through water, in two dimensions — live in your browser as WebAssembly."
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

# ╔═╡ c6a00002-0000-4000-8000-000000000002
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ c6a00003-0000-4000-8000-000000000003
PlutoUI.TableOfContents(aside = true)

# ╔═╡ c6a00001-0000-4000-8000-000000000001
md"""
# Random walks in two dimensions

A one-dimensional walker could only go left or right. Set it free on a **plane** and at
each step it picks one of four directions — up, down, left, right — at random. The path
it traces is the classic picture of **diffusion**: a wandering, self-crossing thread that
slowly spreads outward from the start.

This is exactly how a pollen grain jitters in water (Brownian motion), how a gas molecule
diffuses, and how heat spreads. Drag the sliders to send the walker on a longer journey or
a different random path, traced live in your browser as WebAssembly.
"""

# ╔═╡ c6a00004-0000-4000-8000-000000000004
md"""
steps = $(@bind nsteps Slider(100:100:5000, show_value=true, default=1500))

seed = $(@bind seed Slider(1:60, show_value=true, default=11))
"""

# ╔═╡ c6a00005-0000-4000-8000-000000000005
let
    # walk the plane: each step draws a direction 0..3 from one inline RNG stream and
    # moves one unit that way. We record the whole (x, y) trail to draw it.
    s = (seed * 2654435761 + 12345) % 2147483647
    if s == 0
        s = 1
    end
    xs = Vector{Float64}(undef, nsteps + 1)
    ys = Vector{Float64}(undef, nsteps + 1)
    x = 0.0
    y = 0.0
    xs[1] = x
    ys[1] = y
    for i in 1:nsteps
        s = (s * 16807) % 2147483647
        d = s % 4                       # a direction: 0,1,2,3
        if d == 0
            x = x + 1.0
        end
        if d == 1
            x = x - 1.0
        end
        if d == 2
            y = y + 1.0
        end
        if d == 3
            y = y - 1.0
        end
        xs[i + 1] = x
        ys[i + 1] = y
    end
    fig = Figure(size = (480, 480))
    ax = Axis(fig[1, 1])
    lines!(ax, [0.0], [0.0])     # mark the origin
    lines!(ax, xs, ys)           # the wandering trail
    fig
end

# ╔═╡ c6a00006-0000-4000-8000-000000000006
let
    # how far from home did it get? recompute the endpoint and compare to sqrt(steps)
    s = (seed * 2654435761 + 12345) % 2147483647
    if s == 0
        s = 1
    end
    x = 0.0
    y = 0.0
    for i in 1:nsteps
        s = (s * 16807) % 2147483647
        d = s % 4
        if d == 0
            x = x + 1.0
        end
        if d == 1
            x = x - 1.0
        end
        if d == 2
            y = y + 1.0
        end
        if d == 3
            y = y - 1.0
        end
    end
    dist = sqrt(x * x + y * y)
    expected = sqrt(Float64(nsteps))
    md"""**After $(nsteps) steps** the walker is **$(floor(dist * 100.0) / 100.0)** units
    from where it started, while the typical distance grows like sqrt(steps) =
    **$(floor(expected * 100.0) / 100.0)**. Diffusion is slow: to wander twice as far from
    home you need *four times* as many steps.
    """
end

# ╔═╡ c6a00007-0000-4000-8000-000000000007
md"""
## From one walker to a physical law

Watch many such walkers at once and they spread out as a widening, blurry cloud — and the
*density* of that cloud obeys the **diffusion equation**, the same partial differential
equation that governs heat flow and the smearing of a drop of dye. A simple random rule for
one particle, averaged over many, becomes a smooth deterministic law for the whole. That
bridge from random microscopic steps to predictable macroscopic behaviour is one of the
great themes of computational science.
"""

# ╔═╡ c6a00008-0000-4000-8000-000000000008
md"""
## Appendix

Built with an inline **Park-Miller** random generator and **WasmMakie** so the whole walk
runs as in-browser WebAssembly — no `rand`, no `Plots.jl`, no server. The four-direction
rule and the sqrt(steps) spread are the standard textbook 2D random walk.
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
# ╟─c6a00001-0000-4000-8000-000000000001
# ╠═c6a00002-0000-4000-8000-000000000002
# ╠═c6a00003-0000-4000-8000-000000000003
# ╟─c6a00004-0000-4000-8000-000000000004
# ╠═c6a00005-0000-4000-8000-000000000005
# ╟─c6a00006-0000-4000-8000-000000000006
# ╟─c6a00007-0000-4000-8000-000000000007
# ╟─c6a00008-0000-4000-8000-000000000008
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
